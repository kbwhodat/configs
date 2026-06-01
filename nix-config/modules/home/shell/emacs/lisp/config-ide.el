;;; config-ide.el --- Tree-sitter, eglot, tempel -*- lexical-binding: t; -*-
;;; Commentary:
;; eglot is built-in to emacs 30.  treesit grammars are auto-wired by the
;; nix emacs wrapper via treesit-extra-load-path.
;;; Code:

;; --- Explicit tree-sitter remaps -----------------------------------
;; Keep startup predictable: remap only the languages this config uses
;; instead of loading `treesit-auto' to discover every installed grammar.
(setq major-mode-remap-alist
      '((python-mode     . python-ts-mode)
        (sh-mode         . bash-ts-mode)
        (go-mode         . go-ts-mode)
        (js-mode         . js-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (json-mode       . json-ts-mode)
        (yaml-mode       . yaml-ts-mode)))

(add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode))

;; --- lua-ts-mode (built-in emacs 30+) for *.lua --------------------
;; No lua-mode package installed, so we just hard-route .lua to the
;; built-in tree-sitter mode (requires tree-sitter-lua grammar — see
;; emacs.nix `with-grammars').  Covers Hammerspoon, Wezterm, Neovim,
;; awesome-wm configs.
(add-to-list 'auto-mode-alist '("\\.lua\\'" . lua-ts-mode))

;; --- nix-ts-mode for *.nix (treesit-auto doesn't ship a nix recipe) ---
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
        jsonrpc-event-hook nil
        eglot-workspace-configuration
        '(:nil (:nix (:flake (:autoArchive t)))))
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
        corfu-auto-delay 0.2
        corfu-auto-prefix 3
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

;; --- envrc: project-local env vars via direnv -----------------------
;; Without this, eglot-spawned LSPs and `M-x compile` see your login
;; shell PATH/env — not the project's nix develop / virtualenv / etc.
;; envrc consults the nearest .envrc and exports its variables into
;; every subprocess emacs spawns from that buffer.
(use-package envrc
  :hook (after-init . envrc-global-mode)
  :config
  ;; --- Async direnv -------------------------------------------------
  ;; envrc's `envrc--export' uses `call-process' synchronously to
  ;; invoke `direnv export json'.  For `use flake'-style .envrc files
  ;; (nix, guix), that call can block emacs for 5-60 seconds the first
  ;; time per project per session.  Upstream tracks this as a known
  ;; limitation (purcell/envrc issues #6 + #53, both closed without a
  ;; merged fix as of 2025-12).
  ;;
  ;; Around-advice on `envrc--export':
  ;;   - if not already running for ENV-DIR, spawn `direnv export json'
  ;;     via `make-process' (non-blocking) and return 'none immediately
  ;;     so envrc--update doesn't stall
  ;;   - the sentinel parses the JSON, puts the real env in
  ;;     envrc--cache (overwriting the 'none we returned), and
  ;;     re-applies the env to every live buffer in ENV-DIR
  ;;   - duplicate concurrent calls for the same dir are coalesced
  ;;     via `my/envrc--pending'
  ;;
  ;; Trade-off: first project visit sees the GLOBAL env briefly (a
  ;; second or two for warm-cache direnv, longer for cold-cache nix
  ;; flake).  Once the sentinel fires, env is correct.  Subsequent
  ;; visits hit envrc--cache → instant.  vs blocking emacs entirely.
  (require 'json)
  (defvar my/envrc--pending (make-hash-table :test 'equal)
    "Map of env-dir -> t for direnvs currently running async.
Coalesces duplicate concurrent calls for the same dir.")
  (defun my/envrc-async-export (_orig-fn env-dir)
    "Async wrapper around `envrc--export'.  Returns 'none immediately,
spawns direnv in background, applies real env when it finishes."
    (cond
     ((gethash env-dir my/envrc--pending) 'none)
     (t
      (puthash env-dir t my/envrc--pending)
      (let ((global-env (default-value 'process-environment))
            (output-buffer (generate-new-buffer " *envrc-async-out*"))
            (default-directory env-dir))
        (make-process
         :name (format "envrc-async %s" env-dir)
         :buffer output-buffer
         :command (list envrc-direnv-executable "export" "json")
         :noquery t
         :sentinel
         (lambda (proc _event)
           (when (memq (process-status proc) '(exit signal))
             (remhash env-dir my/envrc--pending)
             (let* ((exit-code (process-exit-status proc))
                    (output (and (buffer-live-p output-buffer)
                                 (with-current-buffer output-buffer
                                   (buffer-string)))))
               (when (buffer-live-p output-buffer)
                 (kill-buffer output-buffer))
               (when (and (numberp exit-code) (zerop exit-code))
                 (let ((env (if (or (null output)
                                    (string-empty-p (string-trim output)))
                                'none
                              (condition-case nil
                                  (with-temp-buffer
                                    (insert output)
                                    (goto-char (point-min))
                                    (let ((json-key-type 'string))
                                      (json-read-object)))
                                (error 'error)))))
                   ;; Cache the real result (overwrites the 'none we
                   ;; returned synchronously).
                   (puthash (envrc--cache-key env-dir global-env)
                            env envrc--cache)
                   ;; Re-apply to all live buffers in this env-dir.
                   (dolist (buf (buffer-list))
                     (when (and (buffer-live-p buf)
                                (buffer-local-value 'envrc-mode buf))
                       (with-current-buffer buf
                         (when (equal (envrc--find-env-dir) env-dir)
                           (envrc--apply buf env)))))
                   (message "envrc: %s loaded" env-dir)))))))
        'none))))
  (advice-add 'envrc--export :around #'my/envrc-async-export))

;; --- apheleia: subprocess CLI formatter, on-demand only -------------
;; Installed but NOT hooked to save — user values their manual
;; formatting (compact one-liners, deliberate alignment, etc.) and
;; doesn't want it auto-clobbered on every C-x C-s.  Available via:
;;
;;   M-x apheleia-format-buffer  — format current buffer once
;;   M-x apheleia-mode           — toggle save-format for this buffer
;;
;; For per-project save-format, drop a .dir-locals.el at the project root:
;;
;;   ((nil . ((eval . (apheleia-mode 1)))))
;;
;; Default formatter for python is `black'; override to `ruff' since
;; ruff is on PATH via emacs.nix home.packages.
(use-package apheleia
  :defer t
  :commands (apheleia-format-buffer apheleia-mode)
  :config
  (setf (alist-get 'python-mode apheleia-mode-alist) 'ruff
        (alist-get 'python-ts-mode apheleia-mode-alist) 'ruff))

;; --- Built-in compile/run --------------------------------------------
;; `compile' is the native build runner: opens a *compilation* buffer,
;; captures stdout+stderr, parses errors so RET / `next-error' jumps
;; to the source line, and remembers the command for `recompile'.
;;
;; `project-compile' (built-in to emacs 28+) does the same but runs
;; from the project root and caches the command per-project — preferred
;; for repo work since you can ride the same SPC c c forever.
(setq-default compile-command "")             ; don't default prompts to "make -k"

(setq compilation-scroll-output 'first-error  ; auto-scroll, stop at first error
      compilation-ask-about-save nil          ; auto-save buffers before compile
      compilation-always-kill t               ; one compile at a time
      compilation-environment '("TERM=dumb")) ; tell tools they're not in a tty

;; ANSI color escape sequences (cargo, npm, go test, …) interpreted instead
;; of rendered as literal "[0;31m".
(add-hook 'compilation-filter-hook #'ansi-color-compilation-filter)

;; Leader bindings under SPC c
;; cc  compile (or recompile from project cache)   cr  recompile
;; cC  re-prompt for compile command               ck  kill running compile
;; cn  next error                                  cp  previous error
;; cv  run command in ghostel
(with-eval-after-load 'general
  (when (fboundp 'my/leader)
    (my/leader
      "c"  '(:ignore t :which-key "compile/run")
      "cc" '(project-compile     :which-key "compile (project)")
      "cC" '(compile             :which-key "compile (prompt)")
      "cr" '(recompile           :which-key "recompile last")
      "ck" '(kill-compilation    :which-key "kill compile")
      "cn" '(next-error          :which-key "next error")
      "cp" '(previous-error      :which-key "prev error")
      "cv" '(my/ghostel-run-command :which-key "run in ghostel")
      "c&" '(async-shell-command :which-key "background shell"))))

(provide 'config-ide)
;;; config-ide.el ends here
