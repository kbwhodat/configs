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
(require 'config-ide)          ; ts-mode remap, lsp-mode + lsp-ui, tempel, company
(require 'config-git)          ; magit (deferred)
(require 'config-notes)        ; markdown, notdeft, persistent-scratch
(require 'config-sessions)     ; persp-mode (no eager restore)
(require 'config-session-lite) ; fast file/workspace snapshots
(require 'config-tree)         ; treemacs sidebar (SPC e)
(require 'config-files)        ; oil/netrw-style bottom-popup dired ("-" trigger)
(require 'config-term)         ; vterm (SPC o t half / SPC o T full)
(require 'config-llm)          ; agent-shell (ACP)
(require 'config-pdf)          ; pdf-tools
(require 'config-reader)       ; nov.el (.epub) + olivetti

;; Buffer hygiene block removed.
;; Previously killed `*scratch*' (no-op — persistent-scratch's
;; `kill-buffer-query-functions' refuses) and `*Messages*' (real
;; behavior — but discards warnings, native-comp logs, LSP startup
;; notes, and `(message ...)' history that's invaluable when something
;; breaks later).  Both buffers stay live; persp-mode's chatter filter
;; (`my/persp-skip-chatter-buffer-p' in config-sessions.el) already
;; hides `*Messages*' from the workspace buffer list.

;; --- Keep GUI customizations separate ---
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file) (load custom-file))

(provide 'init)
;;; init.el ends here
