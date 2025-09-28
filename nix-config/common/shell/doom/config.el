;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;;;; —— core “don’t lose my work” settings ——
;; Save point (cursor) in files
(save-place-mode 1)

;; disable doom-modeline
(remove-hook 'doom-first-buffer-hook #'doom-modeline-mode)

;; Save minibuffer/history across sessions
(savehist-mode 1)
(setq history-length 1000)

(after! markdown-mode
  ;; stop code-block syntax colors + header scaling, hide markup chars like ** _
  (setq markdown-fontify-code-blocks-natively nil
        markdown-hide-markup t
        markdown-header-scaling nil))

(setq confirm-kill-emacs nil)

(desktop-save-mode -1)

(setq display-line-numbers-type 'relative)

;; Enable persp-mode for workspace/session persistence
(use-package! persp-mode
  :init
  ;; Enable session persistence
  (setq persp-autosave-fname "autosave") ;; Name of the session file
  (setq persp-save-dir "~/.doom.d/persp-sessions/") ;; Where to save sessions
  (setq persp-autosave-default t) ;; Automatically save on exit
  (setq persp-set-last-persp-for-new-frames t)
  :config
  (persp-mode 1)

  ;; Restore session on startup
  (when (file-exists-p (expand-file-name persp-autosave-fname persp-save-dir))
    (persp-load-state-from-file (expand-file-name persp-autosave-fname persp-save-dir)))

  ;; Optionally, save session whenever you kill Emacs
  (add-hook 'kill-emacs-hook
            (lambda ()
              (persp-save-state-to-file (expand-file-name persp-autosave-fname persp-save-dir))))
)

;; Recent files list
(recentf-mode 1)
(setq recentf-max-saved-items 500)

;; Autosave visited buffers (writes to disk)
(auto-save-visited-mode 1)
(setq auto-save-visited-interval 5)

;; remove window decoration on macos
(add-to-list 'default-frame-alist '(undecorated . t))

;;; —— persistent scratch (unsaved notes survive restarts) ——
(use-package! persistent-scratch
  :hook (after-init . persistent-scratch-setup-default)
  :config
  (persistent-scratch-autosave-mode 1))

; (setq doom-theme 'doom-homage-black)
(setq doom-theme 'doom-alabaster)
(setq doom-font (font-spec :family "ComicShannsMono Nerd Font Mono" :size 17))

(defvar nb/current-line '(0 . 0)
  "(start . end) of current line in current buffer")
(make-variable-buffer-local 'nb/current-line)

(defun nb/unhide-current-line (limit)
  "Font-lock function"
  (let ((start (max (point) (car nb/current-line)))
        (end (min limit (cdr nb/current-line))))
    (when (< start end)
      (remove-text-properties start end
                              '(invisible t display "" composition ""))
      (goto-char limit)
      t)))

(defun nb/refontify-on-linemove ()
  "Post-command-hook"
  (let* ((start (line-beginning-position))
         (end (line-beginning-position 2))
         (needs-update (not (equal start (car nb/current-line)))))
    (setq nb/current-line (cons start end))
    (when needs-update
      (font-lock-fontify-block 3))))

(defun nb/markdown-unhighlight ()
  "Enable markdown concealing with live unhide on current line."
  (interactive)
  (markdown-toggle-markup-hiding 'toggle)
  (font-lock-add-keywords nil '((nb/unhide-current-line)) t)
  (add-hook 'post-command-hook #'nb/refontify-on-linemove nil t))

(after! markdown-mode
  (setq markdown-hide-markup t
        markdown-fontify-code-blocks-natively nil
        markdown-list-item-bullets (make-list 6 "-")
        markdown-header-scaling nil)

  (map! :map markdown-mode-map
        :i "RET" #'newline
        :n "RET"  nil)

  ; (add-hook 'markdown-mode-hook #'markdown-toggle-markup-hiding)
  (add-hook 'markdown-mode-hook #'nb/markdown-unhighlight)

  (custom-set-faces!
    '(markdown-bold-face             :weight bold :foreground nil)
    '(markdown-italic-face           :slant italic :foreground nil)
    '(markdown-header-face           :inherit default :weight bold)
    '(markdown-header-face-1         :inherit default :weight bold)
    '(markdown-header-face-2         :inherit default :weight bold)
    '(markdown-header-face-3         :inherit default :weight bold)
    '(markdown-header-face-4         :inherit default :weight bold)
    '(markdown-code-face             :inherit default :foreground nil :background nil)
    '(markdown-inline-code-face      :inherit default :foreground nil :background nil)
    '(markdown-metadata-key-face     :inherit default :foreground nil :background nil)
    '(markdown-blockquote-face       :inherit default)
    '(markdown-header-delimiter-face :inherit default :foreground nil :background nil :weight bold)
    '((markdown-language-keyword-face markdown-code-face) :inherit default :foreground nil :background nil)
    '(markdown-markup-face      :inherit default)))

;; If you use a custom roam dir, set it BEFORE org-roam loads
(setq org-directory "~/vault/"
      org-roam-directory (file-truename org-directory)
      org-roam-file-extensions '("org" "md")
      org-roam-completion-everywhere nil)


(defun my/new-markdown-note (title)
  "Create a new Markdown note with TITLE."
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

(defun my/markdown-template (title slug)
  "Return default Markdown template using TITLE and SLUG."
  (let ((uid (format "%d-%s"
                     (random (expt 10 10))
                     (substring (md5 (number-to-string (float-time))) 0 4))))
    (format
     "---\nid: %s\naliases:\n  - %s\ntags: []\ndate: %s\nuid: %s\n---\n\n# %s\n\n"
     slug title (format-time-string "%Y-%m-%d") uid title)))

(defvar my/notes-dir "~/vault")

(setq deft-directory "~/vault"        
      deft-extensions '("md")   
      deft-recursive t         
      deft-filter-only-filenames nil 
      deft-use-filename-as-title t
      deft-file-naming-rules
      '((noslash . "-")
        (nospace . "-")))

(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "/etc/profiles/per-user/katob/bin/librewolf")

;; Key binding
; (map! :n
;       :desc "browse url" "g x" #'browse-url)

(map! :leader
      :desc "Deft" "n s" #'deft)

(map! :leader
      :desc "New plain markdown note"
      "n n" #'my/new-markdown-note)

(map! :leader
      :desc "Delete current buffer"
      "d" #'kill-current-buffer)

(map! :leader
      :desc "Move to the down window"
      "j" #'windmove-down)

(map! :leader
      :desc "Move to the up window"
      "k" #'windmove-up)

(map! :leader
      :desc "Move to the left window"
      "h" #'windmove-left)

(map! :leader
      :desc "Move to the right window"
      "l" #'windmove-right)

(map! :leader
      :desc "Previous Buffer" ";" #'previous-buffer
      :desc "Next Buffer"     "'" #'next-buffer)
