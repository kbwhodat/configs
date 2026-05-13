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
      (my/leader "o f" '(elfeed :which-key "rss"))))
  :config
  (setq elfeed-db-directory
        (expand-file-name "elfeed-db" user-emacs-directory))
  (let ((feeds-file
         (expand-file-name "elfeed-feeds.el" user-emacs-directory)))
    (when (file-exists-p feeds-file) (load feeds-file))))

(use-package pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config (pdf-tools-install :no-query))

(provide 'config-feeds)
;;; config-feeds.el ends here
