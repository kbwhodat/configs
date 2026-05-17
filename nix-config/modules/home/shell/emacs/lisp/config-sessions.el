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
  (defun my/persp-list ()
    "Echo the full list of workspaces with `*' next to the current one."
    (interactive)
    (let* ((names   (sort (copy-sequence (persp-names)) #'string<))
           (current (safe-persp-name (get-current-persp))))
      (message "workspaces: %s"
               (mapconcat (lambda (n) (if (equal n current) (concat "*" n) n))
                          names "  "))))
  (defun my/persp-switch-nth (n)
    "Switch to the Nth workspace (1-indexed) sorted by name."
    (let ((names (sort (copy-sequence (persp-names)) #'string<)))
      (when (and (>= n 1) (<= n (length names)))
        (persp-switch (nth (1- n) names)))))
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
      (my/leader
        "TAB"   '(:ignore t :which-key "workspaces")
        "TAB s" '(persp-switch :which-key "switch")
        "TAB n" '(persp-add-new :which-key "new")
        "TAB d" '(persp-kill   :which-key "kill")
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
  )

(provide 'config-sessions)
;;; config-sessions.el ends here
