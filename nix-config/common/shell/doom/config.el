;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;;;; —— core “don’t lose my work” settings ——
;; Save point (cursor) in files
(save-place-mode 1)

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
      org-roam-directory (file-truename org-directory))

(setq org-agenda-files '("~/vault/"))

(use-package! org-roam
  :init
  ;; ensure the dir is set before loading
  (setq org-roam-directory (file-truename org-directory))
  :custom
  (org-roam-completion-everywhere t)
  :config
  (org-roam-db-autosync-mode)

  ;; custom capture template
  (setq org-roam-capture-templates
        '(("d" "default" plain "%?"
           :if-new (file+head "${slug}.org"
                              "#+title: ${title}\n#+date: %<%Y-%m-%d>\n#+filetags: ")
           :unnarrowed t))))

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
