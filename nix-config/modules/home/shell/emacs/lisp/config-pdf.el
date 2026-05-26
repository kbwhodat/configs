;;; config-pdf.el --- PDF viewer -*- lexical-binding: t; -*-
;;; Commentary:
;; pdf-tools auto-loads when opening *.pdf.
;;; Code:

(use-package pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  ;; pdf-tools-install eagerly tries to enable pdf-occur-global-minor-mode
  ;; which lives in pdf-occur.el and isn't loaded yet at install time
  ;; (autoload-ordering bug in vedang/pdf-tools v20240429). Skip it —
  ;; the :mode autoload above routes *.pdf to pdf-view-mode without
  ;; needing the global install. If we ever need pdf-tools-install,
  ;; require 'pdf-occur first or wrap in (ignore-errors ...).
  )

(provide 'config-pdf)
;;; config-pdf.el ends here
