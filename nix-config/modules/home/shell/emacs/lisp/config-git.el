;;; config-git.el --- Magit (deferred until first SPC g) -*- lexical-binding: t; -*-
;;; Code:

(use-package magit
  :defer t
  :commands (magit-status magit-dispatch magit-file-dispatch
             magit-blame magit-log-buffer-file)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "g"  '(:ignore t :which-key "git")
        "gs" '(magit-status           :which-key "status")
        "gd" '(magit-dispatch         :which-key "dispatch")
        "gf" '(magit-file-dispatch    :which-key "file dispatch")
        "gb" '(magit-blame            :which-key "blame")
        "gl" '(magit-log-buffer-file  :which-key "log")))))

(provide 'config-git)
;;; config-git.el ends here
