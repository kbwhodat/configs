;;; config-tree.el --- File-tree sidebar (treemacs) -*- lexical-binding: t; -*-
;;; Commentary:
;; treemacs gives you a left-side file tree similar to VSCode's explorer
;; or nvim-tree.  Bound to SPC e (matches user's nvim convention where
;; <leader>e opened Oil).
;;; Code:

(use-package treemacs
  :defer t
  :commands (treemacs treemacs-select-window treemacs-find-file)
  :init
  (setq treemacs-no-png-images t            ; unicode icons, no PNG files needed
        treemacs-width 30
        treemacs-position 'left
        treemacs-follow-after-init t
        treemacs-is-never-other-window t    ; SPC h/l skips over it
        treemacs-show-cursor nil
        treemacs-recenter-after-file-follow 'always
        treemacs-recenter-after-tag-follow 'always)
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "e"  '(treemacs           :which-key "file tree")
        "T" '(treemacs-find-file  :which-key "tree: focus file")))))

;; Evil bindings inside the treemacs buffer (so j/k navigate, etc).
(use-package treemacs-evil
  :after (treemacs evil))

;; Show git status next to filenames in the tree.
(use-package treemacs-magit
  :after (treemacs magit))

(provide 'config-tree)
;;; config-tree.el ends here
