;;; config-sessions.el --- Workspaces (persp-mode) -*- lexical-binding: t; -*-
;;; Commentary:
;; THE KEY CHANGE: no eager (persp-load-state-from-file) at startup.
;; Restore is manual via SPC TAB r.  Save still happens on kill-emacs-hook.
;;; Code:

(setq desktop-save-mode -1)

(defconst my/persp-save-dir
  (expand-file-name "persp-sessions/" user-emacs-directory))

(unless (file-directory-p my/persp-save-dir)
  (make-directory my/persp-save-dir t))

(use-package persp-mode
  :defer t
  :commands (persp-mode persp-switch persp-add-buffer persp-frame-switch
             persp-load-state-from-file persp-save-state-to-file
             persp-kill)
  :init
  (setq persp-auto-resume-time -1
        persp-autosave-fname "autosave"
        persp-save-dir my/persp-save-dir
        persp-autosave-default t)
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "TAB"   '(:ignore t :which-key "workspaces")
        "TAB s" '(persp-switch :which-key "switch")
        "TAB n" '(persp-add-new :which-key "new")
        "TAB d" '(persp-kill   :which-key "kill")
        "TAB r" '((lambda () (interactive)
                    (persp-load-state-from-file
                     (expand-file-name persp-autosave-fname persp-save-dir)))
                  :which-key "restore session")
        "TAB w" '((lambda () (interactive)
                    (persp-save-state-to-file
                     (expand-file-name persp-autosave-fname persp-save-dir)))
                  :which-key "save session"))))
  :config
  (persp-mode 1)
  ;; Save on kill-emacs (keep prior behavior) — but DO NOT auto-restore.
  (add-hook 'kill-emacs-hook
            (lambda ()
              (ignore-errors
                (persp-save-state-to-file
                 (expand-file-name persp-autosave-fname persp-save-dir))))))

(provide 'config-sessions)
;;; config-sessions.el ends here
