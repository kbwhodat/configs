;;; config-ide.el --- Tree-sitter, lsp-mode, tempel -*- lexical-binding: t; -*-
;;; Commentary:
;; lsp-mode (lean configuration; see below) wired with emacs-lsp-booster
;; for performance.  treesit grammars are auto-wired by the nix emacs
;; wrapper via treesit-extra-load-path.
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
        (yaml-mode       . yaml-ts-mode)
        (c-mode          . c-ts-mode)
        (c++-mode        . c++-ts-mode)))

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

;; --- LSP client (lsp-mode, lean — eglot-shaped feature surface) ----
;; All UI bloat disabled.  What's left hooks into emacs primitives
;; (xref / eldoc / flymake) so the rest of the config stays unchanged
;; from the eglot era.  Booster wraps each server's stdio in a Rust
;; process that pre-parses JSON into bytecode (~4x parse speedup).
;;
;; PLIST OPT: lsp-mode's `LSP_USE_PLISTS' env var switches from
;; hash-table to plist representation for another big perf win, but
;; the var must be set at BYTECOMPILE time.  nix bytecompiles lsp-mode
;; at build time without it, so we run the (slightly slower) hash-
;; table path.  Booster is the bigger knob anyway.  To enable plists,
;; override the lsp-mode derivation in emacs.nix to set
;; LSP_USE_PLISTS=true during preBuild.
(use-package lsp-mode
  ;; python-ts-mode is hooked by `lsp-pyright' below — it must `require'
  ;; lsp-pyright (which registers the pyright client) BEFORE lsp-deferred
  ;; runs its client discovery.  If python-ts-mode were also hooked here,
  ;; the timing would race and pyright might not register in time.
  :hook ((bash-ts-mode   . lsp-deferred)
         (go-ts-mode     . lsp-deferred)
         (nix-ts-mode    . lsp-deferred)
         (c-ts-mode      . lsp-deferred)
         (c++-ts-mode    . lsp-deferred))
  :commands (lsp lsp-deferred)
  :init
  ;; NOTE: `read-process-output-max' is set to 4 MB in early-init.el — do
  ;; NOT re-set it here.  An earlier 1 MB setting silently downgraded the
  ;; LSP read buffer because this :init runs AFTER early-init.
  (setq lsp-keymap-prefix nil                    ; no SPC-l prefix; we use g-keys

        ;; --- UI bloat OFF -----------------------------------------
        lsp-headerline-breadcrumb-enable      nil
        lsp-modeline-code-actions-enable      nil
        lsp-modeline-diagnostics-enable       nil
        lsp-modeline-workspace-status-enable  nil
        lsp-lens-enable                       nil
        lsp-signature-auto-activate           nil
        lsp-enable-symbol-highlighting        nil
        lsp-semantic-tokens-enable            nil   ; treesitter handles syntax

        ;; --- "Helpful" behaviors OFF ------------------------------
        lsp-enable-indentation                nil
        lsp-enable-on-type-formatting         nil
        lsp-enable-snippet                    nil
        lsp-enable-file-watchers              nil   ; big saving in large repos
        lsp-log-io                            nil   ; no per-msg logging
        lsp-completion-show-detail            nil   ; company shows annotation; LSP detail redundant
        lsp-enable-text-document-color        nil   ; CSS color hints — not needed
        lsp-enable-folding                    nil   ; tree-sitter handles folding
        lsp-enable-dap-auto-configure         nil   ; no dap installed
        lsp-enable-links                      nil   ; clickable URL hints — minor

        ;; --- Defer to emacs primitives ---------------------------
        lsp-completion-provider               :capf
        lsp-diagnostics-provider              :flymake
        lsp-eldoc-enable-hover                nil   ; no auto-hover in echo area
        lsp-eldoc-render-all                  nil

        ;; Stop the "X is not part of any project, import root?" prompt.
        ;; Auto-detects via project.el / projectile (git root etc.).
        lsp-auto-guess-root                   t

        lsp-idle-delay                        0.5)
  :config
  ;; --- emacs-lsp-booster (Rust JSON → bytecode wrapper) -----------
  ;; Same binary that drove eglot-booster.  We hook it in via advice
  ;; on `lsp-resolve-final-command' (prepends `emacs-lsp-booster' to
  ;; the LSP server invocation) and `json-parse-buffer' (recognizes
  ;; the bytecode form and evaluates it).
  (defun my/lsp-booster--final-command (orig cmd &optional test)
    (let ((result (funcall orig cmd test)))
      (if (and (executable-find "emacs-lsp-booster")
               (not test)
               (not (file-remote-p default-directory)))
          ;; Booster defaults to emitting plists, but our lsp-mode isn't
          ;; compiled with LSP_USE_PLISTS (nix build doesn't get the env
          ;; var), so it expects hash-tables.  Explicit `--json-object-
          ;; type hashtable' makes booster match.  `--' separates booster
          ;; args from the LSP server command that follows.
          (append (list "emacs-lsp-booster"
                        "--json-object-type" "hashtable"
                        "--")
                  result)
        result)))
  (defun my/lsp-booster--json-parse (orig &rest args)
    (or (and (equal (following-char) ?#)
             (let ((bytecode (read (current-buffer))))
               (when (byte-code-function-p bytecode)
                 (funcall bytecode))))
        (apply orig args)))
  (advice-add 'lsp-resolve-final-command :around #'my/lsp-booster--final-command)
  (advice-add 'json-parse-buffer         :around #'my/lsp-booster--json-parse))

;; --- lsp-ui: visual layers (doc popup, sideline, peek, imenu) ------
;; All four submodes ON so you can see what each does.  Each can be
;; toggled or stripped after deciding what you like.  Brings child
;; frames back; mitigation hook (below) hides lsp-ui-doc on macOS
;; Cmd-Tab away.
(use-package lsp-ui
  :after lsp-mode
  :hook (lsp-mode . lsp-ui-mode)
  :init
  (setq
   ;; --- DOC popup (cursor-anchored hover) ------------------------
   lsp-ui-doc-enable             t
   lsp-ui-doc-show-with-cursor   nil    ; on-demand only (use `g h')
   lsp-ui-doc-show-with-mouse    nil    ; keyboard-only workflow
   lsp-ui-doc-position           'at-point
   lsp-ui-doc-max-width          80
   lsp-ui-doc-max-height         20
   lsp-ui-doc-delay              0.2
   lsp-ui-doc-border             "#525868"

   ;; --- SIDELINE (inline info on the right of each line) --------
   lsp-ui-sideline-enable                t
   lsp-ui-sideline-show-diagnostics      t
   lsp-ui-sideline-show-code-actions     nil   ; "extract function" etc. — disabled
   lsp-ui-sideline-show-hover            nil   ; no inline sig; use `g h' on demand
   lsp-ui-sideline-show-symbol           nil   ; pure noise — symbol name inline
   lsp-ui-sideline-update-mode           'line ; only update on line change
   lsp-ui-sideline-delay                 0.2

   ;; --- PEEK (replacement for jump-to-def window) ---------------
   lsp-ui-peek-enable                    t
   lsp-ui-peek-always-show               t     ; show overlay even for single result (default skips for 1 def)
   lsp-ui-peek-show-directory            t
   lsp-ui-peek-list-width                60
   lsp-ui-peek-fontify                   'always

   ;; --- IMENU sidebar ------------------------------------------
   lsp-ui-imenu-enable                   t
   lsp-ui-imenu-auto-refresh             'after-save
   lsp-ui-imenu-window-width             32))

;; macOS Cmd-Tab orphan mitigation: hide lsp-ui-doc child frame when
;; emacs loses focus.  Scoped — does NOT touch other posframes.
(with-eval-after-load 'lsp-ui-doc
  (defun my/lsp-ui-doc--hide-on-focus-out ()
    (unless (frame-focus-state)
      (when (fboundp 'lsp-ui-doc-hide)
        (lsp-ui-doc-hide))))
  (add-function :after after-focus-change-function
                #'my/lsp-ui-doc--hide-on-focus-out))

;; --- Pyright client for lsp-mode (Python) --------------------------
;; lsp-mode core doesn't ship a pyright client.  Without this, Python
;; buffers only get ruff (linting) — no definitions / references /
;; hover.  pyright provides those; ruff stays attached as an "add-on"
;; client for linting + formatting suggestions.
(use-package lsp-pyright
  :init
  (setq lsp-pyright-langserver-command "pyright")    ; use pkgs.pyright on PATH
  :hook (python-ts-mode . (lambda ()
                            (require 'lsp-pyright)
                            (lsp-deferred))))

;; flymake is the diagnostics backend (lsp-diagnostics-provider :flymake).
;; Force-load it so `flymake-goto-next-error' etc. are commandp BEFORE
;; lsp attaches — otherwise pressing `g e' in a non-LSP buffer errors:
;;   Wrong type argument: commandp, flymake-goto-next-error
(require 'flymake)

;; `lsp-diagnostics.el' is the sub-module that wires LSP diagnostics
;; INTO flymake.  lsp-mode lazy-loads it, but if a buffer attaches LSP
;; before the lazy-load trigger fires, `lsp-diagnostics-mode' never
;; activates and diagnostics never reach flymake → red squiggles
;; missing + `g e' walks nothing.  Explicit require sidesteps the race.
(with-eval-after-load 'lsp-mode
  (require 'lsp-diagnostics))

;; --- Vim-style LSP keybindings (consistent with nvim + Zed) ---------
;; Scoped to `prog-mode-map' so `g i' doesn't shadow defaults in
;; text/org/markdown.  `g i' in default evil is `evil-insert-resume'
;; which almost no one uses — overriding for "go to impl" is the
;; community convention.
(with-eval-after-load 'evil
  (evil-define-key 'normal prog-mode-map
    ;; --- Navigation ---
    (kbd "g d") #'lsp-find-definition             ; def at point
    (kbd "g D") #'lsp-find-declaration            ; declaration
    (kbd "g r") #'lsp-find-references             ; find all references
    (kbd "g i") #'lsp-find-implementation         ; impl(s)
    (kbd "g t") #'lsp-find-type-definition        ; type def

    ;; --- Info ---
    (kbd "g h") #'lsp-ui-doc-glance               ; cursor-anchored hover popup
    (kbd "g H") #'lsp-describe-thing-at-point     ; *lsp-help* buffer (fallback)
    (kbd "g s") #'lsp-signature-activate          ; signature help (cycle w/ C-n/C-p)

    ;; --- Refactor ---
    (kbd "g R") #'lsp-rename                      ; rename symbol across project
    (kbd "g a") #'lsp-execute-code-action         ; run a code action at point
    (kbd "g w") #'xref-find-apropos               ; fuzzy-search ANY symbol in workspace (via lsp-xref backend)
    (kbd "g f") #'lsp-format-buffer               ; LSP format (NB: apheleia also formats)

    ;; --- Diagnostics ---
    (kbd "g e") #'flymake-goto-next-error         ; next diagnostic
    (kbd "g E") #'flymake-goto-prev-error         ; prev diagnostic
    (kbd "g q") #'flymake-show-buffer-diagnostics ; list errors in this buffer
    (kbd "g Q") #'flymake-show-project-diagnostics ; project-wide errors list

    ;; --- lsp-ui peek (preview without jumping) ---
    (kbd "g p d") #'lsp-ui-peek-find-definitions  ; peek defs
    (kbd "g p r") #'lsp-ui-peek-find-references   ; peek refs
    (kbd "g p i") #'lsp-ui-peek-find-implementation  ; peek impls
    (kbd "g p s") #'lsp-ui-peek-find-workspace-symbol)) ; peek workspace sym

;; --- Use consult's xref renderer (fuzzy list + live preview) -------
;; Default `xref-find-references' pops a `*xref*' buffer in a new
;; window — passable, but takes screen real estate and you scroll a
;; static list.  consult-xref shows results in the minibuffer with
;; vertico filtering and live preview at point.
;;
;; NOTE: `consult-xref' is provided by the sub-library `consult-xref.el',
;; NOT the main `consult.el'.  In our nixpkgs build the autoloads file
;; doesn't expose the function, so loading `consult' alone is not
;; enough — `lsp-show-xrefs' calls `consult-xref' directly and errors
;; with `void-function consult-xref'.  Explicit `require' fixes it.
(with-eval-after-load 'consult
  (require 'consult-xref)
  (setq xref-show-xrefs-function       #'consult-xref
        xref-show-definitions-function #'consult-xref))

;; --- Tempel snippets (replaces yasnippet; tempel is lighter) ---
(use-package tempel
  :hook ((prog-mode . tempel-abbrev-mode))
  :bind (("M-+" . tempel-complete)
         ("M-*" . tempel-insert))
  :init
  (setq tempel-path
        (expand-file-name "templates/*.eld" user-emacs-directory)))

;; --- In-buffer completion (company-mode, overlay-based) ------------
;; Overlay rendering, not child frames — immune to the macOS Cmd-Tab
;; orphan that hits corfu / posframe consumers.
;;
;; Scoped to prog + text modes instead of `global-company-mode'.  Global
;; mode turns company on in dired, magit, *Messages*, help, etc. where
;; there's nothing useful to complete — wasting cycles per keystroke
;; and adding hook overhead in every buffer.  prog/text covers every
;; buffer where completion is actually wanted (code, markdown, org,
;; commit messages).
(use-package company
  :hook ((prog-mode . company-mode)
         (text-mode . company-mode))
  :init
  (setq company-idle-delay 0.2
        company-minimum-prefix-length 3
        company-selection-wrap-around t
        company-tooltip-align-annotations t
        company-tooltip-limit 12
        company-show-quick-access t          ; M-1..M-9 to pick by number
        company-frontends '(company-pseudo-tooltip-frontend
                            company-echo-metadata-frontend)
        ;; Defaults dismiss the popup mid-typing (unique-match, no-match
        ;; auto-abort, single-candidate hide).  Override → popup stays
        ;; put until RET / ESC.
        company-abort-on-unique-match nil
        company-require-match nil
        company-selection-default nil))      ; no auto-highlight on open

;; Popup styling.  DO NOT add :box to company-tooltip — it triggers
;; per-character-cell rendering and lags scroll severely.
(with-eval-after-load 'company
  (set-face-attribute 'company-tooltip nil
                      :background "#11161e" :foreground "#dfe7f0")
  (set-face-attribute 'company-tooltip-selection nil
                      :background "#3b6ea5" :foreground "#ffffff" :weight 'bold)
  (set-face-attribute 'company-tooltip-common nil
                      :foreground "#fbbf24" :weight 'bold)
  (set-face-attribute 'company-tooltip-common-selection nil
                      :foreground "#facc15" :weight 'bold)
  (set-face-attribute 'company-tooltip-annotation nil
                      :foreground "#a3aab8" :slant 'italic)
  (set-face-attribute 'company-tooltip-annotation-selection nil
                      :foreground "#e8eef7" :slant 'italic :weight 'bold)
  (set-face-attribute 'company-scrollbar-bg nil :background "#11161e")
  (set-face-attribute 'company-scrollbar-fg nil :background "#525868"))

;; --- envrc: project-local env vars via direnv -----------------------
;; Without this, lsp-spawned servers and `M-x compile` see your login
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

;; exercism.org — transient menu via `M-x exercism' / SPC c e.
;; CLI installed via emacs.nix; one-time `Configure' -> API token.
(use-package exercism
  :defer t
  :commands (exercism)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader "ce" '(exercism :which-key "exercism (transient)")))))

(provide 'config-ide)
;;; config-ide.el ends here
