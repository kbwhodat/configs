;;; config-tree.el --- File-tree sidebar (treemacs) -*- lexical-binding: t; -*-
;;; Commentary:
;; treemacs gives you a left-side file tree similar to VSCode's explorer
;; or nvim-tree.  Bound to SPC e (matches user's nvim convention where
;; <leader>e opened Oil).
;;; Code:

;; --- File-open routing: always go to the window we launched from -----
;; Defined at TOP LEVEL (not inside `use-package :config') so the leader
;; binding installed in `:init' resolves to a real command at startup.
;; If these lived in `:config' they'd only exist after the first
;; treemacs autoload, and `SPC e' would error with
;; "Wrong type argument: commandp, my/treemacs".
(defvar my/treemacs-source-window nil
  "Window from which treemacs was launched; target for RET visits.")

(defun my/treemacs--remember-source ()
  (let ((win (selected-window)))
    (unless (and (fboundp 'treemacs-is-treemacs-window?)
                 (treemacs-is-treemacs-window? win))
      (setq my/treemacs-source-window win))))

(defun my/treemacs ()
  "Open the treemacs sidebar, remembering the current window.
First invocation triggers the autoload of `treemacs' via the
`:commands' list."
  (interactive)
  (my/treemacs--remember-source)
  (treemacs))

(defun my/treemacs-find-file ()
  "Focus current file in treemacs, remembering the current window."
  (interactive)
  (my/treemacs--remember-source)
  (treemacs-find-file))

(defun my/treemacs-visit-in-source-window (&optional _arg)
  "RET action: open node at point in the window treemacs was launched from.
Falls back to `next-window' when the source window is gone or is itself
the treemacs window.  Accepts the prefix arg passed by `treemacs-RET-action'
but ignores it — the routing logic doesn't need a prefix."
  (interactive)
  (let* ((btn  (treemacs-current-button))
         (path (and btn (treemacs-safe-button-get btn :path)))
         (target (or (and (window-live-p my/treemacs-source-window)
                          (not (eq my/treemacs-source-window (selected-window)))
                          my/treemacs-source-window)
                     (next-window (selected-window) nil nil))))
    (cond
     ((and path (file-regular-p path))
      (select-window target)
      (find-file path))
     ((and path (file-directory-p path))
      (treemacs-toggle-node)))))

(use-package treemacs
  :defer t
  :commands (treemacs treemacs-select-window treemacs-find-file)
  :init
  (setq treemacs-no-png-images t            ; unicode icons, no PNG files needed
        treemacs-width 30
        treemacs-position 'left
        treemacs-follow-after-init t
        treemacs-show-cursor t              ; visible cursor when navigating
        treemacs-recenter-after-file-follow 'always
        treemacs-recenter-after-tag-follow 'always
        ;; Absolute path — treemacs-git-status.py runs `Popen(shell=True,
        ;; env={"LC_ALL":..., "GIT_OPTIONAL_LOCKS":...})' which wipes PATH,
        ;; so a bare "git" can't be located.  `executable-find' picks the
        ;; concrete path from the daemon's exec-path at init time.
        treemacs-git-executable (or (executable-find "git") "git"))
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "e"  '(my/treemacs           :which-key "file tree")
        "T" '(my/treemacs-find-file  :which-key "tree: focus file"))))
  :config
  (setq treemacs-RET-actions-config
        '((root-node-open   . treemacs-toggle-node)
          (root-node-closed . treemacs-toggle-node)
          (dir-node-open    . treemacs-toggle-node)
          (dir-node-closed  . treemacs-toggle-node)
          (file-node-open   . my/treemacs-visit-in-source-window)
          (file-node-closed . my/treemacs-visit-in-source-window)
          (tag-node-open    . treemacs-toggle-node)
          (tag-node-closed  . treemacs-toggle-node)
          (tag-node         . my/treemacs-visit-in-source-window))))

;; Evil bindings inside the treemacs buffer.  Each pair below is forced
;; into normal/motion/treemacs state so the buffer-local treemacs binding
;; wins over evil's default for that key (e.g. evil's `w' = next-word,
;; `-' = first-non-blank-above, `D' = delete-to-eol, `%' = match-paren).
;; Mappings chosen to match netrw muscle memory.
(use-package treemacs-evil
  :after (treemacs evil)
  :config
  (dolist (binding '(("w"  . treemacs-set-width)            ; prompt for width
                     ("-"  . treemacs-goto-parent-node)     ; netrw: up a dir
                     ("D"  . treemacs-delete-file)          ; netrw: delete
                     ("%"  . treemacs-create-file)          ; netrw: new file
                     ("gh" . treemacs-toggle-show-dotfiles))) ; netrw: toggle dotfiles
    (dolist (state '(normal motion treemacs))
      (evil-define-key state treemacs-mode-map
        (kbd (car binding)) (cdr binding)))))

;; Show git status next to filenames in the tree.
(use-package treemacs-magit
  :after (treemacs magit))

(provide 'config-tree)
;;; config-tree.el ends here
