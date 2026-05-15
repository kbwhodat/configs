;;; config-session-lite.el --- Fast file/workspace session snapshots -*- lexical-binding: t; -*-
;;; Commentary:
;; This is intentionally narrower than `desktop-save-mode'.  It persists
;; file-backed buffers, plus lightweight persp-mode workspace membership
;; when meaningful workspaces exist.  It avoids restoring processes,
;; special buffers, TRAMP, window layouts, and other slow/brittle state.
;;; Code:

(require 'cl-lib)
(require 'seq)

(defvar my/session-lite-file
  (expand-file-name "session-lite.el" user-emacs-directory)
  "File where the lightweight session snapshot is stored.")

(defvar my/session-lite-max-buffers 80
  "Maximum number of file buffers saved in the global MRU list.")

(defvar my/session-lite-max-file-size (* 5 1024 1024)
  "Maximum file size, in bytes, eligible for lightweight restore.")

(defvar my/session-lite-save-idle-delay 1
  "Idle delay, in seconds, before saving the lightweight session.")

(defvar my/session-lite-restore-idle-delay 0.2
  "Idle delay, in seconds, between lazy restored buffers.")

(defvar my/session-lite--save-timer nil
  "Pending idle timer used to debounce session snapshot writes.")

(defvar my/session-lite--restored nil
  "Non-nil after the first GUI-frame restore attempt.")

(defun my/session-lite--file-eligible-p (file)
  "Return non-nil when FILE is cheap and useful to restore."
  (and file
       (stringp file)
       (not (file-remote-p file))
       (file-exists-p file)
       (file-readable-p file)
       (let ((attrs (file-attributes file)))
         (and attrs
              (numberp (file-attribute-size attrs))
              (<= (file-attribute-size attrs) my/session-lite-max-file-size)))))

(defun my/session-lite--buffer-file (buffer)
  "Return BUFFER's truename-free file name when it should be restored."
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (when (my/session-lite--file-eligible-p buffer-file-name)
        buffer-file-name))))

(defun my/session-lite--buffers-to-files (buffers)
  "Return restoreable file names for BUFFERS, preserving order."
  (cl-loop with seen = nil
           for buffer in buffers
           for file = (my/session-lite--buffer-file buffer)
           when (and file (not (member file seen)))
           collect file into files
           and do (push file seen)
           finally return files))

(defun my/session-lite--global-files ()
  "Return the current file-backed buffer list in MRU order."
  (seq-take (my/session-lite--buffers-to-files (buffer-list))
            my/session-lite-max-buffers))

(defun my/session-lite--selected-file ()
  "Return the selected buffer's file, or the first restoreable file."
  (or (my/session-lite--buffer-file (current-buffer))
      (car (my/session-lite--global-files))))

(defun my/session-lite--workspace-names ()
  "Return meaningful persp-mode workspace names, excluding the default none state."
  (when (and (bound-and-true-p persp-mode)
             (fboundp 'persp-names))
    (seq-filter (lambda (name)
                  (and (stringp name) (not (string= name "none"))))
                (persp-names))))

(defun my/session-lite--current-workspace ()
  "Return the current meaningful persp-mode workspace name, or nil."
  (when (and (bound-and-true-p persp-mode)
             (fboundp 'get-current-persp)
             (fboundp 'safe-persp-name))
    (let ((name (safe-persp-name (get-current-persp))))
      (when (and (stringp name) (not (string= name "none")))
        name))))

(defun my/session-lite--workspace-files (name)
  "Return restoreable file buffers belonging to persp workspace NAME."
  (when (and (boundp '*persp-hash*)
             (hash-table-p *persp-hash*)
             (fboundp 'persp-buffers))
    (let ((persp (gethash name *persp-hash*)))
      (when persp
        (my/session-lite--buffers-to-files (persp-buffers persp))))))

(defun my/session-lite--workspace-snapshot (name current-workspace selected-file)
  "Build one workspace snapshot for NAME."
  (let ((files (my/session-lite--workspace-files name)))
    (when files
      (list :name name
            :selected-file (if (equal name current-workspace)
                               (or selected-file (car files))
                             (car files))
            :files files))))

(defun my/session-lite-build-snapshot ()
  "Build the lightweight session snapshot."
  (let* ((global-files (my/session-lite--global-files))
         (selected-file (my/session-lite--selected-file))
         (current-workspace (my/session-lite--current-workspace))
         (workspaces (delq nil
                           (mapcar (lambda (name)
                                     (my/session-lite--workspace-snapshot
                                      name current-workspace selected-file))
                                   (my/session-lite--workspace-names)))))
    (list :version 1
          :saved-at (float-time)
          :current-workspace current-workspace
          :selected-file selected-file
          :global-files global-files
          :workspaces workspaces)))

(defun my/session-lite--snapshot-empty-p (snapshot)
  "Return non-nil when SNAPSHOT has no useful restore target."
  (and (null (plist-get snapshot :selected-file))
       (null (plist-get snapshot :global-files))
       (null (plist-get snapshot :workspaces))))

(defun my/session-lite-save (&optional force)
  "Persist the current lightweight session snapshot.
Automatic saves skip empty snapshots so a fresh daemon does not replace
the last useful session with only `*scratch*'.  FORCE writes even when
the snapshot is empty."
  (interactive "P")
  (let ((snapshot (my/session-lite-build-snapshot))
        (dir (file-name-directory my/session-lite-file)))
    (unless (and (not force) (my/session-lite--snapshot-empty-p snapshot))
      (unless (file-directory-p dir)
        (make-directory dir t))
      (with-temp-file my/session-lite-file
        (let ((print-length nil)
              (print-level nil))
          (prin1 snapshot (current-buffer)))))))

(defun my/session-lite-schedule-save ()
  "Debounce a lightweight session save onto idle time."
  (when (timerp my/session-lite--save-timer)
    (cancel-timer my/session-lite--save-timer))
  (setq my/session-lite--save-timer
        (run-with-idle-timer my/session-lite-save-idle-delay nil
                             #'my/session-lite-save)))

(defun my/session-lite-read ()
  "Read the lightweight session snapshot from disk."
  (when (file-readable-p my/session-lite-file)
    (with-temp-buffer
      (insert-file-contents my/session-lite-file)
      (read (current-buffer)))))

(defun my/session-lite--find-file (file &optional select)
  "Open FILE cheaply.  SELECT means show it in the selected window."
  (when (my/session-lite--file-eligible-p file)
    (let ((buffer (find-file-noselect file)))
      (when select
        (switch-to-buffer buffer))
      buffer)))

(defun my/session-lite--ensure-workspace (name)
  "Create or switch to persp-mode workspace NAME when available."
  (when (and name
             (bound-and-true-p persp-mode)
             (fboundp 'persp-switch))
    (persp-switch name)
    t))

(defun my/session-lite--restore-files-lazily (files)
  "Restore FILES one per idle tick."
  (let ((delay my/session-lite-restore-idle-delay))
    (dolist (file files)
      (run-with-idle-timer
       delay nil
       (lambda (target) (my/session-lite--find-file target nil))
       file)
      (setq delay (+ delay my/session-lite-restore-idle-delay)))))

(defun my/session-lite-restore ()
  "Restore the lightweight session snapshot for the current GUI frame."
  (interactive)
  (let* ((snapshot (my/session-lite-read))
         (workspaces (plist-get snapshot :workspaces))
         (current-workspace (plist-get snapshot :current-workspace))
         (selected-file (plist-get snapshot :selected-file))
         (global-files (plist-get snapshot :global-files)))
    (when (and (listp snapshot)
               (equal (plist-get snapshot :version) 1))
      (if workspaces
          (progn
            (dolist (workspace workspaces)
              (my/session-lite--ensure-workspace (plist-get workspace :name)))
            (my/session-lite--ensure-workspace current-workspace)
            (my/session-lite--find-file selected-file t)
            (my/session-lite--restore-files-lazily
             (seq-remove (lambda (file) (equal file selected-file))
                         (cl-mapcan (lambda (workspace)
                                      (copy-sequence (plist-get workspace :files)))
                                    workspaces))))
        (my/session-lite--find-file selected-file t)
        (my/session-lite--restore-files-lazily
         (seq-remove (lambda (file) (equal file selected-file)) global-files))))))

(defun my/session-lite-restore-on-gui-frame (&optional frame)
  "Restore session once when a graphical FRAME becomes available.
FRAME is passed by `after-make-frame-functions'; the other two hook
sites (`window-setup-hook', `server-after-make-frame-hook') pass
nothing, so we fall back to `selected-frame'.  Checking the explicit
FRAME (not `(display-graphic-p)' on whatever happens to be selected
during a server-side eval) is the critical fix: the
`(make-frame ...)' inside `my/raise-or-make-frame' runs while the
selected frame is still the daemon's TTY F1, which `display-graphic-p'
would report as non-graphical.  The guard is only set AFTER a
successful restore, and cleared on error so the next frame retries."
  (let ((target (or frame (selected-frame))))
    (when (and (not my/session-lite--restored)
               (frame-live-p target)
               (display-graphic-p target))
      (setq my/session-lite--restored t)
      (condition-case err
          (my/session-lite-restore)
        (error
         (setq my/session-lite--restored nil)
         (message "session-lite restore failed: %S" err))))))

(defun my/session-lite-save-on-frame-close (_frame)
  "Save the session when a frame closes, covering Cmd+Q-style exits."
  (my/session-lite-save))

(defun my/session-lite-save-before-kill ()
  "Save the session before Emacs confirms shutdown.
Return t so `kill-emacs-query-functions' continues normally."
  (my/session-lite-save)
  t)

(defun my/session-lite-mode-enable ()
  "Enable lightweight session persistence."
  (remove-hook 'buffer-list-update-hook #'my/session-lite-schedule-save)
  (remove-hook 'kill-emacs-hook #'my/session-lite-save)
  (remove-hook 'kill-emacs-query-functions #'my/session-lite-save-before-kill)
  (remove-hook 'delete-frame-functions #'my/session-lite-save-on-frame-close)
  (remove-hook 'window-setup-hook #'my/session-lite-restore-on-gui-frame)
  (remove-hook 'server-after-make-frame-hook #'my/session-lite-restore-on-gui-frame)
  (remove-hook 'after-make-frame-functions #'my/session-lite-restore-on-gui-frame)
  (add-hook 'buffer-list-update-hook #'my/session-lite-schedule-save)
  (add-hook 'kill-emacs-hook #'my/session-lite-save)
  (add-hook 'kill-emacs-query-functions #'my/session-lite-save-before-kill -90)
  ;; Run before `server-handle-delete-frame' tears down emacsclient frames.
  (add-hook 'delete-frame-functions #'my/session-lite-save-on-frame-close -90)
  ;; Single hook is enough: `after-make-frame-functions' fires for every
  ;; `make-frame' call regardless of caller — daemon init, emacsclient,
  ;; or elisp `(make-frame ...)' inside an --eval.  If a future emacs/
  ;; server release changes this, re-add `window-setup-hook' and
  ;; `server-after-make-frame-hook' as belt-and-suspenders.
  (add-hook 'after-make-frame-functions #'my/session-lite-restore-on-gui-frame)
  (run-with-idle-timer my/session-lite-save-idle-delay t #'my/session-lite-save))

(my/session-lite-mode-enable)

(provide 'config-session-lite)
;;; config-session-lite.el ends here
