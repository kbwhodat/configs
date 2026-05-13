# Emacs Redesign — Design Spec

**Date:** 2026-05-13
**Author:** katob (with Claude assist)
**Status:** Draft (awaiting user review)
**Target hosts:** `mac-personal`, `mac-studio`, `macbook-neo`, `mac-work` (darwin); secondary: `frame13`, `util`, `server`, `main` (nixos)

---

## 1. Goal

Replace the current Emacs configuration with a declarative, lazy-loaded, daemon-only setup that hits a measured cold-start under 1.5 s on a slow machine while remaining a one-stop-shop development environment (git, LSP, terminal, notes, RSS, PDF, LLM chat).

## 2. Context — observed state of the current setup

- Emacs version: `30.2` (verified: `nix eval` of `pkgs.emacs.version`)
- `pkgs.emacs.NATIVE_FULL_AOT = "1"` — native AOT compilation enabled at build time (verified: `nix eval`)
- `treesit-available-p` returns `t`; built-in ts-modes (`python-ts-mode`, `bash-ts-mode`, `go-ts-mode`, `json-ts-mode`, `yaml-ts-mode`) all `fboundp` (verified by running `emacs --batch`)
- `eglot` loaded from `/nix/store/.../emacs-30.2/share/emacs/30.2/lisp/progmodes/eglot.elc` (built-in, verified by `emacs --batch`)
- `treesit-extra-load-path` already points at `…-emacs-packages-deps/lib/` — nix wrapper auto-wires grammars
- Daemon mode enabled at `modules/home/shell/emacs.nix:114-118` (`services.emacs.enable = true`, `client.enable = true`)
- Current `~/.emacs.d/init.el` is 388 lines, source-mounted via `home.file."${emacsDir}/init.el".source = ./doom/init.el;` at `emacs.nix:103`
- `modules/home/shell/doom/` contains: `config.el` (7.7K, legacy Doom), `early-init.el` (1.4K), `init.el` (14.5K, active), `init.el-doom` (2.0K, museum-piece doom! macro), `packages.el` (552B, legacy Doom)
- Theme `doom-alabaster-theme.el` declares `Package-Requires: ((emacs "25.1") (doom-themes "2.3.0"))` — depends on upstream `doom-themes`, not `ewal-doom-themes`
- Current `extraPackages` includes `doom-themes` requirement violated: only `ewal-doom-themes` is installed; `init.el:17` `(require 'doom-themes)` silently fails. Fix in this design.

## 3. Measured baseline

| Scenario | Observed |
|---|---|
| `emacs -Q --batch` (vanilla floor) | 0.20 s wall |
| `emacs --batch -l init.el` (init only, no GUI) | 1.55–1.87 s wall |
| `emacs -l init.el --eval '(kill-emacs)'` (GUI cold) | 53 s first run, 16 s warm; ~9.59 GB peak RSS (user observation) |
| Background `time -l emacs -l init.el ...` from non-GUI shell | 275 s hung waiting for display, **~212 MB peak RSS** without GUI |
| Daemon emacsclient round-trip | 10–20 ms |

Diagnosis: persp-mode at `init.el:247-250` calls `(persp-load-state-from-file …)` eagerly at startup against an autosave file referencing 19 vault markdown buffers. ~15 eager `(require …)` calls in init.el. Theme/font set synchronously in init.el. GUI multiplier (Cocoa frame, font, theme face attributes on 19 buffers) accounts for the 53 s and 9.59 GB.

## 4. Constraints

In priority order, per user:

1. **Performance — top priority.** Goated startup, especially on slow work machine.
2. **Vim keybindings** (evil) — required.
3. **Not bloatware** — explicit drop-list.
4. **One-stop-shop** — OK so long as constraint #1 holds.
5. **Inspiration:** Jane Street public emacs practices (heavy magit, vanilla idioms, ~67% engineers use emacs).
6. **Language stack:** Nix, Bash, Python, Go, Markdown (heavy), elisp (config). No org-mode. No OCaml.

## 5. Approach

**Approach B — clean redesign, declarative, measured.**

Other approaches considered and rejected:
- **A. Tune current init.el in place.** Rejected: 388-line single file with ~15 eager requires + eager session restore is the structural problem.
- **C. Steal Doom's lazy-load patterns without the framework.** Rejected: `use-package` (built into emacs 30) provides the same lazy-load primitives with less hand-rolled code.

## 6. Architecture

### 6.1 Process model — daemon-only

- One persistent `emacs --daemon` started at login by the existing launchd/systemd user service (`services.emacs.enable = true` in `emacs.nix`).
- All interactive frames are `emacsclient -c -a ''`. The `-a ''` auto-starts the daemon if not running.
- `EmacsClient.app` wrapper at `emacs.nix:12-63` already routes Spotlight/Raycast invocations through the client. Keep unchanged.
- **Open decision:** add `home.shellAliases.emacs = "emacsclient -c -a ''"` (and optionally `vi`/`vim`). User parked this question; default in spec is `emacs` alias only, `vi`/`vim` left as-is.

### 6.2 File layout

```
modules/home/shell/emacs/
├── early-init.el                # GC, file-handler suspension, frame defaults
├── init.el                      # ≤ 50 lines: (require 'config-*) calls in order
└── lisp/
    ├── config-perf.el           # benchmark-init wiring, gc-after-init, save-place-mode
    ├── config-ui.el             # theme on window-setup-hook, font on window-setup-hook,
    │                            #   minimal modeline, custom-theme-load-path,
    │                            #   display-line-numbers-type 'relative,
    │                            #   browse-url → firefox
    ├── config-evil.el           # evil + evil-collection (idle-deferred 0.5s)
    │                            #   + general SPC leader + which-key (delay 0.3)
    ├── config-completion.el     # vertico, orderless, marginalia, savehist (history-length 1000),
    │                            #   consult :defer + bindings, recentf-mode 1 (max 500)
    ├── config-ide.el            # major-mode-remap-alist for ts-modes,
    │                            #   eglot :hook per language,
    │                            #   eglot-server-programs entries,
    │                            #   tempel :hook (prog-mode)
    ├── config-git.el            # magit :defer :commands
    ├── config-notes.el          # markdown-mode block (faces, hide-markup nil, header-scaling nil),
    │                            #   notdeft :defer + bindings,
    │                            #   my/new-markdown-note, my/markdown-template,
    │                            #   persistent-scratch :hook,
    │                            #   no flyspell/eldoc in markdown
    ├── config-sessions.el       # persp-mode :defer, kill-emacs-hook save,
    │                            #   desktop-save-mode -1, NO eager restore
    ├── config-term.el           # vterm :defer
    ├── config-llm.el            # gptel :defer
    └── config-feeds.el          # elfeed + pdf-tools :defer
```

Every `lisp/config-*.el` ends with `(provide 'config-<name>)` and is required from `init.el` in the order shown.

### 6.3 Nix-side wiring

In `modules/home/shell/emacs.nix`:

1. `extraPackages` (replace existing list):
   ```nix
   extraPackages = epkgs: with epkgs; [
     vertico orderless marginalia consult
     evil evil-collection evil-surround general which-key avy
     undo-fu undo-fu-session tempel
     doom-themes minions
     nix-ts-mode markdown-mode
     magit vterm gptel elfeed pdf-tools notdeft
     persp-mode persistent-scratch
     benchmark-init
   ];
   ```

2. File mounts (replace lines 102–103):
   ```nix
   home.file."${emacsDir}/early-init.el".source = ./emacs/early-init.el;
   home.file."${emacsDir}/init.el".source       = ./emacs/init.el;
   home.file."${emacsDir}/lisp" = {
     source    = ./emacs/lisp;
     recursive = true;
   };
   ```

3. LSP/formatter binaries + xapian (replace line 121):
   ```nix
   home.packages = (lib.optionals isDarwin [ emacsClientApp ]) ++ [
     pkgs.pyright pkgs.bash-language-server pkgs.gopls pkgs.nil
     pkgs.ruff pkgs.shfmt pkgs.nixfmt-rfc-style pkgs.xapian
   ];
   ```

4. Theme mount (line 105) unchanged — `doom-alabaster-theme` from kbwhodat continues to be fetched as-is.

## 7. Performance budget

### 7.1 Targets

| Scenario | Today | Target |
|---|---|---|
| `emacs --batch -l init.el` | 1.6 s | **≤ 0.35 s** |
| `emacs -l init.el` GUI cold | 53 s | **≤ 1.5 s** |
| `emacsclient -c -e '(delete-frame)'` warm | not measured | **≤ 100 ms** |
| Per-package `benchmark-init` entry | n/a (no instrumentation) | **none > 80 ms** |
| Peak RSS post-startup | ~9.59 GB GUI (with persp restore) | **≤ 500 MB** |

### 7.2 Tactics

Already in place (verified):
- GC threshold maxed during init, restored to 64 MB after (`early-init.el:19-28`)
- `file-name-handler-alist` suspended during init, restored after
- `package-enable-at-startup nil`, `package-quickstart nil`
- `read-process-output-max = 4 MB`
- `frame-inhibit-implied-resize t`
- `native-comp-async-report-warnings-errors 'silent`
- `bidi-inhibit-bpa t`, `inhibit-compacting-font-caches t`
- `idle-update-delay 0.5`
- Native-AOT enabled in `pkgs.emacs`

New tactics this design adds:
- Every non-essential package wrapped in `use-package … :defer t :commands … :hook … :after …`
- Theme load on `window-setup-hook` (after first frame paint)
- Font `set-face-attribute` on `window-setup-hook`
- Eager session restore at `init.el:247-250` **removed**; restore becomes manual via `SPC TAB r`
- Eager `kill-buffer "*Messages*"` and `kill-buffer "*scratch*"` at `init.el:24-27` **removed**; keep only the `after-init-hook` form
- `evil-collection-init` keeps idle-defer at 0.5 s (current pattern)
- `which-key-idle-delay 0.3` (from default 1.0)
- `benchmark-init` loaded from `early-init.el` so it captures everything after; report bound to `SPC h b`

### 7.3 Verification harness

Bench script committed to repo (proposed location `nix-config/scripts/emacs-bench.sh`):

```sh
#!/usr/bin/env bash
EMACS=$(command -v emacs)
echo "=== batch cold init (5 runs) ==="
for i in 1 2 3 4 5; do
  /usr/bin/time -p "$EMACS" --batch -l ~/.emacs.d/init.el --eval '(kill-emacs)' 2>&1 | grep '^real'
done
echo "=== GUI cold (1 run, frame will flicker) ==="
/usr/bin/time -l "$EMACS" -l ~/.emacs.d/init.el --eval '(kill-emacs)' 2>&1 | tail -3
echo "=== emacsclient warm (5 runs) ==="
for i in 1 2 3 4 5; do
  /usr/bin/time -p "$EMACS"client -c -e '(delete-frame)' 2>&1 | grep '^real'
done
```

Run before any change, run after, compare. Regressions block merge.

## 8. Package allowlist

### 8.1 Drop list (with reason — all verified)

| Package | Reason |
|---|---|
| `evil-markdown` | User said drop. evil-collection + markdown-mode cover it. |
| `evil-exchange` | User said drop. |
| `evil-matchit` | User said drop. Core evil `%` already jumps parens. |
| `evil-args` | User said drop. |
| `evil-easymotion` | User said drop. `avy` covers jumps. |
| `evil-anzu` | User said drop. Vertico+consult already shows match counts. |
| `evil-nerd-commenter` | User said drop. Replace with 5-line custom `gc` binding. |
| `markup` | Verified: only one `(require 'markup)` at `init.el:261`, no usage. Other `markdown-*-markup` symbols are markdown-mode features. |
| `ewal-doom-themes` | Verified: `doom-alabaster-theme.el` `Package-Requires:` lists `doom-themes`, not `ewal-doom-themes`. |
| `deft` | Replaced by `notdeft` (Xapian-backed). |
| `anzu` (non-evil) | Vertico+consult covers it. |
| `ripgrep` (epkg) | Verified: `consult-ripgrep-args` at `consult.el:303-309` defaults to a shell string invoking system `rg` binary directly. Emacs `ripgrep.el` package unrelated. |

### 8.2 Add list (verified present in pinned nixpkgs)

`doom-themes`, `magit`, `vterm`, `gptel`, `elfeed`, `pdf-tools`, `notdeft`, `tempel`, `nix-ts-mode`, `markdown-mode`, `benchmark-init`

### 8.3 Eager vs deferred

**Eager (loaded at daemon startup, in order):**

1. `early-init.el` body (GC, file-handler, frame defaults, benchmark-init init)
2. `general` (leader macro must exist before any other file uses it)
3. `evil` + `(evil-mode 1)`
4. `which-key` + `(which-key-mode 1)`
5. `vertico-mode`, `marginalia-mode`, `savehist-mode`, `orderless` styles
6. `recentf-mode` (built-in, cheap)
7. `save-place-mode` (built-in, cheap)
8. `evil-collection-init` — idle-deferred 0.5 s (current pattern preserved)
9. Theme load — `window-setup-hook`

**Deferred (everything else):** see Section 6.2 file layout for trigger per package.

## 9. Keybinding scheme

Leader: `SPC` (normal/visual/motion) / `M-SPC` (insert). User preserved `SPC h/j/k/l` as windmove leaves (letter-leaf + same-letter-as-prefix pattern, disambiguated by which-key timeout). Full table:

```
# windmove leaves + prefixes
SPC h         windmove-left      | SPC h k describe-key
                                 | SPC h f describe-function
                                 | SPC h v describe-variable
                                 | SPC h m describe-mode
                                 | SPC h b benchmark-init/show-durations-tabulated
SPC j         windmove-down      | SPC j w avy-goto-word-1
                                 | SPC j l avy-goto-line
                                 | SPC j c avy-goto-char-timer
SPC k         windmove-up
SPC l         windmove-right     | SPC l l gptel
                                 | SPC l s gptel-send
                                 | SPC l m gptel-menu

# preserved (from current init.el)
SPC b b   switch-to-buffer        SPC b d   kill-this-buffer
SPC d     kill-current-buffer
SPC w v   split-window-right      SPC w s   split-window-below
SPC w d   delete-window
SPC q     save-buffers-kill-terminal
SPC ;     previous-buffer         SPC '     next-buffer
SPC x     persistent-scratch      SPC m     markdown-toggle-markup-hiding
SPC s s   consult-line            SPC s g   consult-ripgrep
SPC s b   consult-buffer
SPC p p   project-switch-project  SPC p f   project-find-file
SPC p b   consult-project-buffer  SPC p s   consult-ripgrep (project-scoped)
gx, gX    markdown-follow-link-at-point   (evil normal)

# new
SPC g s   magit-status            SPC g d   magit-dispatch
SPC g f   magit-file-dispatch     SPC g b   magit-blame
SPC g l   magit-log-buffer-file

SPC o t   vterm                   SPC o f   elfeed
SPC o p   find-file (*.pdf)       SPC o e   eshell

SPC TAB s persp-switch            SPC TAB n persp-new
SPC TAB d persp-kill              SPC TAB r persp-load-state-from-file (manual)
SPC TAB w persp-save-state-to-file (manual)

SPC n s   notdeft                 SPC n n   my/new-markdown-note (preserved)
SPC n f   notdeft-filter          SPC n d   notdeft-delete-file
SPC n r   notdeft-refresh

SPC f f   find-file               SPC f s   save-buffer
SPC f r   recentf                 SPC f d   dired

SPC t l   display-line-numbers-mode    SPC t w   visual-line-mode
```

Evil setup (preserved from current init.el):
- `evil-want-C-u-scroll t`, `evil-want-C-i-jump t`, `evil-want-keybinding nil`
- `evil-undo-system 'undo-fu`
- Cursor shapes: normal=box, insert=bar, visual=hollow

## 10. Per-mode integrations

### 10.1 Tree-sitter mode mapping (in `config-ide.el`)

```elisp
(setq major-mode-remap-alist
      '((python-mode . python-ts-mode)
        (bash-mode   . bash-ts-mode)
        (sh-mode     . bash-ts-mode)
        (json-mode   . json-ts-mode)
        (yaml-mode   . yaml-ts-mode)
        (go-mode     . go-ts-mode)))
(add-to-list 'auto-mode-alist '("\\.nix\\'" . nix-ts-mode))
```

Grammars come from nixpkgs `treesit-grammars.with-all-grammars` via `treesit-extra-load-path` (auto-wired by the nix emacs wrapper, verified).

### 10.2 LSP — eglot per language (in `config-ide.el`)

```elisp
(use-package eglot
  :ensure nil  ; built-in
  :hook ((python-ts-mode . eglot-ensure)
         (bash-ts-mode   . eglot-ensure)
         (go-ts-mode     . eglot-ensure)
         (nix-ts-mode    . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs '(python-ts-mode . ("pyright-langserver" "--stdio")))
  (add-to-list 'eglot-server-programs '(bash-ts-mode   . ("bash-language-server" "start")))
  (add-to-list 'eglot-server-programs '(go-ts-mode     . ("gopls")))
  (add-to-list 'eglot-server-programs '(nix-ts-mode    . ("nil"))))
```

Server binaries provided via `home.packages` in `emacs.nix` (Section 6.3).

Nix LSP choice: **`nil`** (lighter, faster) per performance priority. Switch to `nixd` later if feature depth needed — one-symbol change.

### 10.3 Formatters

Per-mode `before-save-hook` calling `eglot-format-buffer` where the server formats, otherwise shell out to the binary. Detail level deferred to writing-plans phase.

| Lang | Formatter |
|---|---|
| Python | `ruff format` via wrapper |
| Bash | `shfmt` |
| Go | gopls built-in |
| Nix | `nixfmt-rfc-style` |
| Markdown | none (optional `prettier`, out of scope) |

### 10.4 Tempel snippets (in `config-ide.el`)

```elisp
(use-package tempel
  :hook ((prog-mode . tempel-abbrev-mode))
  :bind (("M-+" . tempel-complete)
         ("M-*" . tempel-insert)))
```

Templates live at `~/.config/emacs/templates/<mode>.eld`. Empty initially; user adds as they go.

### 10.5 Markdown (in `config-notes.el`)

Copy verbatim from current `init.el:196-226`:
- `markdown-fontify-code-blocks-natively nil`
- `markdown-hide-markup nil`
- `markdown-list-item-bullets (make-list 6 "-")`
- `markdown-header-scaling nil`
- All face customizations under `'user` theme

Add (from doom/config.el):
- `(add-hook 'markdown-mode-hook (lambda () (flyspell-mode -1)))`
- `(with-eval-after-load 'eldoc (add-hook 'markdown-mode-hook (lambda () (eldoc-mode -1))))`

### 10.6 Notdeft (in `config-notes.el`)

```elisp
(use-package notdeft
  :defer t
  :commands (notdeft notdeft-filter notdeft-delete-file notdeft-refresh)
  :config
  (setq notdeft-directories '("~/vault")
        notdeft-extension "md"
        notdeft-secondary-extensions '("md")
        notdeft-xapian-program (executable-find "notdeft-xapian")))
```

Xapian provided via `pkgs.xapian` in `home.packages`. `notdeft-xapian` binary built by the notdeft package itself.

Custom `my/deft-open-and-close` and its keybinding are dropped — notdeft has different semantics; if you want close-on-open, we add a notdeft equivalent. Skipped from initial spec.

### 10.7 Persp-mode (in `config-sessions.el`)

```elisp
(use-package persp-mode
  :defer t
  :commands (persp-switch persp-add-buffer persp-frame-switch
             persp-load-state-from-file persp-save-state-to-file)
  :init
  (setq persp-auto-resume-time -1
        persp-autosave-fname "autosave"
        persp-save-dir (expand-file-name "persp-sessions/" user-emacs-directory)
        persp-autosave-default t)
  :config
  (persp-mode 1)
  (add-hook 'kill-emacs-hook
            (lambda ()
              (ignore-errors
                (persp-save-state-to-file
                 (expand-file-name persp-autosave-fname persp-save-dir))))))
(setq desktop-save-mode -1)
```

**Key change vs today:** no eager `(persp-load-state-from-file …)` at startup. Restore is manual via `SPC TAB r`.

## 11. Theme, font, modeline

### 11.1 Theme (in `config-ui.el`)

```elisp
(add-to-list 'custom-theme-load-path
             (expand-file-name "themes/doom-alabaster-theme" user-emacs-directory))

(use-package doom-themes
  :defer t
  :init
  (add-hook 'window-setup-hook
            (lambda () (load-theme 'doom-alabaster t))))
```

### 11.2 Font (in `config-ui.el`)

```elisp
(add-hook 'window-setup-hook
          (lambda ()
            (set-face-attribute 'default nil
                                :family "ComicShannsMono Nerd Font Mono"
                                :height 135)))
```

Font verified installed system-wide via `pkgs.nerd-fonts.comic-shanns-mono` at `hosts/_shared/darwin-personal-system.nix:149` and `hosts/_shared/darwin-work-system.nix:92`.

### 11.3 Modeline (in `config-ui.el`)

Keep hand-rolled minimal modeline from `init.el:3-15` (filled dot vs hollow dot + buffer name). Plus `(minions-mode 1)`.

### 11.4 Frame defaults

Move from current `early-init.el`/`init.el`:
- `menu-bar-mode -1`, `tool-bar-mode -1`, `scroll-bar-mode -1`
- `inhibit-startup-screen t`, `initial-scratch-message nil`, `frame-inhibit-implied-resize t`
- `(add-to-list 'default-frame-alist '(undecorated . t))`
- `(setq display-line-numbers-type 'relative)` (from doom/config.el)

### 11.5 Buffer hygiene

- Drop the eager `(kill-buffer "*Messages*")` / `(kill-buffer "*scratch*")` at current `init.el:26-27`
- Keep `my-initial-buffer-setup` on `after-init-hook` (current `init.el:30-41`)
- `auto-save-visited-mode -1` stays disabled (user choice)

### 11.6 Browse URL

Preserve current `init.el:266-267`:
```elisp
(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "/etc/profiles/per-user/katob/bin/firefox")
```
(Librewolf reference in legacy doom/config.el ignored.)

## 12. Migration path

Atomic, one-shot, reversible via `git revert`.

### 12.1 Create
- `modules/home/shell/emacs/early-init.el`
- `modules/home/shell/emacs/init.el`
- `modules/home/shell/emacs/lisp/config-{perf,ui,evil,completion,ide,git,notes,sessions,term,llm,feeds}.el` (11 files)

### 12.2 Modify
- `modules/home/shell/emacs.nix` lines 70 (extraPackages), 102-103 (file mounts), 121 (home.packages) per Section 6.3

### 12.3 Delete (after gates pass)
- `modules/home/shell/doom/config.el`
- `modules/home/shell/doom/early-init.el`
- `modules/home/shell/doom/init.el`
- `modules/home/shell/doom/init.el-doom`
- `modules/home/shell/doom/packages.el`
- The now-empty `modules/home/shell/doom/` directory

### 12.4 User-data disposition (in `~/.emacs.d/`)
- `persp-sessions/` — keep; auto-restore disabled; manual via `SPC TAB r`
- `eln-cache/` — keep; emacs repopulates
- `scratch-pad.el` — keep
- `auto-save-list/`, `history` — keep

### 12.5 Verification gates (all must pass)

1. `nix eval .#darwinConfigurations.mac-personal.config.system.build.toplevel --apply 'x: x.outPath'` succeeds
2. `darwin-rebuild build --flake .#mac-personal` succeeds
3. `darwin-rebuild switch --flake .#mac-personal` applies, daemon restarts
4. `time emacs --batch -l ~/.emacs.d/init.el --eval '(kill-emacs)'` ≤ 0.35 s
5. `time emacs -l ~/.emacs.d/init.el --eval '(kill-emacs)'` ≤ 1.5 s
6. `time emacsclient -c -e '(delete-frame)'` ≤ 100 ms
7. `SPC h b` shows no benchmark-init entry > 80 ms
8. Eyes-on smoke test: evil keys in markdown; `SPC s g` consult-ripgrep; `SPC g s` magit; `SPC o t` vterm; `SPC l l` gptel; `SPC TAB s` persp; `SPC n s` notdeft

### 12.6 Rollback

```
git revert <migration commit hash>
darwin-rebuild switch --flake .#mac-personal
```

## 13. Out of scope (deferred to phase 2)

- `pdumper` portable dumper (would target sub-100 ms cold start)
- `emacs-lsp-booster` Rust JSON bridge (only if eglot becomes bottleneck)
- `corfu`/`company` in-buffer completion popups (using built-in `M-TAB` completion-at-point)
- mu4e/notmuch email (user declined)
- org-mode (user declined)
- OCaml + merlin + dune (user not writing OCaml)
- Linux host (NixOS) verification — spec targets darwin first; nixos hosts get the same module but their bench numbers aren't validated in this design

## 14. Open decisions

1. `home.shellAliases` for `emacs` (`emacsclient -c -a ''`) — default yes; user undecided on `vi`/`vim` aliases.
2. Doom-style close-on-open for notdeft (the `my/deft-open-and-close` analogue) — skipped from initial spec; add later if user wants.
3. Spec assumes `nil` over `nixd` for Nix LSP. Swappable in one place.
