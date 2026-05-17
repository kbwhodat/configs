;;; config-feeds.el --- RSS (elfeed) + PDF (pdf-tools) -*- lexical-binding: t; -*-
;;; Commentary:
;; elfeed feed list lives at ~/.emacs.d/elfeed-feeds.el (user maintained).
;; pdf-tools auto-loads when opening *.pdf.
;;; Code:

(use-package elfeed
  :defer t
  :commands (elfeed)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader "or" '(elfeed :which-key "rss"))))
  :config
  (setq elfeed-db-directory
        (expand-file-name "elfeed-db" user-emacs-directory))
  (let ((feeds-file
         (expand-file-name "elfeed-feeds.el" user-emacs-directory)))
    (when (file-exists-p feeds-file) (load feeds-file))))

;; --- Full-article reader (R) -----------------------------------------
;; Most feeds publish only a snippet.  Pressing `R' on an entry fetches
;; the link in eww and immediately runs `eww-readable' to strip nav /
;; ads / footers — equivalent to newsboat's full-content view.
;;
;; The hook is buffer-local + self-removing so it only fires once per
;; render and only in the eww buffer we just opened (no global state).
(defun my/elfeed--make-readable-once ()
  "Run `eww-readable' the first time eww renders, then unhook self."
  (eww-readable)
  (remove-hook 'eww-after-render-hook #'my/elfeed--make-readable-once 'local))

(defun my/elfeed-show-readable ()
  "Open the current entry's full article in eww with readability."
  (interactive)
  (let ((entry (or (and (boundp 'elfeed-show-entry) elfeed-show-entry)
                   (and (fboundp 'elfeed-search-selected)
                        (elfeed-search-selected :ignore-region)))))
    (unless entry (user-error "No elfeed entry at point"))
    (let ((url (elfeed-entry-link entry)))
      (eww url)
      (add-hook 'eww-after-render-hook
                #'my/elfeed--make-readable-once nil 'local))))

(with-eval-after-load 'elfeed-search
  (evil-define-key 'normal elfeed-search-mode-map (kbd "R") #'my/elfeed-show-readable))
(with-eval-after-load 'elfeed-show
  (evil-define-key 'normal elfeed-show-mode-map (kbd "R") #'my/elfeed-show-readable))

(use-package pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  ;; pdf-tools-install eagerly tries to enable pdf-occur-global-minor-mode
  ;; which lives in pdf-occur.el and isn't loaded yet at install time
  ;; (autoload-ordering bug in vedang/pdf-tools v20240429). Skip it —
  ;; the :mode autoload above routes *.pdf to pdf-view-mode without
  ;; needing the global install. If we ever need pdf-tools-install,
  ;; require 'pdf-occur first or wrap in (ignore-errors ...).
  )

(provide 'config-feeds)
;;; config-feeds.el ends here
