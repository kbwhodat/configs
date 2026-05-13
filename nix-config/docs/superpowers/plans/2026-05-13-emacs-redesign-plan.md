# Emacs Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current 388-line eager-loaded `~/.emacs.d/init.el` with a daemon-only, declaratively-managed, lazy-loaded Emacs 30.2 configuration that hits ≤ 1.5 s GUI cold-start, ≤ 0.35 s batch-init, and ≤ 100 ms warm `emacsclient` frame on a slow Mac, while staying a one-stop-shop dev environment (magit, eglot, vterm, gptel, elfeed, pdf-tools, notdeft).

**Architecture:** New module directory `modules/home/shell/emacs/` with `early-init.el` + `init.el` (≤ 50-line dispatcher) + `lisp/config-*.el` topical files. Every non-essential package wraps in `use-package … :defer t`. Theme/font load on `window-setup-hook` (after first frame). Persp-mode eager session restore removed; restoration becomes manual via `SPC TAB r`. Native AOT compilation + tree-sitter + eglot are all already built into your `pkgs.emacs` (verified).

**Tech Stack:** Emacs 30.2 (native-AOT, treesit, eglot, use-package built-in), Nix flake + home-manager, evil + evil-collection + general (SPC leader), vertico/orderless/marginalia/consult, magit, eglot (pyright / bash-language-server / gopls / nil), notdeft + xapian.

**Spec reference:** `docs/superpowers/specs/2026-05-13-emacs-redesign-design.md` (commit `b5e34d0`).

---

## Pre-flight

- [ ] Confirm clean working tree apart from in-flight home-manager fix:
  ```bash
  git status --short
  ```
  Expected: spec doc committed (`b5e34d0`). `flake.nix`, `flake.lock`, `modules/home/ai/default.nix`, `modules/home/macos/aerospace.nix` are uncommitted from prior session — leave them alone, they belong to the home-manager fix. Do NOT touch them.

- [ ] Capture today's baseline numbers for regression comparison:
  ```bash
  mkdir -p docs/superpowers/plans/_baselines
  {
    echo "=== batch cold init, 5 runs ==="
    for i in 1 2 3 4 5; do
      /usr/bin/time -p emacs --batch -l ~/.emacs.d/init.el --eval '(kill-emacs)' 2>&1 | grep '^real'
    done
  } > docs/superpowers/plans/_baselines/emacs-redesign-baseline.txt
  cat docs/superpowers/plans/_baselines/emacs-redesign-baseline.txt
  ```
  Expected: 5 lines of `real 1.5–1.9`.

---

## Task 1: Scaffold the new module directory + skeleton dispatcher

**Files:**
- Create: `modules/home/shell/emacs/early-init.el`
- Create: `modules/home/shell/emacs/init.el`
- Create: `modules/home/shell/emacs/lisp/` (directory)
- Create: 11 skeleton files `lisp/config-{perf,ui,evil,completion,ide,git,notes,sessions,term,llm,feeds}.el`

- [ ] **Step 1: Create the directory.**

```bash
mkdir -p modules/home/shell/emacs/lisp
```

- [ ] **Step 2: Write `modules/home/shell/emacs/early-init.el`.**

```elisp
;;; early-init.el --- Early initialization -*- lexical-binding: t; no-byte-compile: t -*-
;;; Commentary:
;; Runs before package.el / GUI / theme. Keep this MINIMAL.
;; Native-AOT and treesit grammars are already wired by the nix wrapper.
;;; Code:

;; --- minimal UI ---
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t
      initial-scratch-message nil
      frame-inhibit-implied-resize t)

;; --- package.el off (nix manages everything) ---
(setq package-enable-at-startup nil
      package-quickstart nil)

;; --- subprocess I/O (eglot, ripgrep) ---
(setq read-process-output-max (* 4 1024 1024))

;; --- GC + file-handler suspension during init ---
(defvar my/file-name-handler-alist-backup file-name-handler-alist)
(setq file-name-handler-alist nil
      gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'after-init-hook
          (lambda ()
            (setq file-name-handler-alist my/file-name-handler-alist-backup
                  gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

;; --- native-comp warnings silent ---
(when (boundp 'native-comp-async-report-warnings-errors)
  (setq native-comp-async-report-warnings-errors 'silent))

;; --- cheap rendering defaults ---
(setq bidi-inhibit-bpa t
      inhibit-compacting-font-caches t
      idle-update-delay 0.5)

;; --- undecorated frames (macOS) ---
(add-to-list 'default-frame-alist '(undecorated . t))

;; --- benchmark-init must load FIRST to capture everything below ---
(require 'benchmark-init)
(add-hook 'after-init-hook #'benchmark-init/deactivate)

(provide 'early-init)
;;; early-init.el ends here
```

- [ ] **Step 3: Write `modules/home/shell/emacs/init.el`.**

```elisp
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
```

- [ ] **Step 4: Write 11 skeleton `lisp/config-*.el` files.**

For each `<name>` in `perf ui evil completion ide git notes sessions term llm feeds`, write `modules/home/shell/emacs/lisp/config-<name>.el` with this template (substituting `<name>` literally in each):

```elisp
;;; config-<name>.el --- placeholder -*- lexical-binding: t; -*-
;;; Code:
(provide 'config-<name>)
;;; config-<name>.el ends here
```

Quick way:

```bash
for n in perf ui evil completion ide git notes sessions term llm feeds; do
  cat > "modules/home/shell/emacs/lisp/config-${n}.el" <<EOF
;;; config-${n}.el --- placeholder -*- lexical-binding: t; -*-
;;; Code:
(provide 'config-${n})
;;; config-${n}.el ends here
EOF
done
```

- [ ] **Step 5: Verify the elisp files parse with `emacs --batch`.**

```bash
emacs --batch \
  -L modules/home/shell/emacs/lisp \
  -l modules/home/shell/emacs/lisp/config-perf.el \
  --eval '(message "ok")'
```

Expected: `ok` on stderr, no errors.

- [ ] **Step 6: Commit.**

```bash
git add modules/home/shell/emacs/
git commit -m "feat(emacs): scaffold new modular emacs config directory

Empty skeletons for early-init.el, init.el (dispatcher), and 11 topical
lisp/config-*.el files. Not yet wired into emacs.nix."
```

---

## Task 2: Wire emacs.nix to use the new files (atomic switchover)

This task swaps `emacs.nix` over to the new structure even though most `config-*.el` files are still skeletons. After this task, rebuilding will load an essentially empty config. That's expected — subsequent tasks fill in the topical files.

**Files:**
- Modify: `modules/home/shell/emacs.nix`

- [ ] **Step 1: Read the file's current state.**

```bash
cat modules/home/shell/emacs.nix
```

You need to replace three regions:
- The `extraPackages = …` list (line ~70 onward)
- The two `home.file."${emacsDir}/early-init.el".source = ./doom/early-init.el;` / `…/init.el".source = ./doom/init.el;` lines (102-103)
- The `home.packages = lib.optionals isDarwin [ emacsClientApp ];` line (121)

- [ ] **Step 2: Replace `extraPackages` list.**

Find:

```nix
    extraPackages = epkgs: [
      epkgs.evil
      epkgs.evil-collection
      epkgs.which-key
      epkgs.general
      epkgs.persistent-scratch

      epkgs.evil-surround         
      epkgs.evil-markdown         
      epkgs.markup         
      epkgs.evil-nerd-commenter  
      epkgs.evil-exchange       
      epkgs.evil-matchit       
      epkgs.evil-args         
      epkgs.evil-easymotion  
      epkgs.avy             
      epkgs.evil-anzu      
      epkgs.undo-fu epkgs.undo-fu-session
      epkgs.deft
      epkgs.persp-mode
      epkgs.minions

      epkgs.vertico
      epkgs.orderless
      epkgs.marginalia
      epkgs.ewal-doom-themes
      epkgs.consult
      epkgs.ripgrep               
      epkgs.project              
    ];
```

Replace with:

```nix
    extraPackages = epkgs: with epkgs; [
      # ---- core completion / minibuffer ----
      vertico orderless marginalia consult

      # ---- evil + leader ----
      evil evil-collection evil-surround general which-key avy

      # ---- editing utilities ----
      undo-fu undo-fu-session tempel

      # ---- ui / theme ----
      doom-themes      # bug fix: init.el (require 'doom-themes) was unmet
      minions

      # ---- languages (py/sh/json/yaml/go ts-modes are built-in to emacs 30) ----
      nix-ts-mode markdown-mode

      # ---- IDE (eglot is built-in; treesit grammars auto-wired by nix) ----

      # ---- one-stop-shop additions ----
      magit vterm gptel elfeed pdf-tools notdeft

      # ---- workspaces / scratch ----
      persp-mode persistent-scratch

      # ---- perf measurement ----
      benchmark-init
    ];
```

- [ ] **Step 3: Replace file-mount lines (102-103).**

Find:

```nix
  home.file."${emacsDir}/early-init.el".source = ./doom/early-init.el;
  home.file."${emacsDir}/init.el".source = ./doom/init.el;
```

Replace with:

```nix
  home.file."${emacsDir}/early-init.el".source = ./emacs/early-init.el;
  home.file."${emacsDir}/init.el".source       = ./emacs/init.el;
  home.file."${emacsDir}/lisp" = {
    source    = ./emacs/lisp;
    recursive = true;
  };
```

- [ ] **Step 4: Replace `home.packages` line (121).**

Find:

```nix
  home.packages = lib.optionals isDarwin [ emacsClientApp ];
```

Replace with:

```nix
  home.packages = (lib.optionals isDarwin [ emacsClientApp ]) ++ [
    pkgs.pyright
    pkgs.bash-language-server
    pkgs.gopls
    pkgs.nil
    pkgs.ruff
    pkgs.shfmt
    pkgs.nixfmt-rfc-style
    pkgs.xapian
  ];

  # Daemon-only flow: typing `emacs` in any shell goes through emacsclient.
  # -a '' auto-starts the daemon if not already running. vi/vim left alone.
  home.shellAliases.emacs = "emacsclient -c -a ''";
```

- [ ] **Step 5: Verify the flake still evaluates.**

```bash
nix eval .#darwinConfigurations.mac-personal.config.system.build.toplevel --apply 'x: x.outPath' 2>&1 | tail -5
```

Expected: a single line `"/nix/store/…-darwin-system-…"`. If error, fix the syntax in `emacs.nix` before continuing.

- [ ] **Step 6: Commit.**

```bash
git add modules/home/shell/emacs.nix
git commit -m "feat(emacs): wire emacs.nix to new modular config

Swap extraPackages to Section-3 locked list (drops 7 evil-* + markup +
ewal-doom-themes + deft + anzu + ripgrep; adds doom-themes magit vterm
gptel elfeed pdf-tools notdeft tempel nix-ts-mode markdown-mode
benchmark-init). Mount ./emacs/ tree. Add LSP/formatter binaries and
xapian to home.packages. Add emacs shellAlias to emacsclient."
```

---

## Task 3: Fill `config-perf.el` (persistence + small built-ins)

**Files:**
- Modify: `modules/home/shell/emacs/lisp/config-perf.el`

- [ ] **Step 1: Replace the file with:**

```elisp
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
```

- [ ] **Step 2: Syntax check.**

```bash
emacs --batch -l modules/home/shell/emacs/lisp/config-perf.el --eval '(message "ok")'
```

Expected: `ok`.

- [ ] **Step 3: Commit.**

```bash
git add modules/home/shell/emacs/lisp/config-perf.el
git commit -m "feat(emacs): config-perf — save-place + recentf"
```

---

## Task 4: Fill `config-ui.el` (theme, font, modeline, frame)

**Files:**
- Modify: `modules/home/shell/emacs/lisp/config-ui.el`

- [ ] **Step 1: Replace the file with:**

```elisp
;;; config-ui.el --- Theme, font, modeline, frame, browse-url -*- lexical-binding: t; -*-
;;; Commentary:
;; Theme + font deferred to window-setup-hook so they don't block first paint.
;;; Code:

;; --- Relative line numbers when enabled (vim-style) ---
(setq display-line-numbers-type 'relative)

;; --- Minimal modeline: filled vs hollow dot + buffer name ---
(setq-default
 mode-line-format
 '((:eval
    (concat
     (if (buffer-modified-p)
         (concat
          (propertize "   ● " 'face '(:foreground "#ffffff" :weight bold))
          (propertize "%b"     'face '(:foreground "#ffffff" :weight bold)))
       (concat
        (propertize "   ○ " 'face '(:weight bold))
        (propertize "%b"    'face '(:weight bold))))))))

;; --- Minions: declutter minor-mode lighters ---
(use-package minions
  :defer 1
  :config (minions-mode 1))

;; --- Theme load path (kbwhodat doom-alabaster fetched via nix) ---
(add-to-list 'custom-theme-load-path
             (expand-file-name "themes/doom-alabaster-theme" user-emacs-directory))

;; --- Theme: load after first frame is visible ---
(use-package doom-themes
  :defer t
  :init
  (add-hook 'window-setup-hook
            (lambda () (load-theme 'doom-alabaster t))))

;; --- Font: apply after first frame ---
(add-hook 'window-setup-hook
          (lambda ()
            (set-face-attribute 'default nil
                                :family "ComicShannsMono Nerd Font Mono"
                                :height 135)))

;; --- Browse URL: open in external firefox ---
(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "/etc/profiles/per-user/katob/bin/firefox")

(provide 'config-ui)
;;; config-ui.el ends here
```

- [ ] **Step 2: Syntax check.**

```bash
emacs --batch -l modules/home/shell/emacs/lisp/config-ui.el --eval '(message "ok")'
```

Expected: `ok`.

- [ ] **Step 3: Commit.**

```bash
git add modules/home/shell/emacs/lisp/config-ui.el
git commit -m "feat(emacs): config-ui — theme + font on window-setup-hook, minimal modeline"
```

---

## Task 5: Fill `config-evil.el` (evil + leader + which-key)

**Files:**
- Modify: `modules/home/shell/emacs/lisp/config-evil.el`

- [ ] **Step 1: Replace the file with:**

```elisp
;;; config-evil.el --- Evil + leader + which-key -*- lexical-binding: t; -*-
;;; Commentary:
;; evil-collection deferred 0.5s idle (keymaps for ~100 modes).
;; which-key delay tightened from 1.0s to 0.3s.
;;; Code:

;; --- Must be set BEFORE evil loads ---
(setq evil-want-C-u-scroll t
      evil-want-C-i-jump t
      evil-want-keybinding nil)

(use-package evil
  :init
  (setq evil-undo-system 'undo-fu
        evil-normal-state-cursor '(box . 1)
        evil-insert-state-cursor '(bar . 1)
        evil-visual-state-cursor '(hollow . 1))
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config
  (run-with-idle-timer
   0.5 nil
   (lambda () (evil-collection-init))))

(use-package evil-surround
  :after evil
  :config (global-evil-surround-mode 1))

(use-package undo-fu :after evil)
(use-package undo-fu-session
  :after undo-fu
  :config (global-undo-fu-session-mode 1))

(use-package which-key
  :config
  (setq which-key-idle-delay 0.3)
  (which-key-mode 1))

(use-package general
  :config
  (general-create-definer my/leader
    :states '(normal visual motion)
    :keymaps 'override
    :prefix "SPC" :non-normal-prefix "M-SPC")

  ;; --- windmove leaves (preserved from user's existing setup) ---
  (my/leader
    "h" '(windmove-left  :which-key "← window")
    "j" '(windmove-down  :which-key "↓ window")
    "k" '(windmove-up    :which-key "↑ window")
    "l" '(windmove-right :which-key "→ window"))

  ;; --- buffers / quit / nav ---
  (my/leader
    "b"  '(:ignore t :which-key "buffers")
    "bb" '(switch-to-buffer    :which-key "switch")
    "bd" '(kill-this-buffer    :which-key "kill")
    "d"  '(kill-current-buffer :which-key "kill current")
    ";"  '(previous-buffer     :which-key "prev buffer")
    "'"  '(next-buffer         :which-key "next buffer")
    "q"  '(save-buffers-kill-terminal :which-key "quit"))

  ;; --- windows ---
  (my/leader
    "w"  '(:ignore t :which-key "windows")
    "wv" '(split-window-right :which-key "vsplit")
    "ws" '(split-window-below :which-key "hsplit")
    "wd" '(delete-window      :which-key "close"))

  ;; --- help under SPC h (in addition to windmove leaf) ---
  (my/leader
    "h k" '(describe-key      :which-key "describe key")
    "h f" '(describe-function :which-key "describe func")
    "h v" '(describe-variable :which-key "describe var")
    "h m" '(describe-mode     :which-key "describe mode")
    "h b" '(benchmark-init/show-durations-tabulated :which-key "bench report"))

  ;; --- toggles ---
  (my/leader
    "t"  '(:ignore t :which-key "toggle")
    "tl" '(display-line-numbers-mode :which-key "line numbers")
    "tw" '(visual-line-mode          :which-key "wrap")))

;; --- Avy (deferred until first SPC j sub-binding) ---
(use-package avy
  :defer t
  :commands (avy-goto-word-1 avy-goto-line avy-goto-char-timer)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "j w" '(avy-goto-word-1     :which-key "word")
        "j l" '(avy-goto-line       :which-key "line")
        "j c" '(avy-goto-char-timer :which-key "char")))))

(provide 'config-evil)
;;; config-evil.el ends here
```

- [ ] **Step 2: Syntax check.**

```bash
emacs --batch -l modules/home/shell/emacs/lisp/config-evil.el --eval '(message "ok")'
```

Expected: `ok`.

- [ ] **Step 3: Commit.**

```bash
git add modules/home/shell/emacs/lisp/config-evil.el
git commit -m "feat(emacs): config-evil — evil + collection + general SPC leader + which-key 0.3s"
```

---

## Task 6: Fill `config-completion.el` (vertico + consult + savehist)

**Files:**
- Modify: `modules/home/shell/emacs/lisp/config-completion.el`

- [ ] **Step 1: Replace the file with:**

```elisp
;;; config-completion.el --- Minibuffer completion stack -*- lexical-binding: t; -*-
;;; Commentary:
;; Vertico+orderless+marginalia eager (used at first M-x/find-file).
;; Consult deferred.  History length bumped from default 100 to 1000.
;;; Code:

(use-package savehist
  :init (setq history-length 1000)
  :config (savehist-mode 1))

(use-package vertico
  :config (vertico-mode 1))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides
        '((file (styles basic partial-completion)))))

(use-package marginalia
  :config (marginalia-mode 1))

(use-package consult
  :defer t
  :commands (consult-line consult-ripgrep consult-buffer consult-project-buffer)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "s"  '(:ignore t :which-key "search")
        "ss" '(consult-line     :which-key "in-buffer")
        "sg" '(consult-ripgrep  :which-key "ripgrep")
        "sb" '(consult-buffer   :which-key "buffers"))
      (with-eval-after-load 'project
        (my/leader
          "p"  '(:ignore t :which-key "project")
          "pp" '(project-switch-project :which-key "switch")
          "pf" '(project-find-file      :which-key "find file")
          "pb" '(consult-project-buffer :which-key "buffers")
          "ps" '(consult-ripgrep        :which-key "ripgrep")))
      (my/leader
        "f"  '(:ignore t :which-key "files")
        "ff" '(find-file   :which-key "find file")
        "fs" '(save-buffer :which-key "save")
        "fr" '(recentf     :which-key "recent")
        "fd" '(dired       :which-key "dired")))))

(provide 'config-completion)
;;; config-completion.el ends here
```

- [ ] **Step 2: Syntax check.**

```bash
emacs --batch -l modules/home/shell/emacs/lisp/config-completion.el --eval '(message "ok")'
```

Expected: `ok`.

- [ ] **Step 3: Commit.**

```bash
git add modules/home/shell/emacs/lisp/config-completion.el
git commit -m "feat(emacs): config-completion — vertico+orderless+marginalia eager, consult deferred"
```

---

## Task 7: Fill `config-ide.el` (tree-sitter mapping, eglot, tempel)

**Files:**
- Modify: `modules/home/shell/emacs/lisp/config-ide.el`

- [ ] **Step 1: Replace the file with:**

```elisp
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

(provide 'config-ide)
;;; config-ide.el ends here
```

- [ ] **Step 2: Syntax check.**

```bash
emacs --batch -l modules/home/shell/emacs/lisp/config-ide.el --eval '(message "ok")'
```

Expected: `ok`.

- [ ] **Step 3: Commit.**

```bash
git add modules/home/shell/emacs/lisp/config-ide.el
git commit -m "feat(emacs): config-ide — ts-mode remap + eglot per lang + tempel"
```

---

## Task 8: Fill `config-git.el` (magit, deferred)

**Files:**
- Modify: `modules/home/shell/emacs/lisp/config-git.el`

- [ ] **Step 1: Replace the file with:**

```elisp
;;; config-git.el --- Magit (deferred until first SPC g) -*- lexical-binding: t; -*-
;;; Code:

(use-package magit
  :defer t
  :commands (magit-status magit-dispatch magit-file-dispatch
             magit-blame magit-log-buffer-file)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "g"  '(:ignore t :which-key "git")
        "gs" '(magit-status           :which-key "status")
        "gd" '(magit-dispatch         :which-key "dispatch")
        "gf" '(magit-file-dispatch    :which-key "file dispatch")
        "gb" '(magit-blame            :which-key "blame")
        "gl" '(magit-log-buffer-file  :which-key "log")))))

(provide 'config-git)
;;; config-git.el ends here
```

- [ ] **Step 2: Syntax check.**

```bash
emacs --batch -l modules/home/shell/emacs/lisp/config-git.el --eval '(message "ok")'
```

Expected: `ok`.

- [ ] **Step 3: Commit.**

```bash
git add modules/home/shell/emacs/lisp/config-git.el
git commit -m "feat(emacs): config-git — magit deferred under SPC g"
```

---

## Task 9: Fill `config-notes.el` (markdown, notdeft, scratch)

**Files:**
- Modify: `modules/home/shell/emacs/lisp/config-notes.el`

- [ ] **Step 1: Replace the file with:**

```elisp
;;; config-notes.el --- Markdown + notdeft + persistent-scratch -*- lexical-binding: t; -*-
;;; Commentary:
;; Markdown face tweaks copied verbatim from prior init.el:196-226.
;;; Code:

(use-package markdown-mode
  :mode "\\.md\\'"
  :config
  ;; --- behavior / tweaks ---
  (setq markdown-fontify-code-blocks-natively nil
        markdown-hide-markup nil
        markdown-list-item-bullets (make-list 6 "-")
        markdown-header-scaling nil)

  ;; --- faces (vanilla replacement for Doom's custom-set-faces!) ---
  (custom-theme-set-faces
   'user
   '(markdown-bold-face             ((t (:inherit default :weight bold :foreground unspecified))))
   '(markdown-italic-face           ((t (:inherit default :slant italic :foreground unspecified))))
   '(markdown-header-face           ((t (:inherit default :weight bold :height 1.35))))
   '(markdown-header-face-1         ((t (:inherit default :weight bold :height 1.25))))
   '(markdown-header-face-2         ((t (:inherit default :weight bold :height 1.15))))
   '(markdown-header-face-3         ((t (:inherit default :weight bold :height 1.10))))
   '(markdown-header-face-4         ((t (:inherit default :weight bold :height 1.05))))
   '(markdown-code-face             ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-inline-code-face      ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-language-keyword-face ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-metadata-key-face     ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-line-break-face       ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-blockquote-face       ((t (:inherit default))))
   '(markdown-header-delimiter-face ((t (:inherit default :weight bold :foreground unspecified :background unspecified))))
   '(markdown-markup-face           ((t (:inherit default))))
   '(hl-line                        ((t (:inherit default :foreground unspecified :background unspecified))))))

;; --- Markdown buffer cleanup ---
(add-hook 'markdown-mode-hook (lambda () (flyspell-mode -1)))
(with-eval-after-load 'eldoc
  (add-hook 'markdown-mode-hook (lambda () (eldoc-mode -1))))

;; --- gx / gX follow markdown link under cursor (evil normal) ---
(with-eval-after-load 'evil
  (evil-define-key 'normal 'global (kbd "g x") #'markdown-follow-link-at-point)
  (evil-define-key 'normal 'global (kbd "g X") #'markdown-follow-link-at-point))

;; --- SPC m toggles markdown markup ---
(with-eval-after-load 'general
  (when (fboundp 'my/leader)
    (my/leader "m" '(markdown-toggle-markup-hiding :which-key "toggle markup"))))

;; --- Custom markdown note functions (preserved from prior init.el) ---
(defun my/markdown-template (title slug)
  "Return default Markdown template using TITLE and SLUG."
  (let ((uid (format "%d-%s"
                     (random (expt 10 10))
                     (substring (md5 (number-to-string (float-time))) 0 4))))
    (format
     "---\nid: %s\naliases:\n  - %s\ntags: []\ndate: %s\nuid: %s\n---\n\n# %s\n\n"
     slug title (format-time-string "%Y-%m-%d") uid title)))

(defun my/new-markdown-note (title)
  "Create a new Markdown note with TITLE in ~/vault."
  (interactive "sNote title: ")
  (let* ((dir  (expand-file-name "~/vault/"))
         (slug (replace-regexp-in-string "[^[:alnum:]-]+" "-" (downcase title)))
         (file (expand-file-name (concat slug ".md") dir))
         (new? (not (file-exists-p file))))
    (unless (file-directory-p dir)
      (make-directory dir t))
    (find-file file)
    (when new?
      (insert (my/markdown-template title slug))
      (save-buffer))))

;; --- Notdeft (Xapian-backed note search; replaces deft) ---
(use-package notdeft
  :defer t
  :commands (notdeft notdeft-filter notdeft-delete-file notdeft-refresh)
  :init
  (setq notdeft-directories '("~/vault")
        notdeft-extension "md"
        notdeft-secondary-extensions '("md"))
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "n"  '(:ignore t :which-key "notes")
        "ns" '(notdeft             :which-key "search")
        "nn" '(my/new-markdown-note :which-key "new note")
        "nf" '(notdeft-filter      :which-key "filter")
        "nd" '(notdeft-delete-file :which-key "delete")
        "nr" '(notdeft-refresh     :which-key "refresh")))))

;; --- Persistent scratch ---
(use-package persistent-scratch
  :hook (after-init . persistent-scratch-autosave-mode)
  :config
  (setq persistent-scratch-save-file
        (expand-file-name "scratch-pad.el" user-emacs-directory))
  (persistent-scratch-setup-default)
  (add-hook 'kill-buffer-query-functions
            (lambda ()
              (if (string= (buffer-name) "*scratch*")
                  (progn
                    (persistent-scratch-save)
                    (bury-buffer)
                    (ignore-errors (delete-window))
                    nil)
                t))))

(defun my/open-persistent-scratch ()
  "Pop to the persistent scratch buffer."
  (interactive) (pop-to-buffer "*scratch*"))

(with-eval-after-load 'general
  (when (fboundp 'my/leader)
    (my/leader "x" '(my/open-persistent-scratch :which-key "scratch"))))

;; --- auto-save-visited explicitly OFF (user choice from prior config) ---
(auto-save-visited-mode -1)

(provide 'config-notes)
;;; config-notes.el ends here
```

- [ ] **Step 2: Syntax check.**

```bash
emacs --batch -l modules/home/shell/emacs/lisp/config-notes.el --eval '(message "ok")'
```

Expected: `ok`.

- [ ] **Step 3: Commit.**

```bash
git add modules/home/shell/emacs/lisp/config-notes.el
git commit -m "feat(emacs): config-notes — markdown + notdeft + persistent-scratch + my/new-markdown-note"
```

---

## Task 10: Fill `config-sessions.el` (persp-mode, no eager restore)

**Files:**
- Modify: `modules/home/shell/emacs/lisp/config-sessions.el`

- [ ] **Step 1: Replace the file with:**

```elisp
;;; config-sessions.el --- Workspaces (persp-mode) -*- lexical-binding: t; -*-
;;; Commentary:
;; THE KEY CHANGE: no eager (persp-load-state-from-file) at startup.
;; Restore is manual via SPC TAB r.  Save still happens on kill-emacs-hook.
;;; Code:

(setq desktop-save-mode -1)

(defconst my/persp-save-dir
  (expand-file-name "persp-sessions/" user-emacs-directory))

(unless (file-directory-p my/persp-save-dir)
  (make-directory my/persp-save-dir t))

(use-package persp-mode
  :defer t
  :commands (persp-mode persp-switch persp-add-buffer persp-frame-switch
             persp-load-state-from-file persp-save-state-to-file
             persp-kill)
  :init
  (setq persp-auto-resume-time -1
        persp-autosave-fname "autosave"
        persp-save-dir my/persp-save-dir
        persp-autosave-default t)
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "TAB"   '(:ignore t :which-key "workspaces")
        "TAB s" '(persp-switch :which-key "switch")
        "TAB n" '(persp-add-new :which-key "new")
        "TAB d" '(persp-kill   :which-key "kill")
        "TAB r" '((lambda () (interactive)
                    (persp-load-state-from-file
                     (expand-file-name persp-autosave-fname persp-save-dir)))
                  :which-key "restore session")
        "TAB w" '((lambda () (interactive)
                    (persp-save-state-to-file
                     (expand-file-name persp-autosave-fname persp-save-dir)))
                  :which-key "save session"))))
  :config
  (persp-mode 1)
  ;; Save on kill-emacs (keep prior behavior) — but DO NOT auto-restore.
  (add-hook 'kill-emacs-hook
            (lambda ()
              (ignore-errors
                (persp-save-state-to-file
                 (expand-file-name persp-autosave-fname persp-save-dir))))))

(provide 'config-sessions)
;;; config-sessions.el ends here
```

- [ ] **Step 2: Syntax check.**

```bash
emacs --batch -l modules/home/shell/emacs/lisp/config-sessions.el --eval '(message "ok")'
```

Expected: `ok`.

- [ ] **Step 3: Commit.**

```bash
git add modules/home/shell/emacs/lisp/config-sessions.el
git commit -m "feat(emacs): config-sessions — persp-mode deferred, no eager session restore"
```

---

## Task 11: Fill `config-term.el` (vterm)

**Files:**
- Modify: `modules/home/shell/emacs/lisp/config-term.el`

- [ ] **Step 1: Replace the file with:**

```elisp
;;; config-term.el --- Terminal (vterm) -*- lexical-binding: t; -*-
;;; Code:

(use-package vterm
  :defer t
  :commands (vterm vterm-other-window)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "o"  '(:ignore t :which-key "open")
        "ot" '(vterm   :which-key "vterm")
        "oe" '(eshell  :which-key "eshell")))))

(provide 'config-term)
;;; config-term.el ends here
```

- [ ] **Step 2: Syntax check.**

```bash
emacs --batch -l modules/home/shell/emacs/lisp/config-term.el --eval '(message "ok")'
```

Expected: `ok`.

- [ ] **Step 3: Commit.**

```bash
git add modules/home/shell/emacs/lisp/config-term.el
git commit -m "feat(emacs): config-term — vterm deferred under SPC o t"
```

---

## Task 12: Fill `config-llm.el` (gptel)

**Files:**
- Modify: `modules/home/shell/emacs/lisp/config-llm.el`

- [ ] **Step 1: Replace the file with:**

```elisp
;;; config-llm.el --- LLM chat (gptel) -*- lexical-binding: t; -*-
;;; Commentary:
;; Provider API keys come from environment variables set in shell, not here.
;;; Code:

(use-package gptel
  :defer t
  :commands (gptel gptel-send gptel-menu)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "l l" '(gptel      :which-key "chat")
        "l s" '(gptel-send :which-key "send")
        "l m" '(gptel-menu :which-key "menu")))))

(provide 'config-llm)
;;; config-llm.el ends here
```

- [ ] **Step 2: Syntax check.**

```bash
emacs --batch -l modules/home/shell/emacs/lisp/config-llm.el --eval '(message "ok")'
```

Expected: `ok`.

- [ ] **Step 3: Commit.**

```bash
git add modules/home/shell/emacs/lisp/config-llm.el
git commit -m "feat(emacs): config-llm — gptel deferred under SPC l"
```

---

## Task 13: Fill `config-feeds.el` (elfeed + pdf-tools)

**Files:**
- Modify: `modules/home/shell/emacs/lisp/config-feeds.el`

- [ ] **Step 1: Replace the file with:**

```elisp
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
```

- [ ] **Step 2: Syntax check.**

```bash
emacs --batch -l modules/home/shell/emacs/lisp/config-feeds.el --eval '(message "ok")'
```

Expected: `ok`.

- [ ] **Step 3: Commit.**

```bash
git add modules/home/shell/emacs/lisp/config-feeds.el
git commit -m "feat(emacs): config-feeds — elfeed + pdf-tools deferred"
```

---

## Task 14: Write the bench script with fail criteria

**Files:**
- Create: `scripts/emacs-bench.sh`

- [ ] **Step 1: Confirm scripts/ directory.**

```bash
mkdir -p scripts
```

- [ ] **Step 2: Write `scripts/emacs-bench.sh`.**

```bash
#!/usr/bin/env bash
# emacs-bench.sh — measure emacs startup against spec budget.
# Exits non-zero if any target is missed.
#
# Targets (from docs/superpowers/specs/2026-05-13-emacs-redesign-design.md §7.1):
#   batch cold init     ≤ 0.35 s
#   GUI cold init       ≤ 1.5 s
#   emacsclient -c warm ≤ 0.10 s

set -u
EMACS=$(command -v emacs)
EMACSCLIENT=$(command -v emacsclient)

if [ -z "$EMACS" ] || [ -z "$EMACSCLIENT" ]; then
  echo "FAIL: emacs or emacsclient not on PATH" >&2
  exit 2
fi

median () { sort -n | awk 'BEGIN{c=0} {a[c++]=$0} END{print a[int(c/2)]}'; }

target_batch=0.35
target_gui=1.50
target_warm=0.10

fail=0
check () {  # check <label> <observed> <target>
  local label=$1 obs=$2 tgt=$3
  awk -v o="$obs" -v t="$tgt" -v lbl="$label" 'BEGIN {
    if (o+0 <= t+0) {
      printf "PASS  %-30s %.3fs (≤ %.3fs)\n", lbl, o, t
      exit 0
    } else {
      printf "FAIL  %-30s %.3fs (> %.3fs)\n", lbl, o, t
      exit 1
    }
  }' || fail=1
}

echo "=== Batch cold init (5 runs, median) ==="
batch_median=$(
  for i in 1 2 3 4 5; do
    /usr/bin/time -p "$EMACS" --batch -l ~/.emacs.d/init.el --eval '(kill-emacs)' 2>&1 \
      | awk '/^real/{print $2}'
  done | median
)
check "batch cold init" "$batch_median" "$target_batch"

echo
echo "=== GUI cold init (1 run, frame will flicker) ==="
gui_real=$(
  /usr/bin/time -p "$EMACS" -l ~/.emacs.d/init.el --eval '(kill-emacs)' 2>&1 \
    | awk '/^real/{print $2}'
)
check "GUI cold init" "$gui_real" "$target_gui"

echo
echo "=== emacsclient -c warm frame (5 runs, median) ==="
if "$EMACSCLIENT" -e 't' >/dev/null 2>&1; then
  warm_median=$(
    for i in 1 2 3 4 5; do
      /usr/bin/time -p "$EMACSCLIENT" -c -e '(delete-frame)' 2>&1 \
        | awk '/^real/{print $2}'
    done | median
  )
  check "emacsclient warm frame" "$warm_median" "$target_warm"
else
  echo "SKIP  emacsclient warm frame (daemon not running)"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "ALL TARGETS MET"
  exit 0
else
  echo "ONE OR MORE TARGETS MISSED"
  exit 1
fi
```

- [ ] **Step 3: Make it executable.**

```bash
chmod +x scripts/emacs-bench.sh
```

- [ ] **Step 4: Commit.**

```bash
git add scripts/emacs-bench.sh
git commit -m "feat(scripts): emacs-bench.sh measures cold/GUI/warm vs spec budget"
```

---

## Task 15: Eval-check the flake before rebuilding

- [ ] **Step 1: Eval mac-personal (primary target).**

```bash
nix eval .#darwinConfigurations.mac-personal.config.system.build.toplevel --apply 'x: x.outPath' 2>&1 | tail -3
```

Expected: a `"/nix/store/…-darwin-system-…"` line, no error. If error, read the message — the most-likely cause is a typo in `emacs.nix` from Task 2. Fix and re-eval before continuing.

- [ ] **Step 2: Eval other darwin hosts.**

```bash
for h in mac-studio macbook-neo mac-work; do
  printf "=== %-15s " "$h"
  nix eval ".#darwinConfigurations.${h}.config.system.build.toplevel" --apply 'x: x.outPath' 2>&1 | tail -1
done
```

Expected: all 3 print a `/nix/store/…-darwin-system-…` line.

- [ ] **Step 3: Eval nixos hosts (eval only, no rebuild — out of scope per spec §13).**

```bash
for h in util frame13 server main; do
  printf "=== %-10s " "$h"
  nix eval ".#nixosConfigurations.${h}.config.system.build.toplevel" --apply 'x: x.outPath' 2>&1 | tail -1
done
```

Expected: all 4 print a `/nix/store/…-nixos-system-…` line.

---

## Task 16: Build the new darwin configuration without applying

- [ ] **Step 1: `darwin-rebuild build` (no switch).**

```bash
darwin-rebuild build --flake .#mac-personal 2>&1 | tail -20
```

Expected: ends with a derivation path symlinked to `result`. No errors.

---

## Task 17: Apply the configuration and restart the daemon

⚠️ This task takes your live emacs daemon down for ~5 seconds while it reloads. Save any unsaved work in current frames first.

- [ ] **Step 1: Save current emacs state from your live frame.**

In emacs: `C-x s` (save all buffers).

- [ ] **Step 2: `darwin-rebuild switch`.**

```bash
darwin-rebuild switch --flake .#mac-personal 2>&1 | tail -15
```

Expected: ends with `activating reloadDaemon …` or similar. Daemon restarts automatically.

- [ ] **Step 3: Verify the daemon is up.**

```bash
emacsclient -e t
```

Expected: `t`. If daemon isn't up, start it:

```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nix-community.home.emacs.plist || true
emacsclient -e t
```

- [ ] **Step 4: Verify `init.el` is the new file.**

```bash
readlink ~/.emacs.d/init.el
```

Expected: a `/nix/store/…/emacs/init.el` path containing `emacs/init.el` (not `doom/init.el`).

---

## Task 18: Run the bench and confirm targets

- [ ] **Step 1: Run the bench.**

```bash
./scripts/emacs-bench.sh
```

Expected: 3 `PASS` lines and `ALL TARGETS MET`.

If any line is `FAIL`:
- **batch cold init > 0.35s** — open `~/.emacs.d/init.el`, hunt for accidentally-eager requires. Use `SPC h b` (`benchmark-init/show-durations-tabulated`) inside emacs to identify the offender.
- **GUI cold init > 1.5s** — same diagnostic. Likely culprit: a missing `:defer t` on one of the `use-package` blocks, or `evil-collection-init` accidentally running synchronously.
- **emacsclient warm > 0.10s** — check `frame-inhibit-implied-resize` survived; check no `after-make-frame-functions` hook is doing heavy work.

If a fail blocks progress: `git revert HEAD~N..HEAD` (where N is the count of new commits) and `darwin-rebuild switch --flake .#mac-personal` to restore prior state.

- [ ] **Step 2: Save the bench output for the record.**

```bash
./scripts/emacs-bench.sh > docs/superpowers/plans/_baselines/emacs-redesign-after.txt 2>&1
cat docs/superpowers/plans/_baselines/emacs-redesign-after.txt
```

---

## Task 19: Eyes-on smoke test

⚠️ Manual. Open a new emacs frame and check each of the items below. None can be automated.

- [ ] **Step 1: Open a fresh frame.**

```bash
emacsclient -c &
```

A new emacs frame appears.

- [ ] **Step 2: Smoke checks (each line is one observation).**

| Check | Action | Expected |
|---|---|---|
| Evil works | Press `i`, type "hello", `<Esc>` | Insert mode and normal mode toggle correctly |
| Theme loaded | Look at the frame | Doom-alabaster colors visible |
| Modeline minimal | Look at modeline | Hollow/filled dot + buffer name only |
| `SPC s g` consult-ripgrep | Press `SPC s g`, type a regex | Project-wide rg search opens vertico results |
| `SPC g s` magit | Press `SPC g s` (inside a git repo) | Magit status buffer appears |
| `SPC o t` vterm | Press `SPC o t` | A vterm buffer opens with a shell |
| `SPC l l` gptel | Press `SPC l l` | gptel-mode buffer appears (may need API key) |
| `SPC TAB s` persp | Press `SPC TAB s` | persp-switch prompt appears in minibuffer |
| `SPC n s` notdeft | Press `SPC n s` | notdeft buffer with vault contents appears |
| `SPC h b` bench | Press `SPC h b` | benchmark-init tabulated report opens; no row > 80ms |

- [ ] **Step 3: Note any failures, decide blocking vs. follow-up.**

If a smoke-test row fails, capture the failure mode in a comment in the commit message for Task 20. Failures that block daily workflow → revert. Failures that don't block → file as follow-up in the spec's Open Decisions section.

---

## Task 20: Delete the legacy `doom/` directory

After Task 18's bench passes and Task 19's smoke tests succeed.

**Files:**
- Delete: `modules/home/shell/doom/config.el`
- Delete: `modules/home/shell/doom/early-init.el`
- Delete: `modules/home/shell/doom/init.el`
- Delete: `modules/home/shell/doom/init.el-doom`
- Delete: `modules/home/shell/doom/packages.el`
- Delete: `modules/home/shell/doom/` (the now-empty dir)

- [ ] **Step 1: Verify the old paths are referenced nowhere.**

```bash
grep -rn "shell/doom\|./doom/" modules/ flake.nix 2>&1 | grep -v "^Binary file"
```

Expected: no output. The references in `emacs.nix:102-103` should already point at `./emacs/...` after Task 2.

- [ ] **Step 2: Remove the files and the directory.**

```bash
git rm modules/home/shell/doom/config.el \
       modules/home/shell/doom/early-init.el \
       modules/home/shell/doom/init.el \
       modules/home/shell/doom/init.el-doom \
       modules/home/shell/doom/packages.el
rmdir modules/home/shell/doom
```

- [ ] **Step 3: Eval to confirm nothing references the removed files.**

```bash
nix eval .#darwinConfigurations.mac-personal.config.system.build.toplevel --apply 'x: x.outPath' 2>&1 | tail -3
```

Expected: same store path or a new one, no error.

- [ ] **Step 4: Commit.**

```bash
git commit -m "chore(emacs): remove legacy doom/ directory

Replaced by modules/home/shell/emacs/.  The doom/ files were Doom-Emacs
artifacts kept after the migration off Doom; they are no longer sourced."
```

---

## Task 21: Final sanity sweep

- [ ] **Step 1: Confirm bench-after numbers persist after the deletion.**

```bash
./scripts/emacs-bench.sh
```

Expected: same numbers as Task 18, `ALL TARGETS MET`.

- [ ] **Step 2: Confirm all 8 hosts still eval clean.**

```bash
for h in mac-personal mac-studio macbook-neo mac-work; do
  printf "darwin %-15s " "$h"
  nix eval ".#darwinConfigurations.${h}.config.system.build.toplevel" --apply 'x: x.outPath' 2>&1 | tail -1
done
for h in util frame13 server main; do
  printf "nixos  %-10s " "$h"
  nix eval ".#nixosConfigurations.${h}.config.system.build.toplevel" --apply 'x: x.outPath' 2>&1 | tail -1
done
```

Expected: every line ends with a `/nix/store/…` path.

- [ ] **Step 3: Tag the migration commit for easy rollback.**

```bash
git tag emacs-redesign-applied
```

- [ ] **Step 4: No final commit. The migration is the body of work; it is itself the unit of revert if needed.**

---

## Rollback (for reference, only if needed)

If at any point after Task 17 the new setup blocks daily work:

```bash
git revert <commit-range>
darwin-rebuild switch --flake .#mac-personal
emacsclient -e '(kill-emacs)'
emacsclient -c &
```

The nix store still has the previous emacs derivation cached, so rollback is sub-second to apply.

---

## Spec-coverage self-check

| Spec section | Implemented in |
|---|---|
| §6.1 daemon-only model | Tasks 2 (shellAliases), 17 (rebuild) |
| §6.2 file layout | Task 1 |
| §6.3 extraPackages | Task 2 |
| §6.3 file mounts | Task 2 |
| §6.3 home.packages (LSP binaries + xapian) | Task 2 |
| §7.1 perf targets | Task 14 (encoded in bench), Task 18 (verified) |
| §7.2 tactics | Tasks 1, 3–13 |
| §7.3 verification harness | Task 14 |
| §8.1 drop list | Task 2 |
| §8.2 add list | Task 2 |
| §8.3 eager / deferred ordering | Tasks 3–13 |
| §9 keybindings (verbatim) | Tasks 5, 6, 8, 9, 10, 11, 12, 13 |
| §10.1 ts-mode mapping | Task 7 |
| §10.2 eglot per language | Task 7 (LSP = nil per locked decision) |
| §10.3 formatters | Out of scope — see Gaps note below |
| §10.4 tempel | Task 7 |
| §10.5 markdown faces (verbatim) | Task 9 |
| §10.6 notdeft (close-on-open skipped) | Task 9 |
| §10.7 persp-mode no eager restore | Task 10 |
| §11.1 theme on window-setup-hook | Task 4 |
| §11.2 font on window-setup-hook | Task 4 |
| §11.3 minimal modeline | Task 4 |
| §11.4 frame defaults | Task 1 (early-init.el) + Task 4 (config-ui) |
| §11.5 buffer hygiene | Task 1 (init.el dispatcher only has after-init form) |
| §11.6 browse-url firefox | Task 4 |
| §12.1 create | Tasks 1, 3–13 |
| §12.2 modify | Task 2 |
| §12.3 delete | Task 20 |
| §12.4 user-data disposition | No code action — Task 17 swap doesn't touch user data |
| §12.5 verification gates | Tasks 15–19 |
| §12.6 rollback | "Rollback" section above |
| §14 open decisions | All locked at plan-write time per agent prompt |

**Gaps:** §10.3 non-LSP formatter wrappers (ruff format for python, shfmt for bash, nixfmt-rfc-style for nix) are not in this plan — eglot handles formatting via the LSP server where supported, but pyright doesn't format. File as a follow-up in spec §14 if you want explicit `before-save-hook` wiring per language; not in scope here.
