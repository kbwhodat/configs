;;; config-ui.el --- Theme, font, modeline, frame, browse-url -*- lexical-binding: t; -*-
;;; Commentary:
;; Theme + font deferred to window-setup-hook so they don't block first paint.
;;; Code:

;; --- Relative line numbers when enabled (vim-style) ---
(setq display-line-numbers-type 'relative)

;; --- Minimal modeline: filled vs hollow dot + buffer name ---
(setq-default
 mode-line-format
 '((:eval
    (concat
     (if (buffer-modified-p)
         (concat
          (propertize "   ● " 'face '(:foreground "#ffffff" :weight bold))
          (propertize "%b"     'face '(:foreground "#ffffff" :weight bold)))
       (concat
        (propertize "   ○ " 'face '(:weight bold))
        (propertize "%b"    'face '(:weight bold))))))))

;; --- Minions: declutter minor-mode lighters ---
(use-package minions
  :defer 1
  :config (minions-mode 1))

;; --- Theme load path (kbwhodat doom-alabaster fetched via nix) ---
(add-to-list 'custom-theme-load-path
             (expand-file-name "themes/doom-alabaster-theme" user-emacs-directory))

;; --- Theme: load after first frame is visible ---
(use-package doom-themes
  :defer t
  :init
  (add-hook 'window-setup-hook
            (lambda () (load-theme 'doom-alabaster t))))

;; --- Font: apply after first frame ---
(add-hook 'window-setup-hook
          (lambda ()
            (set-face-attribute 'default nil
                                :family "ComicShannsMono Nerd Font Mono"
                                :height 135)))

;; --- Browse URL: open in external firefox ---
(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "/etc/profiles/per-user/katob/bin/firefox")

(provide 'config-ui)
;;; config-ui.el ends here
