;;; init.el --- Personal Emacs initialization -*- lexical-binding: t; -*-
;;; Commentary:
;; This file is a dispatcher only.  All configuration lives in lisp/config-*.el.
;; Edit those files, not this one.
;;; Code:

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

;; --- AOT-native-compiled config (built by nix; see emacs.nix) -------
;; The nix derivation ships .eln for every config-*.el under lisp/eln/.
;; Register that dir so the elc→eln swap picks them up on `require'.
;; APPEND (last arg t): the first entry of `native-comp-eln-load-path'
;; must stay the writable user eln-cache — the JIT writes there.
(add-to-list 'native-comp-eln-load-path
             (expand-file-name "lisp/eln/" user-emacs-directory) t)

;; Backstop: NEVER let the async JIT compile config files.  Its workers
;; compile each file in isolation — without init.el loaded — so
;; cross-file macros (`my/leader', `evil-define-key') miscompile into
;; function calls, and the poisoned .eln breaks the next daemon start
;; with "Invalid function: evil-define-key".  With the AOT .eln present
;; the JIT has nothing to do anyway; this covers the edge case where
;; the eln lookup misses (e.g. mid-upgrade version-dir mismatch) —
;; falling back to plain byte-code, which is correct, just slower.
;; Second regexp matches the files via their store truename.
;; (Defcustom lives in comp-run.el, not yet loaded; plain setq binds it
;; and the later defcustom preserves the value.)
(setq native-comp-jit-compilation-deny-list
      '("/lisp/config-[^/]*\\.el\\'"
        "emacs-config-lisp-compiled/config-[^/]*\\.el\\'"))

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
(require 'config-rss)          ; elfeed, extraction-first reading (SPC o r)
(require 'config-freeze-watchdog) ; TEMPORARY: gopls freeze diagnostics (M-x my/freeze-report)

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
