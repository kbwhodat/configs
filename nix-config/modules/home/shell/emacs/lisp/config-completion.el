;;; config-completion.el --- Minibuffer completion stack -*- lexical-binding: t; -*-
;;; Commentary:
;; Vertico+orderless+marginalia eager (used at first M-x/find-file).
;; Consult deferred.  History length bumped from default 100 to 1000.
;;; Code:

(use-package savehist
  :init (setq history-length 1000)
  :config (savehist-mode 1))

(use-package vertico
  :config (vertico-mode 1))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides
        '((file (styles basic partial-completion)))))

(use-package marginalia
  :config (marginalia-mode 1))

(use-package consult
  :defer t
  :commands (consult-line consult-ripgrep consult-buffer consult-project-buffer)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "s"  '(:ignore t :which-key "search")
        "ss" '(consult-line     :which-key "in-buffer")
        "sg" '(consult-ripgrep  :which-key "ripgrep")
        "sb" '(consult-buffer   :which-key "buffers"))
      (with-eval-after-load 'project
        (my/leader
          "p"  '(:ignore t :which-key "project")
          "pp" '(project-switch-project :which-key "switch")
          "pf" '(project-find-file      :which-key "find file")
          "pb" '(consult-project-buffer :which-key "buffers")
          "ps" '(consult-ripgrep        :which-key "ripgrep")))
      (my/leader
        "f"  '(:ignore t :which-key "files")
        "ff" '(find-file   :which-key "find file")
        "fs" '(save-buffer :which-key "save")
        "fr" '(recentf     :which-key "recent")
        "fd" '(dired       :which-key "dired")))))

(provide 'config-completion)
;;; config-completion.el ends here
