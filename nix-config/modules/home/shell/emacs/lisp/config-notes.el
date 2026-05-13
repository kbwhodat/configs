;;; config-notes.el --- Markdown + notdeft + persistent-scratch -*- lexical-binding: t; -*-
;;; Commentary:
;; Markdown face tweaks copied verbatim from prior init.el:196-226.
;;; Code:

(use-package markdown-mode
  :mode "\\.md\\'"
  :config
  ;; --- behavior / tweaks ---
  (setq markdown-fontify-code-blocks-natively nil
        markdown-hide-markup nil
        markdown-list-item-bullets (make-list 6 "-")
        markdown-header-scaling nil)

  ;; --- faces (vanilla replacement for Doom's custom-set-faces!) ---
  (custom-theme-set-faces
   'user
   '(markdown-bold-face             ((t (:inherit default :weight bold :foreground unspecified))))
   '(markdown-italic-face           ((t (:inherit default :slant italic :foreground unspecified))))
   '(markdown-header-face           ((t (:inherit default :weight bold :height 1.35))))
   '(markdown-header-face-1         ((t (:inherit default :weight bold :height 1.25))))
   '(markdown-header-face-2         ((t (:inherit default :weight bold :height 1.15))))
   '(markdown-header-face-3         ((t (:inherit default :weight bold :height 1.10))))
   '(markdown-header-face-4         ((t (:inherit default :weight bold :height 1.05))))
   '(markdown-code-face             ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-inline-code-face      ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-language-keyword-face ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-metadata-key-face     ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-line-break-face       ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-blockquote-face       ((t (:inherit default))))
   '(markdown-header-delimiter-face ((t (:inherit default :weight bold :foreground unspecified :background unspecified))))
   '(markdown-markup-face           ((t (:inherit default))))
   '(hl-line                        ((t (:inherit default :foreground unspecified :background unspecified))))))

;; --- Markdown buffer cleanup ---
(add-hook 'markdown-mode-hook (lambda () (flyspell-mode -1)))
(with-eval-after-load 'eldoc
  (add-hook 'markdown-mode-hook (lambda () (eldoc-mode -1))))

;; --- gx / gX follow markdown link under cursor (evil normal) ---
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global (kbd "g x") #'markdown-follow-link-at-point)
  (evil-define-key 'normal 'global (kbd "g X") #'markdown-follow-link-at-point))

;; --- SPC m toggles markdown markup ---
(with-eval-after-load 'general
  (when (fboundp 'my/leader)
    (my/leader "m" '(markdown-toggle-markup-hiding :which-key "toggle markup"))))

;; --- Custom markdown note functions (preserved from prior init.el) ---
(defun my/markdown-template (title slug)
  "Return default Markdown template using TITLE and SLUG."
  (let ((uid (format "%d-%s"
                     (random (expt 10 10))
                     (substring (md5 (number-to-string (float-time))) 0 4))))
    (format
     "---\nid: %s\naliases:\n  - %s\ntags: []\ndate: %s\nuid: %s\n---\n\n# %s\n\n"
     slug title (format-time-string "%Y-%m-%d") uid title)))

(defun my/new-markdown-note (title)
  "Create a new Markdown note with TITLE in ~/vault."
  (interactive "sNote title: ")
  (let* ((dir  (expand-file-name "~/vault/"))
         (slug (replace-regexp-in-string "[^[:alnum:]-]+" "-" (downcase title)))
         (file (expand-file-name (concat slug ".md") dir))
         (new? (not (file-exists-p file))))
    (unless (file-directory-p dir)
      (make-directory dir t))
    (find-file file)
    (when new?
      (insert (my/markdown-template title slug))
      (save-buffer))))

;; --- Notdeft (Xapian-backed note search; replaces deft) ---
(use-package notdeft
  :defer t
  :commands (notdeft notdeft-filter notdeft-delete-file notdeft-refresh)
  :init
  (setq notdeft-directories '("~/vault")
        notdeft-extension "md"
        notdeft-secondary-extensions '("md"))
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "n"  '(:ignore t :which-key "notes")
        "ns" '(notdeft             :which-key "search")
        "nn" '(my/new-markdown-note :which-key "new note")
        "nf" '(notdeft-filter      :which-key "filter")
        "nd" '(notdeft-delete-file :which-key "delete")
        "nr" '(notdeft-refresh     :which-key "refresh")))))

;; --- Persistent scratch ---
(use-package persistent-scratch
  :hook (after-init . persistent-scratch-autosave-mode)
  :config
  (setq persistent-scratch-save-file
        (expand-file-name "scratch-pad.el" user-emacs-directory))
  (persistent-scratch-setup-default)
  (add-hook 'kill-buffer-query-functions
            (lambda ()
              (if (string= (buffer-name) "*scratch*")
                  (progn
                    (persistent-scratch-save)
                    (bury-buffer)
                    (ignore-errors (delete-window))
                    nil)
                t))))

(defun my/open-persistent-scratch ()
  "Pop to the persistent scratch buffer."
  (interactive) (pop-to-buffer "*scratch*"))

(with-eval-after-load 'general
  (when (fboundp 'my/leader)
    (my/leader "x" '(my/open-persistent-scratch :which-key "scratch"))))

;; --- auto-save-visited explicitly OFF (user choice from prior config) ---
(auto-save-visited-mode -1)

(provide 'config-notes)
;;; config-notes.el ends here
