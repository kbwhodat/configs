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
        "nr" '(notdeft-refresh     :which-key "refresh"))))
  :config
  ;; Fix title display: every note in ~/vault starts with `---\n...---'
  ;; YAML frontmatter (from `my/markdown-template'), and notdeft's
  ;; built-in parser takes the first non-empty line as the title — so
  ;; every entry shows up as "---".  Strip the frontmatter and the
  ;; leading `# ' off the markdown heading before notdeft parses.
  (defun my/notdeft--clean-contents (contents)
    "Strip YAML frontmatter + leading markdown header marker from CONTENTS.
In-memory only; does not modify any file on disk."
    (let ((c contents))
      (when (string-match "\\`---[[:space:]]*\n\\(?:.*\n\\)*?---[[:space:]]*\n"
                          c)
        (setq c (substring c (match-end 0))))
      (setq c (replace-regexp-in-string "\\`[[:space:]\n\r]+" "" c))
      (setq c (replace-regexp-in-string "\\`#+[[:space:]]+" "" c))
      c))
  (advice-add 'notdeft-parse-title :filter-args
              (lambda (args)
                (list (my/notdeft--clean-contents (car args)))))

  ;; --- Strip YAML frontmatter + leading `#' from BOTH title & summary -
  ;; `notdeft-parse-title' advice above only fires in a few code paths.
  ;; The actual listing buffer derives both title AND summary from
  ;; `notdeft-parse-buffer', which sees the raw file — so without this
  ;; advice the summary column shows `--- --- id: ... aliases: ...'.
  ;; We narrow past the frontmatter (and the leading markdown header
  ;; marker) so parse-buffer's "first non-whitespace line" picks the
  ;; real title and the summary starts at body text.
  (defun my/notdeft--skip-frontmatter (orig-fn &rest args)
    (save-restriction
      (widen)
      (let ((body-start
             (save-excursion
               (goto-char (point-min))
               (when (looking-at "\\`---[[:space:]]*\n")
                 (forward-line 1)
                 (when (re-search-forward "^---[[:space:]]*\n" nil t)
                   (goto-char (match-end 0))))
               (skip-chars-forward " \t\n\r")
               (when (looking-at "#+[[:space:]]+")
                 (goto-char (match-end 0)))
               (point))))
        (narrow-to-region body-start (point-max))
        (apply orig-fn args))))
  (advice-add 'notdeft-parse-buffer :around #'my/notdeft--skip-frontmatter)

  ;; --- Faces: match the minimal markdown aesthetic ------------------
  ;; Default notdeft inherits font-lock-* which colours everything in
  ;; the doom-alabaster theme; clashes with the rest of the buffer.
  (custom-theme-set-faces
   'user
   '(notdeft-header-face        ((t (:inherit default :weight bold))))
   '(notdeft-filter-string-face ((t (:inherit default :slant italic))))
   '(notdeft-title-face         ((t (:inherit default :weight bold))))
   '(notdeft-separator-face     ((t (:inherit default :foreground "#666666"))))
   '(notdeft-summary-face       ((t (:inherit default :foreground "#888888"))))
   '(notdeft-time-face          ((t (:inherit default :foreground "#666666")))))

  ;; Shorter timestamp — full datetime was line-noise.
  (setq notdeft-time-format " %Y-%m-%d")

  ;; --- Remove the *NotDeft* buffer/window after picking a file ------
  ;; Notdeft leaves its search buffer behind after RET on a result.
  ;; Kill it so normal buffer cycling does not keep returning to the
  ;; search buffer after a note has been selected.
  (defun my/notdeft--dismiss (&rest _)
    (let ((buf (get-buffer notdeft-buffer)))
      (when buf
        (dolist (win (get-buffer-window-list buf nil t))
          (when (window-deletable-p win)
            (delete-window win)))
        (kill-buffer buf))))
  (advice-add 'notdeft-find-file :after #'my/notdeft--dismiss))

;; --- Jinx: fast spell-check via libenchant -------------------------
;; Replaces flyspell.  Uses libenchant (system Apple Spell on macOS,
;; hunspell/aspell elsewhere — see `pkgs.enchant' in emacs.nix).
;;
;; ON-DEMAND ONLY — no auto-hooks.  Spell-check is per-buffer work that
;; we don't want on every text/markdown/org buffer (felt slow on weaker
;; hardware).  Enable manually with `M-x jinx-mode' in a specific buffer
;; when you actually want spell-checking, or add a buffer-local hook in
;; .dir-locals.el for a specific project.
;;
;; M-$    `jinx-correct'     — fix the misspelled word at/before point
;; C-M-$  `jinx-languages'   — toggle active dictionary languages
(use-package jinx
  :defer t
  :commands (jinx-mode jinx-correct jinx-languages)
  :bind (("M-$" . jinx-correct)
         ("C-M-$" . jinx-languages)))

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

(provide 'config-notes)
;;; config-notes.el ends here
