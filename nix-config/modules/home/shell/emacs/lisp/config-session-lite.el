;;; config-session-lite.el --- Fast file/workspace session snapshots -*- lexical-binding: t; -*-
;;; Commentary:
;; This is intentionally narrower than `desktop-save-mode'.  It persists
;; file-backed buffers, lightweight persp-mode workspace membership, and
;; file-backed split layouts when meaningful workspaces exist.  It avoids
;; restoring processes, special buffers, TRAMP, and other slow/brittle state.
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

(defun my/session-lite--proper-list-p (value)
  "Return non-nil when VALUE is a proper list."
  (let ((tail value))
    (while (consp tail)
      (setq tail (cdr tail)))
    (null tail)))

(defun my/session-lite--window-state-buffer-names (state)
  "Return buffer names referenced by writable window STATE."
  (cond
   ((and (consp state)
         (eq (car state) 'buffer)
         (stringp (cadr state)))
    (list (cadr state)))
   ((and (consp state)
         (my/session-lite--proper-list-p state))
    (cl-loop for item in state
             append (my/session-lite--window-state-buffer-names item)))))

(defun my/session-lite--window-layout-buffer-snapshot (name)
  "Return a serializable file-backed snapshot for buffer NAME."
  (let ((buffer (get-buffer name)))
    (when buffer
      (let ((file (my/session-lite--buffer-file buffer)))
        (when file
          (list :name name :file file))))))

(defun my/session-lite--window-layout-snapshot (&optional frame)
  "Return FRAME's file-backed split layout, or nil.
Side windows are intentionally excluded by snapshotting the frame's main
window only.  If any main-window leaf is not file-backed, no layout is
saved; restore then falls back to the selected file."
  (let* ((target (or frame (selected-frame)))
         (state (window-state-get (window-main-window target) t))
         (names (my/session-lite--window-state-buffer-names state))
         (buffers (delq nil
                        (mapcar #'my/session-lite--window-layout-buffer-snapshot
                                names))))
    (when (and (> (length names) 1)
               (= (length names) (length buffers)))
      (list :buffers buffers
            :state state))))

(defun my/session-lite-build-snapshot (&optional frame)
  "Build the lightweight session snapshot from FRAME."
  (let ((target (or frame (selected-frame))))
    (with-selected-frame target
      (let* ((global-files (my/session-lite--global-files))
             (selected-file (my/session-lite--selected-file))
             (current-workspace (my/session-lite--current-workspace))
             (window-layout (my/session-lite--window-layout-snapshot target))
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
              :window-layout window-layout
              :workspaces workspaces)))))

(defun my/session-lite--snapshot-empty-p (snapshot)
  "Return non-nil when SNAPSHOT has no useful restore target."
  (and (null (plist-get snapshot :selected-file))
       (null (plist-get snapshot :global-files))
       (null (plist-get snapshot :workspaces))))

(defun my/session-lite-save (&optional force frame)
  "Persist the current lightweight session snapshot.
Automatic saves skip empty snapshots so a fresh daemon does not replace
the last useful session with only `*scratch*'.  FORCE writes even when
the snapshot is empty."
  (interactive "P")
  (let ((snapshot (my/session-lite-build-snapshot frame))
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

(defun my/session-lite--find-file (file &optional select workspace)
  "Open FILE cheaply.  SELECT means show it in the selected window.
WORKSPACE, when non-nil, is the persp-mode workspace name the buffer
should be added to.  Without WORKSPACE we fall back to the current
persp (e.g. for global-files restore where no workspace context exists).

Routing to an explicit workspace is CRITICAL for correctness: the
lazy restore opens many files from many workspaces, and if every
`persp-add-buffer' just used `(get-current-persp)' (the previous
behaviour) every restored buffer would land in whatever workspace
happened to be active at restore time — corrupting workspace
membership across emacs restarts.  Third arg `nil' to `persp-add-buffer'
suppresses persp-mode's `persp-switch-to-added-buffer' default so the
active workspace doesn't flicker during background restore."
  (when (my/session-lite--file-eligible-p file)
    (let ((enable-local-variables nil))
      (let ((buffer (find-file-noselect file)))
        (when (and buffer
                   (bound-and-true-p persp-mode)
                   (fboundp 'persp-add-buffer))
          (let* ((target-persp
                  (or
                   ;; Prefer the explicit workspace argument (lookup via
                   ;; the persp-mode hash table).
                   (and workspace
                        (boundp '*persp-hash*)
                        (hash-table-p *persp-hash*)
                        (gethash workspace *persp-hash*))
                   ;; Fallback: current persp (skip if it's the "none"
                   ;; default — `persp-add-buffer' errors on nil persp).
                   (and (fboundp 'get-current-persp)
                        (get-current-persp)))))
            (when target-persp
              (ignore-errors (persp-add-buffer buffer target-persp nil)))))
        (when select
          (switch-to-buffer buffer))
        buffer))))

(defun my/session-lite--ensure-workspace (name)
  "Create or switch to persp-mode workspace NAME when available."
  (when (and name
             (bound-and-true-p persp-mode)
             (fboundp 'persp-switch))
    (persp-switch name)
    t))

(defun my/session-lite--window-layout-buffer (saved-name buffers &optional workspace)
  "Return the live buffer for SAVED-NAME described by BUFFERS.
WORKSPACE is forwarded to `my/session-lite--find-file' so the opened
buffer joins the right persp."
  (let* ((entry (seq-find (lambda (buffer)
                            (equal (plist-get buffer :name) saved-name))
                          buffers))
         (file (plist-get entry :file)))
    (when file
      (my/session-lite--find-file file nil workspace))))

(defun my/session-lite--window-layout-open-buffers (buffers &optional workspace)
  "Open every file-backed buffer required by BUFFERS.
WORKSPACE is forwarded so each opened buffer joins the right persp."
  (cl-every (lambda (buffer)
              (my/session-lite--find-file (plist-get buffer :file) nil workspace))
            buffers))

(defun my/session-lite--rewrite-window-layout-buffer-names (state buffers &optional workspace)
  "Rewrite saved buffer names in STATE to the live names for BUFFERS.
WORKSPACE is forwarded so any buffers opened during name-resolution
join the right persp."
  (cond
   ((and (consp state)
         (eq (car state) 'buffer)
         (stringp (cadr state)))
    (let ((buffer (my/session-lite--window-layout-buffer (cadr state) buffers workspace)))
      (if buffer
          (cons 'buffer (cons (buffer-name buffer) (cddr state)))
        state)))
   ((and (consp state)
         (my/session-lite--proper-list-p state))
    (mapcar (lambda (item)
              (my/session-lite--rewrite-window-layout-buffer-names item buffers workspace))
            state))
   (t state)))

(defun my/session-lite--restore-window-layout (layout &optional frame workspace)
  "Restore file-backed window LAYOUT.
Return non-nil on success.  Failures are soft so the caller can fall
back to simple selected-file restore.  WORKSPACE, when non-nil, is
the persp-mode workspace name that every layout-resident buffer
should be added to — typically the snapshot's current-workspace,
since the saved window layout was captured from a frame in that
workspace."
  (let ((target (or frame (selected-frame)))
        (state (plist-get layout :state))
        (buffers (plist-get layout :buffers)))
    (when (and state buffers)
      (condition-case err
          (when (my/session-lite--window-layout-open-buffers buffers workspace)
            (with-selected-frame target
              (delete-other-windows)
              (window-state-put
               (my/session-lite--rewrite-window-layout-buffer-names state buffers workspace)
               (frame-root-window target)
               'safe))
            t)
        (error
         (message "session-lite window layout restore failed: %S" err)
         nil)))))

(defun my/session-lite--restore-files-lazily (files)
  "Restore FILES one per idle tick.  No workspace context (e.g. when
the snapshot has no workspaces — files restore into current persp)."
  (let ((delay my/session-lite-restore-idle-delay))
    (dolist (file files)
      (run-with-idle-timer
       delay nil
       (lambda (target) (my/session-lite--find-file target nil))
       file)
      (setq delay (+ delay my/session-lite-restore-idle-delay)))))

(defun my/session-lite--restore-pairs-lazily (pairs)
  "Restore (file . workspace-name) PAIRS one per idle tick.
Each timer callback opens its file AND adds the buffer to the named
workspace via the WORKSPACE argument of `my/session-lite--find-file' —
preserving the file's original workspace membership across restarts.
Without this (the previous flat-list restore) every restored file
landed in whatever workspace was active at restore time."
  (let ((delay my/session-lite-restore-idle-delay))
    (dolist (pair pairs)
      (run-with-idle-timer
       delay nil
       (lambda (target-pair)
         (my/session-lite--find-file (car target-pair) nil (cdr target-pair)))
       pair)
      (setq delay (+ delay my/session-lite-restore-idle-delay)))))

(defun my/session-lite-restore (&optional frame)
  "Restore the lightweight session snapshot into FRAME."
  (interactive)
  (let ((target (or frame (selected-frame))))
    (with-selected-frame target
      (let* ((snapshot (my/session-lite-read))
             (workspaces (plist-get snapshot :workspaces))
             (current-workspace (plist-get snapshot :current-workspace))
             (selected-file (plist-get snapshot :selected-file))
             (global-files (plist-get snapshot :global-files))
             (window-layout (plist-get snapshot :window-layout)))
        (when (and (listp snapshot)
                   (equal (plist-get snapshot :version) 1))
          (if workspaces
              (progn
                ;; Materialize every workspace up front so the per-file
                ;; lookup via `*persp-hash*' resolves below.
                (dolist (workspace workspaces)
                  (my/session-lite--ensure-workspace (plist-get workspace :name)))
                ;; Switch to the saved active workspace — single switch,
                ;; no thrashing.
                (my/session-lite--ensure-workspace current-workspace)
                ;; Restore the visible window state.  Selected-file
                ;; AND every buffer inside the saved layout goes into
                ;; `current-workspace' (where the user left them).
                (unless (my/session-lite--restore-window-layout
                         window-layout target current-workspace)
                  (my/session-lite--find-file selected-file t current-workspace))
                ;; CRITICAL: pair each lazy-restored file with its
                ;; ORIGINAL workspace so `my/session-lite--find-file'
                ;; can `persp-add-buffer' it to the correct persp
                ;; (instead of dumping every file into whichever
                ;; workspace happens to be active at restore time).
                ;; Without this, `kato'-tagged files reappear under
                ;; `projects' and vice versa.
                (let ((pairs (cl-mapcan
                              (lambda (workspace)
                                (let ((ws-name (plist-get workspace :name)))
                                  (mapcar (lambda (file) (cons file ws-name))
                                          (plist-get workspace :files))))
                              workspaces)))
                  (my/session-lite--restore-pairs-lazily
                   (seq-remove (lambda (pair) (equal (car pair) selected-file))
                               pairs))))
            (unless (my/session-lite--restore-window-layout window-layout target)
              (my/session-lite--find-file selected-file t))
            (my/session-lite--restore-files-lazily
             (seq-remove (lambda (file) (equal file selected-file)) global-files))))))))

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
          (my/session-lite-restore target)
        (error
         (setq my/session-lite--restored nil)
         (message "session-lite restore failed: %S" err))))))

(defun my/session-lite-save-on-frame-close (frame)
  "Save the session when a frame closes, covering Cmd+Q-style exits."
  (my/session-lite-save nil frame))

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
