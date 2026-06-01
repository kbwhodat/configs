;;; config-completion.el --- Minibuffer completion stack -*- lexical-binding: t; -*-
;;; Commentary:
;; Vertico+orderless+marginalia eager (used at first M-x/find-file).
;; Consult deferred.  History length bumped from default 100 to 1000.
;;; Code:

(use-package savehist
  :init (setq history-length 1000)
  :config (savehist-mode 1))

(use-package vertico
  :config
  (vertico-mode 1)

  ;; --- vertico-multiform: per-category layouts ---------------------
  ;; Built-in to the vertico package — no separate install.  Lets you
  ;; pick a layout per completion category instead of one-size-fits-all
  ;; vertical.  Toggle layouts at any prompt with `M-V'.
  ;;
  ;; CRITICAL: must `require' each extension file so the corresponding
  ;; mode symbols become `fboundp'.  vertico-multiform resolves a
  ;; shorthand like `grid' -> `vertico-grid-mode' via `intern-soft' +
  ;; `fboundp' (vertico-multiform.el line 137-139); if the extension
  ;; isn't loaded, the resolver falls back to the bare symbol and
  ;; later `(funcall 'grid ...)' errors with `void-function grid'.
  ;; README examples don't mention this because they assume the user
  ;; has enabled extensions globally — for our per-category use, just
  ;; loading the files (not enabling the modes) is enough.
  (require 'vertico-grid)
  (require 'vertico-buffer)
  (require 'vertico-unobtrusive)
  (require 'vertico-flat)
  (require 'vertico-multiform)
  (vertico-multiform-mode 1)
  (setq vertico-multiform-categories
        '((file       grid)              ; find-file: 2D grid (more files per screen)
          (consult-grep buffer)          ; ripgrep results: full-buffer view
          (jinx       grid (vertico-grid-annotate . 20))  ; spellcheck suggestions
          (imenu      buffer)))
  (setq vertico-multiform-commands
        '((execute-extended-command unobtrusive)  ; M-x: stays as one line
          (consult-line             buffer))))    ; in-buffer search: buffer view

(use-package vertico-posframe
  :after vertico
  :config
  ;; Pop completion in a child frame near point instead of the
  ;; minibuffer at the bottom.  Stylistic.  Comment out
  ;; `(vertico-posframe-mode 1)' to disable while keeping the package
  ;; installed.
  (setq vertico-posframe-poshandler  #'posframe-poshandler-frame-center
        vertico-posframe-border-width 2
        vertico-posframe-parameters
        '((left-fringe  . 8)
          (right-fringe . 8)))
  (vertico-posframe-mode 1))


(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides
        '((file (styles basic partial-completion)))))

(use-package marginalia
  :config (marginalia-mode 1))

;; Shell-like minibuffer editing: C-u clears the prompt input, C-w deletes the
;; previous word/path component.  Useful when `find-file' starts in a long cwd.
(defun my/minibuffer-kill-input ()
  "Delete all editable text in the active minibuffer."
  (interactive)
  (delete-minibuffer-contents))

(dolist (map-symbol '(minibuffer-local-map
                      minibuffer-local-ns-map
                      minibuffer-local-completion-map
                      minibuffer-local-must-match-map
                      minibuffer-local-isearch-map
                      minibuffer-local-filename-completion-map
                      minibuffer-local-filename-must-match-map))
  (when (boundp map-symbol)
    (let ((map (symbol-value map-symbol)))
      (define-key map (kbd "C-u") #'my/minibuffer-kill-input)
      (define-key map (kbd "C-w") #'backward-kill-word))))

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
