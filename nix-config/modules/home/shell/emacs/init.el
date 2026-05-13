;;; init.el --- Personal Emacs initialization -*- lexical-binding: t; -*-
;;; Commentary:
;; This file is a dispatcher only.  All configuration lives in lisp/config-*.el.
;; Edit those files, not this one.
;;; Code:

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; use-package is built-in to emacs 30+.

;; --- Topical config files (order matters for general / evil) ---
(require 'config-perf)         ; save-place, recentf, savehist, history-length
(require 'config-ui)           ; theme + font (window-setup-hook), modeline, frame
(require 'config-evil)         ; evil + evil-collection (idle) + general + which-key
(require 'config-completion)   ; vertico, orderless, marginalia, consult
(require 'config-ide)          ; ts-mode remap, eglot, tempel
(require 'config-git)          ; magit (deferred)
(require 'config-notes)        ; markdown, notdeft, persistent-scratch
(require 'config-sessions)     ; persp-mode (no eager restore)
(require 'config-term)         ; vterm
(require 'config-llm)          ; gptel
(require 'config-feeds)        ; elfeed, pdf-tools

;; --- Buffer hygiene (after init only, not eagerly) ---
(defun my/initial-buffer-setup ()
  "Tidy up scratch / messages after init."
  (when (and (get-buffer "*scratch*")
             (not (eq (length (buffer-list)) 1)))
    (kill-buffer "*scratch*"))
  (when (get-buffer "*Messages*")
    (kill-buffer "*Messages*")))
(add-hook 'after-init-hook #'my/initial-buffer-setup)

;; --- Keep GUI customizations separate ---
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file) (load custom-file))

(provide 'init)
;;; init.el ends here
