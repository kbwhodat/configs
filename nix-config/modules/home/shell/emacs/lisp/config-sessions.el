;;; config-sessions.el --- Workspaces (persp-mode) -*- lexical-binding: t; -*-
;;; Commentary:
;; persp-mode provides workspace switching.  Automatic lightweight
;; file/workspace persistence lives in `config-session-lite'; this file
;; keeps manual full persp save/load commands only.
;;; Code:

(setq desktop-save-mode -1)

(defconst my/persp-save-dir
  (expand-file-name "persp-sessions/" user-emacs-directory))

(unless (file-directory-p my/persp-save-dir)
  (make-directory my/persp-save-dir t))

;; --- User-defined persp helpers (TOP LEVEL on purpose) ---------------
;; Defining these at the top of the file — NOT inside `(use-package
;; persp-mode :config ...)' — is deliberate.  If persp-mode's `:config'
;; block ever errors mid-way (e.g. stale .eln files calling
;; `persp-activate' with the wrong arity), Emacs aborts the rest of
;; :config — including any defun forms living inside it.  Keybindings
;; would then resolve to undefined symbols at keypress time, giving
;; `Wrong type argument: commandp, my/persp-*'.  Defining at top level
;; means these functions always exist as commands; if persp-mode itself
;; is broken at call time they fail visibly with a clearer error.
(defun my/persp-list ()
  "Echo the full list of workspaces with `*' next to the current one."
  (interactive)
  (when (fboundp 'persp-names)
    (let* ((names   (sort (copy-sequence (persp-names)) #'string<))
           (current (safe-persp-name (get-current-persp))))
      (message "workspaces: %s"
               (mapconcat (lambda (n) (if (equal n current) (concat "*" n) n))
                          names "  ")))))
(defun my/persp-switch-nth (n)
  "Switch to the Nth workspace (1-indexed) sorted by name."
  (when (fboundp 'persp-names)
    (let ((names (sort (copy-sequence (persp-names)) #'string<)))
      (when (and (>= n 1) (<= n (length names)))
        (persp-switch (nth (1- n) names))))))
(defun my/persp-new-and-switch (name)
  "Create perspective NAME (if needed) and switch to it."
  (interactive "sNew workspace name: ")
  (when (and name (not (string= "" name))
             (fboundp 'persp-switch))
    (persp-switch name)))

(defun my/persp-switch-existing ()
  "Switch to an EXISTING perspective.  Refuses to create on typo.
Excludes the current workspace AND the `none' default from the picker,
so you only see places you can actually switch TO — no need to remember
where you already are before picking.  `t' as `completing-read''s
REQUIRE-MATCH forces input to be one of the offered names; mistyped
names get rejected loudly (use `SPC TAB n' for explicit creation)."
  (interactive)
  (when (fboundp 'persp-names)
    (let* ((current (and (fboundp 'get-current-persp)
                         (fboundp 'safe-persp-name)
                         (let ((p (get-current-persp)))
                           (and p (safe-persp-name p)))))
           (names (seq-remove (lambda (n)
                                (or (string= n "none")
                                    (and current (string= n current))))
                              (persp-names))))
      (cond
       ((null names)
        (message "No other workspaces to switch to (current: %s)"
                 (or current "none")))
       (t
        (let ((choice (completing-read "Switch to workspace: " names nil t)))
          (when (and choice (not (string= "" choice)))
            (persp-switch choice))))))))

(defun my/persp-add-buffer-exclusive (orig-fn &rest args)
  "Make `persp-add-buffer' exclusive: remove BUFFER from any OTHER
named perspective before adding it to the target.  Without this,
persp-mode's default multi-membership lets one buffer live in many
workspaces at once — so `flake.nix' opened in `kato' shows up in
`projects' too after `find-file' fires `persp-add-buffer-on-find-file'.
This is the root cause of the \"buffers merge across workspaces\"
complaint and of the post-restart persp pollution we've been chasing.

Leaves the `none' default perspective alone so global buffers
(`*scratch*' etc.) keep their everywhere-visible status."
  (let* ((buffer (or (car args) (current-buffer)))
         (buffer (if (stringp buffer) (get-buffer buffer) buffer))
         (target-persp (or (cadr args)
                           (and (fboundp 'get-current-persp)
                                (get-current-persp)))))
    (when (and (bufferp buffer)
               (buffer-live-p buffer)
               target-persp
               (fboundp 'persp-persps))
      (dolist (other (persp-persps))
        ;; `none' is nil in persp-mode internals; skip it.
        (when (and other
                   (not (eq other target-persp))
                   (memq buffer (persp-buffers other)))
          (ignore-errors (persp-remove-buffer buffer other)))))
    (apply orig-fn args)))
(defun my/persp-skip-chatter-buffer-p (buf)
  "Return non-nil to exclude BUF from any perspective's buffer list.
Hides *Messages*, *Backtrace*, *Warnings*, *compile-log*, etc. plus
all leading-space internal buffers.  Kept visible: *scratch*, *vterm*,
*ghostel*, *shell*, *eshell*, *magit-*, *notdeft*, every file buffer."
  (let ((name (buffer-name buf)))
    (or (string-prefix-p " " name)
        (string-match-p
         (rx string-start "*"
             (or "Messages" "Backtrace" "Warnings" "Completions"
                 "compile-log" "Async-native-compile-log"
                 "Native-compile-Log" "async-shell-command"
                 "Help" "Apropos" "trace-output" "WoMan-Log"
                 "tramp" "Tramp" "Customize" "Bookmark Annotation"
                 "vc-change-log" "vc-diff" "Process List"
                 "*Output*" "ielm" "Pp Eval Output")
             (zero-or-more nonl) "*" string-end)
         name))))
(defun my/persp--current-workspace-buffers ()
  "Return live buffer objects in the current perspective, filtered."
  (let ((raw (if (fboundp 'persp-buffer-list)
                 (persp-buffer-list)
               (buffer-list))))
    (seq-filter (lambda (b)
                  (and (bufferp b)
                       (buffer-live-p b)
                       (not (my/persp-skip-chatter-buffer-p b))))
                raw)))
(defun my/persp-cycle-buffer (&optional reverse)
  "Cycle to the next workspace-local buffer.
With REVERSE non-nil, cycle backwards."
  (let* ((current (current-buffer))
         (bufs (my/persp--current-workspace-buffers))
         (bufs (if reverse (reverse bufs) bufs))
         (rest (cdr (memq current bufs)))
         (next (or (car rest) (car bufs))))
    (cond
     ((null bufs)        (message "No buffers in this workspace"))
     ((eq next current)  (message "Only one buffer in this workspace"))
     (t                  (switch-to-buffer next t)))))
(defun my/persp-next-buffer ()
  "Switch to the next buffer in the current workspace."
  (interactive)
  (my/persp-cycle-buffer nil))
(defun my/persp-previous-buffer ()
  "Switch to the previous buffer in the current workspace."
  (interactive)
  (my/persp-cycle-buffer t))

(defun my/switch-to-buffer-global ()
  "Switch to ANY buffer including ones outside the current workspace.
By default `switch-to-buffer' is hijacked by `persp-set-read-buffer-function t'
which restricts the picker to the current workspace's buffer list, AND the
chatter filter drops `*Messages*'/`*Backtrace*' from that list — so a vanilla
`switch-to-buffer' can't reach them at all (and worse, accepts a typed name as
a NEW buffer to create, which looks like \"opens the wrong buffer\").
Dynamically rebinding `read-buffer-function' to nil for this one call routes
through emacs's default reader and shows the true global buffer list."
  (interactive)
  (let ((read-buffer-function nil))
    (call-interactively #'switch-to-buffer)))

(defun my/persp-after-switch-evict-foreign (&rest _)
  "After activating a perspective, replace the visible buffer if it
doesn't belong to that perspective.
- Switching into a named persp whose buffer list doesn't include the
  currently-visible buffer (carried over from where we switched from):
  swap it for one of the persp's own buffers, or `*scratch*' if empty.
- Switching into the nil/`none' default perspective: always reset to
  `*scratch*' so the default workspace feels like a clean slate.
Without this hook, persp-mode just changes the persp parameter and
leaves whatever buffer was visible — so switching from `foo' to a
fresh `bar' workspace still shows foo's last file."
  (when (fboundp 'get-current-persp)
    (let* ((persp (get-current-persp))
           (current (current-buffer))
           (target
            (cond
             ;; Switched to "none" — always *scratch*.
             ((null persp)
              (get-buffer-create "*scratch*"))
             ;; Switched to a named persp, current buffer doesn't belong.
             ((not (memq current (persp-buffers persp)))
              (or (seq-find #'buffer-live-p (persp-buffers persp))
                  (get-buffer-create "*scratch*"))))))
      (when (and target (not (eq target current)))
        (switch-to-buffer target t)))))

(use-package persp-mode
  :init
  (setq persp-auto-resume-time -1
        persp-autosave-fname "autosave"
        persp-save-dir my/persp-save-dir
        persp-autosave-default nil
        ;; Filter `switch-to-buffer' (and any other read-buffer caller)
        ;; to the current workspace's buffers.  Cross-workspace switch
        ;; available via `C-x C-b' / `M-x ibuffer'.
        persp-set-read-buffer-function t)
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      ;; --- Fast direct-switch: SPC 1 .. SPC 9 -------------------------
      (my/leader
        "1" `(,(lambda () (interactive) (my/persp-switch-nth 1)) :which-key "ws 1")
        "2" `(,(lambda () (interactive) (my/persp-switch-nth 2)) :which-key "ws 2")
        "3" `(,(lambda () (interactive) (my/persp-switch-nth 3)) :which-key "ws 3")
        "4" `(,(lambda () (interactive) (my/persp-switch-nth 4)) :which-key "ws 4")
        "5" `(,(lambda () (interactive) (my/persp-switch-nth 5)) :which-key "ws 5")
        "6" `(,(lambda () (interactive) (my/persp-switch-nth 6)) :which-key "ws 6")
        "7" `(,(lambda () (interactive) (my/persp-switch-nth 7)) :which-key "ws 7")
        "8" `(,(lambda () (interactive) (my/persp-switch-nth 8)) :which-key "ws 8")
        "9" `(,(lambda () (interactive) (my/persp-switch-nth 9)) :which-key "ws 9"))
      ;; --- Management commands under SPC TAB --------------------------
      ;; `my/persp-new-and-switch' defined at top of file.  `persp-add-new'
      ;; itself only creates — does NOT switch — so we wrap `persp-switch'
      ;; (which create-if-missing AND switches) and bind that instead.
      (my/leader
        "TAB"   '(:ignore t :which-key "workspaces")
        "TAB s" '(my/persp-switch-existing :which-key "switch (existing only)")
        "TAB n" '(my/persp-new-and-switch  :which-key "new + switch")
        "TAB d" '(persp-kill               :which-key "kill")
        "TAB l" '(my/persp-list :which-key "list all")
        "TAB r" '((lambda () (interactive)
                    (persp-load-state-from-file
                     (expand-file-name persp-autosave-fname persp-save-dir)))
                  :which-key "restore session")
        "TAB w" '((lambda () (interactive)
                    (persp-save-state-to-file
                     (expand-file-name persp-autosave-fname persp-save-dir)))
                  :which-key "save session"))))
  ;; Browser-tab-style cycle:  Cmd+]  next,  Cmd+[  previous.
  ;; Works in any mode (no need to be in evil-normal-state).
  (global-set-key (kbd "s-]") #'persp-next)
  (global-set-key (kbd "s-[") #'persp-prev)
  :config
  ;; --- treemacs-persp API-bridge (MUST run before `(persp-mode 1)') ---
  ;; treemacs's persp-mode integration registers
  ;; `treemacs--remove-treemacs-window-in-new-frames' on the
  ;; `persp-activated-functions' hook with arglist `(arg1)' — but
  ;; current persp-mode (20250830+) calls handlers with THREE args:
  ;; `(type frame-or-window persp)'.  Result on every persp activation:
  ;;     persp-activate: Wrong number of arguments: (1 . 1), 3
  ;; The error aborts `(persp-mode 1)' below mid-init, so the chatter
  ;; filter and evict-foreign hook later in this :config block never get
  ;; installed, and persp-mode appears half-broken (buffers from other
  ;; workspaces leak everywhere, SPC b B picks the wrong buffer, etc.).
  ;;
  ;; Replace the broken handler with a 3-arg adapter that forwards only
  ;; the frame to treemacs's expected signature.  Wrap in
  ;; `with-eval-after-load' so this runs regardless of load order
  ;; (treemacs loaded first → handler removed/replaced now; treemacs
  ;; loaded later → fires when it loads).
  (defun my/treemacs-persp-activated-adapter (type frame-or-window _persp)
    "Bridge persp-mode's 3-arg hook signature to treemacs's 1-arg handler.
treemacs's `treemacs--remove-treemacs-window-in-new-frames' expects
just a frame; persp-mode passes `(type frame-or-window persp)' now."
    (when (and (eq type 'frame)
               (fboundp 'treemacs--remove-treemacs-window-in-new-frames))
      (treemacs--remove-treemacs-window-in-new-frames frame-or-window)))
  (with-eval-after-load 'treemacs
    (when (fboundp 'treemacs--remove-treemacs-window-in-new-frames)
      (remove-hook 'persp-activated-functions
                   #'treemacs--remove-treemacs-window-in-new-frames)
      (add-hook 'persp-activated-functions
                #'my/treemacs-persp-activated-adapter)))
  ;; Also handle the case where treemacs is ALREADY loaded right now
  ;; (with-eval-after-load only fires on subsequent load; if treemacs
  ;; loaded before us, its handler is already on the hook).
  (when (and (featurep 'treemacs)
             (fboundp 'treemacs--remove-treemacs-window-in-new-frames))
    (remove-hook 'persp-activated-functions
                 #'treemacs--remove-treemacs-window-in-new-frames)
    (add-hook 'persp-activated-functions
              #'my/treemacs-persp-activated-adapter))

  (persp-mode 1)
  (remove-hook 'after-make-frame-functions #'persp-init-new-frame)
  (remove-hook 'after-make-frame-functions
               #'persp-mode-restore-and-remove-from-make-frame-hook)
  (remove-hook 'delete-frame-functions #'persp-delete-frame)
  (remove-hook 'kill-emacs-hook #'persp-kill-emacs-h)
  (remove-hook 'kill-emacs-query-functions #'persp-kill-emacs-query-function)
  ;; Workspace/file restore is handled by `config-session-lite'.  Keep
  ;; persp-mode available for workspace switching and manual full-state
  ;; save/load, but do not auto-save, auto-load, or auto-initialize its
  ;; full frame/session state.

  ;; --- Install chatter filter + sweep existing perspectives ----------
  ;; `my/persp-skip-chatter-buffer-p' is defined at top of file.  Here we
  ;; just wire it into persp-mode's predicate list AND retroactively
  ;; remove any already-added matches from existing perspectives
  ;; (persp-mode picked them up before our config ran).
  (add-to-list 'persp-common-buffer-filter-functions
               #'my/persp-skip-chatter-buffer-p)
  ;; Guard against the "none" default perspective (persp-mode represents
  ;; it as nil in `(persp-persps)').  `(persp-buffers nil)' throws
  ;; `wrong-type-argument: perspective, nil', and that error aborts the
  ;; rest of :config — leaving the evict-foreign hook AND the
  ;; exclusive-membership advice below uninstalled.  That was the root
  ;; cause of the cross-session "buffers merge into one perspective"
  ;; symptom: with the advice missing, persp-mode's default
  ;; multi-membership re-asserted itself the moment any find-file fired.
  (dolist (p (persp-persps))
    (when p
      (dolist (b (persp-buffers p))
        (when (and (buffer-live-p b)
                   (my/persp-skip-chatter-buffer-p b))
          (persp-remove-buffer b p)))))
  ;; Evict the foreign buffer after every persp switch.  See docstring
  ;; of `my/persp-after-switch-evict-foreign' for why this is needed:
  ;; persp-mode by itself just rebinds the workspace pointer and leaves
  ;; whatever window content was already visible.
  (add-hook 'persp-activated-functions #'my/persp-after-switch-evict-foreign)

  ;; --- Enforce exclusive workspace membership ------------------------
  ;; By default persp-mode allows a buffer to live in multiple
  ;; perspectives simultaneously.  Combined with `persp-add-buffer-on-
  ;; find-file' (default t), opening a file that exists in workspace A
  ;; while you're in workspace B silently adds it to B too — buffers
  ;; appear to "merge" across workspaces, and save+restore faithfully
  ;; reproduces the multi-membership state across emacs restarts.
  ;;
  ;; This around-advice on `persp-add-buffer' first removes the buffer
  ;; from every OTHER named persp before adding it to the target — so
  ;; opening `flake.nix' in `projects' moves it out of `kato' instead
  ;; of duplicating into both.  The `none' default persp is left alone
  ;; so global utility buffers (`*scratch*' etc.) stay visible
  ;; everywhere.
  (advice-add 'persp-add-buffer :around #'my/persp-add-buffer-exclusive))

(provide 'config-sessions)
;;; config-sessions.el ends here
