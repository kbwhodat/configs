;;; config-term.el --- Terminal (vterm) -*- lexical-binding: t; -*-
;;; Code:

(use-package vterm
  :defer t
  :commands (vterm vterm-other-window)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "o"  '(:ignore t :which-key "open")
        "ot" '(vterm   :which-key "vterm")
        "oe" '(eshell  :which-key "eshell")))))

(provide 'config-term)
;;; config-term.el ends here
