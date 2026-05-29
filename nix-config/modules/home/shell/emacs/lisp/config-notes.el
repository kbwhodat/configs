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
        notdeft-secondary-extensions '("md")
        ;; Default cap is 100 — vault now has 370+ notes, so anything
        ;; past row 100 was being silently hidden.  10000 is fine for
        ;; any realistic note collection.
        notdeft-xapian-max-results 10000)
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
  ;; --- Title resolution from YAML frontmatter ------------------------
  ;; `my/markdown-template' generates notes with frontmatter containing
  ;; the canonical name (in `id:' as a slug, optionally `aliases:' as
  ;; the human title).  notdeft's default parser takes the first
  ;; non-empty body line as the title — which for stub notes like
  ;; `kenya.md' (body: "niceplace") is wrong.
  ;;
  ;; This pair of advices pulls a title from the frontmatter in
  ;; priority order:  aliases:[0]  >  title:  >  id:.  If none of
  ;; those exist, falls back to first body line (original behavior).
  ;; The advices then make notdeft see  "<title>\n\n<body>"  so its
  ;; built-in extraction picks the right title AND the body becomes
  ;; the summary.

  (defun my/notdeft--frontmatter-title (text)
    "Pull a display title from TEXT's YAML frontmatter.
Returns nil if no frontmatter or no usable field.  Handles bare
\(`id: kenya') and quoted (`id: \"kenya\"') values."
    (when (string-match
           "\\`---[[:space:]]*\n\\(\\(?:.*\n\\)*?\\)---[[:space:]]*\n" text)
      (let ((fm (match-string 1 text)))
        (cond
         ;; aliases:\n  - VALUE
         ((string-match
           "^aliases:[[:space:]]*\n[[:space:]]*-[[:space:]]+\"?\\([^\"\n]+?\\)\"?[[:space:]]*$"
           fm)
          (string-trim (match-string 1 fm)))
         ;; title: VALUE  (or "VALUE")
         ((string-match "^title:[[:space:]]*\"?\\([^\"\n]+?\\)\"?[[:space:]]*$" fm)
          (string-trim (match-string 1 fm)))
         ;; id: VALUE  (or "VALUE")
         ((string-match "^id:[[:space:]]*\"?\\([^\"\n]+?\\)\"?[[:space:]]*$" fm)
          (string-trim (match-string 1 fm)))))))

  (defun my/notdeft--clean-contents (contents)
    "Return CONTENTS with frontmatter title prepended as the first line.
Used by the `notdeft-parse-title' filter-args advice (a few code
paths rely on this rather than `notdeft-parse-buffer')."
    (let* ((c contents)
           (title (my/notdeft--frontmatter-title c)))
      (when (string-match "\\`---[[:space:]]*\n\\(?:.*\n\\)*?---[[:space:]]*\n" c)
        (setq c (substring c (match-end 0))))
      (setq c (replace-regexp-in-string "\\`[[:space:]\n\r]+" "" c))
      (setq c (replace-regexp-in-string "\\`#+[[:space:]]+" "" c))
      (if (and title (not (string-empty-p title)))
          (concat title "\n\n" c)
        c)))
  (advice-add 'notdeft-parse-title :filter-args
              (lambda (args)
                (list (my/notdeft--clean-contents (car args)))))

  (defun my/notdeft--skip-frontmatter (orig-fn &rest args)
    "Around-advice: feed `notdeft-parse-buffer' a synthetic buffer
where the YAML frontmatter is replaced by `<title>\\n\\n<body>'.

Title-resolution priority:
  1. aliases:/title:/id: from YAML frontmatter (via `my/notdeft--frontmatter-title')
  2. First non-empty body line (notdeft's normal fallback inside `orig-fn')
  3. File basename minus extension (used here ONLY when 1 and 2 produce
     nothing usable — i.e. note has no frontmatter title AND empty body)

So a file like `my-random-thoughts.md' with no frontmatter and no body
still shows up as `my-random-thoughts' in the listing rather than blank."
    (let* ((src-content (buffer-substring-no-properties (point-min) (point-max)))
           (title (my/notdeft--frontmatter-title src-content))
           (body-start
            (save-excursion
              (goto-char (point-min))
              (when (looking-at "\\`---[[:space:]]*\n")
                (forward-line 1)
                (when (re-search-forward "^---[[:space:]]*\n" nil t)
                  (goto-char (match-end 0))))
              (skip-chars-forward " \t\n\r")
              (when (looking-at "#+[[:space:]]+")
                (goto-char (match-end 0)))
              (point)))
           (body (buffer-substring-no-properties body-start (point-max))))
      ;; Layer-3 fallback: empty/whitespace body AND no frontmatter title
      ;; → use the file basename so the listing isn't blank.
      (when (and (or (null title) (string-empty-p title))
                 (string-empty-p (string-trim body))
                 buffer-file-name)
        (setq title (file-name-base buffer-file-name)))
      (with-temp-buffer
        (when (and title (not (string-empty-p title)))
          (insert title "\n\n"))
        (insert body)
        (goto-char (point-min))
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
