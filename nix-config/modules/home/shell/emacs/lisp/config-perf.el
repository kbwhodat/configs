;;; config-perf.el --- Persistence + cheap built-ins -*- lexical-binding: t; -*-
;;; Commentary:
;; benchmark-init is loaded from early-init.el (must be first).
;; This file enables built-in modes that are cheap and globally useful.
;;; Code:

;; Remember cursor position per file
(save-place-mode 1)

;; Recent files — needed for SPC f r binding
(setq recentf-max-saved-items 500)
(recentf-mode 1)

(provide 'config-perf)
;;; config-perf.el ends here
