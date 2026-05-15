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

;; --- embark: actions on completion candidates ----------------------
;; In any minibuffer (M-x, find-file, consult-*) press C-. for a menu
;; of actions on the candidate (kill, rename, copy-path, etc.).
;; embark-consult bridges consult results into embark — e.g. take a
;; consult-grep result list and embark-export to a wgrep buffer for
;; batch edit.
(use-package embark
  :defer t
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim)
         ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; --- wgrep: batch-edit consult-ripgrep results -----------------------
;; Flow:  SPC s g  →  results  →  C-. E  (embark-export to grep buffer)
;; →  e (or C-x C-q) to enter wgrep-mode  →  edit anywhere
;; →  C-c C-c to apply changes to every underlying file.
(use-package wgrep
  :defer t
  :init (setq wgrep-auto-save-buffer t))

(provide 'config-completion)
;;; config-completion.el ends here
