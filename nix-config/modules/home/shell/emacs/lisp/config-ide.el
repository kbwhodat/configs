;;; config-ide.el --- Tree-sitter, eglot, tempel -*- lexical-binding: t; -*-
;;; Commentary:
;; eglot is built-in to emacs 30.  treesit grammars are auto-wired by the
;; nix emacs wrapper via treesit-extra-load-path.
;;; Code:

;; --- Built-in ts-modes for py/sh/json/yaml/go (no extra package) ---
(setq major-mode-remap-alist
      '((python-mode . python-ts-mode)
        (bash-mode   . bash-ts-mode)
        (sh-mode     . bash-ts-mode)
        (json-mode   . json-ts-mode)
        (yaml-mode   . yaml-ts-mode)
        (go-mode     . go-ts-mode)))

;; --- nix-ts-mode for *.nix ---
(use-package nix-ts-mode
  :mode "\\.nix\\'")

;; --- Eglot per language (built-in) ---
(use-package eglot
  :ensure nil
  :hook ((python-ts-mode . eglot-ensure)
         (bash-ts-mode   . eglot-ensure)
         (go-ts-mode     . eglot-ensure)
         (nix-ts-mode    . eglot-ensure))
  :init
  ;; Perf tuning (source: jamescherti/minimal-emacs.d):
  ;; - skip minibuffer progress spam from pyright/gopls
  ;; - kill LSP server when last managed buffer closes (saves memory)
  ;; - disable the events buffer (was a 2 MB ring buffer per server)
  ;; - skip jsonrpc event hook overhead
  (setq eglot-report-progress nil
        eglot-autoshutdown t
        eglot-events-buffer-config '(:size 0 :format short)
        jsonrpc-event-hook nil)
  :config
  (add-to-list 'eglot-server-programs
               '(python-ts-mode . ("pyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs
               '(bash-ts-mode   . ("bash-language-server" "start")))
  (add-to-list 'eglot-server-programs
               '(go-ts-mode     . ("gopls")))
  (add-to-list 'eglot-server-programs
               '(nix-ts-mode    . ("nil"))))

;; --- Tempel snippets (replaces yasnippet; tempel is lighter) ---
(use-package tempel
  :hook ((prog-mode . tempel-abbrev-mode))
  :bind (("M-+" . tempel-complete)
         ("M-*" . tempel-insert))
  :init
  (setq tempel-path
        (expand-file-name "templates/*.eld" user-emacs-directory)))

;; --- In-buffer completion (corfu + cape) -----------------------------
;; corfu = popup-as-you-type. cape = extra completion-at-point sources.
;; Before this we had NO popup completion — only manual M-TAB.

(use-package corfu
  :hook (after-init . global-corfu-mode)
  :init
  (setq corfu-cycle t                ; wrap around list
        corfu-auto t                 ; popup automatically (no manual M-TAB)
        corfu-auto-delay 0.1
        corfu-auto-prefix 2
        corfu-preselect 'prompt      ; preselect the input as a candidate
        corfu-popupinfo-delay '(0.5 . 0.5)
        corfu-quit-no-match 'separator))

(use-package cape
  :after corfu
  :init
  ;; Add extra capf sources: file paths, dabbrev (words from buffers),
  ;; abbrevs.  These show up alongside language-specific (eglot) ones.
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev))

;; --- eglot-booster: 4x faster LSP JSON via Rust wrapper -------------
;; Requires the emacs-lsp-booster binary on PATH (installed via
;; emacs.nix home.packages).
(use-package eglot-booster
  :after eglot
  :config (eglot-booster-mode))

(provide 'config-ide)
;;; config-ide.el ends here
