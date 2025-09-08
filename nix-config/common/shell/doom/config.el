;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;;;; —— core “don’t lose my work” settings ——
;; Save point (cursor) in files
(save-place-mode 1)

;; disable doom-modeline
(remove-hook 'doom-first-buffer-hook #'doom-modeline-mode)

;; Save minibuffer/history across sessions
(savehist-mode 1)
(setq history-length 1000)

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
(setq doom-font (font-spec :family "ComicShannsMono Nerd Font" :size 16))

;; If you use a custom roam dir, set it BEFORE org-roam loads
(setq org-directory "~/vault/"
      org-roam-directory (file-truename org-directory)
      org-roam-file-extensions '("org" "md")
      org-roam-completion-everywhere nil)


(defun my/new-markdown-note (title)
  "Create a new Markdown note with TITLE as the filename, and insert template if new."
  (interactive "sNote title: ")
  (let* ((dir "~/vault/")  ;; change this path to your notes folder
         (slug (replace-regexp-in-string " " "-" (downcase title)))
         (file (expand-file-name (concat slug ".md") dir)))
    (unless (file-exists-p dir)
      (make-directory dir t))
    (if (file-exists-p file)
        (find-file file)
      (find-file file)
      ;; insert template only if it's a brand new file
      (insert (my/markdown-template title))
      (save-buffer))))

(defun my/markdown-template (title slug)
  "Return a string for the default Markdown note template with TITLE and SLUG."
  (let ((uid (format "%d-%s"
                     (random (expt 10 10))  ;; 10-digit random number
                     (substring (md5 (number-to-string (float-time))) 0 4))))
    (format
     "---\nid: %s\naliases:\n  - %s\ntags: []\ndate: %s\nuid: %s\n---\n\n"
     slug
     title
     (format-time-string "%Y-%m-%d")
     uid)))

(defvar my/notes-dir "~/vault")

(setq deft-directory "~/vault"        ;; where your markdown notes live
      deft-extensions '("md")   ;; which file types to include
      deft-recursive t                ;; search subfolders too
      deft-filter-only-filenames nil 
      deft-use-filename-as-title t)

; (defun notes-search-md () (interactive)
;   (let ((default-directory my/notes-dir)
;         (consult-ripgrep-args "rg --null --line-number --column --smart-case --no-heading --color=never -e '^tags:' -g *.md"))
;     (consult-ripgrep default-directory)))

;; Key binding
(map! :leader
      :desc "Deft" "n s" #'deft)

(map! :leader
      :desc "New plain markdown note"
      "n n" #'my/new-markdown-note)

(map! :leader
      :desc "Delete current buffer"
      "d" #'kill-current-buffer)

(map! :g
      :desc "Move to the down window"
      "C-j" #'windmove-down)

(map! :g
      :desc "Move to the up window"
      "C-k" #'windmove-up)

(map! :g
      :desc "Move to the left window"
      "C-h" #'windmove-left)

(map! :g
      :desc "Move to the right window"
      "C-l" #'windmove-right)

(map! :leader
      :desc "Previous Buffer" ";" #'previous-buffer
      :desc "Next Buffer"     "'" #'next-buffer)
