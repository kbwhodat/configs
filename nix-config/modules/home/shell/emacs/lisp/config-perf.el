;;; config-perf.el --- Persistence + cheap built-ins + idle preload -*- lexical-binding: t; -*-
;;; Commentary:
;; This file enables built-in modes that are cheap, and pre-loads heavy
;; packages on idle so first-use lag (SPC g s, SPC o t, SPC s g, ...)
;; is paid in the background instead of in front of the user.
;;; Code:

;; Remember cursor position per file
(save-place-mode 1)

;; Recent files — needed for SPC f r binding.
;; 200 is plenty for SPC f r vertico filtering; serialized on every
;; save, so smaller = faster shutdown / less write churn.
(setq recentf-max-saved-items 200)
(recentf-mode 1)

;; --- Underrated redisplay / scroll / completion perf ----------------
;; Sources: jamescherti/minimal-emacs.d, port19.xyz, emacsredux.

;; Skip syntax fontification while the user is typing. Reduces lag in
;; large buffers. Brief inaccuracy self-corrects on idle.
(setq redisplay-skip-fontification-on-input t)

;; Defer fontification 50 ms after every edit.  Complements the above:
;; that one skips during redisplay-vs-input races, this one batches the
;; post-edit refontify so fast typing doesn't refontify on every key.
;; Free win on big buffers; tiny lag in font-lock catching up.
(setq jit-lock-defer-time 0.05)

;; Faster scrolling at the cost of brief font-lock inaccuracy. Same idea.
(setq fast-but-imprecise-scrolling t)

;; Don't recenter when cursor moves past viewport edge. Default 0 is
;; aggressive (always recenter); 20 is balanced; >100 disables.
(setq scroll-conservatively 20)

;; Keep the cursor 8 lines away from the viewport edges.  Pairs with
;; `scroll-conservatively' to eliminate the small "recenter pull" you
;; otherwise feel when typing at the bottom of a buffer — cursor never
;; reaches the very last visible line, so emacs scrolls smoothly
;; instead of jerking to recenter.
(setq scroll-margin 8)

;; M-x: skip commands not applicable to current mode. Big win for
;; M-x completion responsiveness as your package count grows.
(setq read-extended-command-predicate #'command-completion-default-include-p)

;; Instant search-match highlighting (default delay was 0.25s).
(setq lazy-highlight-initial-delay 0)

;; --- MUST-HAVES: so-long, gcmh, vc trim ------------------------------

;; so-long: built-in to emacs 27+. Protects against minified JSON,
;; generated code, grep buffers with huge lines. Without this, opening
;; one bad file can freeze emacs for minutes.
(global-so-long-mode 1)

;; gcmh: high GC threshold during foreground work, GC fires on idle.
;; 64 MiB foreground threshold — was 1 GiB but that hoarded too much
;; RAM on weaker hardware (OS-level swap pressure outweighed the
;; saved GC pauses).  At 64 MiB you'll see a few more GC pauses on
;; very large buffers (minified JSON, big magit-log) but the typing
;; experience is unchanged and the OS keeps its file cache warm.
(use-package gcmh
  :hook (after-init . gcmh-mode)
  :init
  (setq gcmh-idle-delay 'auto
        gcmh-auto-idle-delay-factor 10
        gcmh-high-cons-threshold (* 64 1024 1024)))   ; 64 MiB

;; Restrict VC backends to ones we actually use. Default has 8 entries
;; (RCS CVS SVN SCCS SRC Bzr Git Hg); each costs a stat() per file
;; open as VC sniffs for the backend.  Trim to Git only — jj support
;; (vc-jj package) was dropped; we use majutsu/jj-CLI for jj repos.
(setq vc-handled-backends '(Git))

;; --- Subprocess + LSP/eldoc/flymake latency knobs --------------------
;; These four are the highest-impact remaining input-feel tweaks for an
;; LSP/daemon workflow.  Defaults bias for correctness over latency.

;; Default `t' uses adaptive read buffering on subprocess pipes — adds
;; up to ~2 s of latency on LSP / vterm / magit / ripgrep output before
;; emacs sees it.  Doom flips this off by default.
(setq process-adaptive-read-buffering nil)

;; flymake reruns diagnostics 0.5 s after every change — that triggers
;; an LSP didChange + republish cycle on every keystroke pause.  1 s
;; throttles it to the speed of human typing.
(with-eval-after-load 'flymake
  (setq flymake-no-changes-timeout 1.0))

;; --- TIER 2: smaller quality-of-life wins ---------------------------

;; recentf default polls every 10s to clean dead entries — disable.
(setq recentf-auto-cleanup 'never)

;; auto-revert via filesystem notifications, not polling.
(setq auto-revert-avoid-polling t)

;; Follow symlinks into VC repos without prompting every time.
(setq vc-follow-symlinks t)

;; Default 10 MB threshold for "large file" warning is too low for
;; modern data. 100 MB avoids prompts on logs / json / csv.
(setq large-file-warning-threshold (* 100 1024 1024))

;; --- Crash safety: auto-save only (no per-save backup copies) -------
;; By default emacs writes a `file~' (and optionally numbered
;; `file.~N~') copy on EVERY save — multiply that by buffer-count and
;; you get noticeable disk churn during heavy editing.  We have:
;;   - git for real version control
;;   - undo-fu-session for cross-session undo history
;;   - auto-save-visited-mode (below) for crash safety
;; So per-save backup copies are dead weight.  Disable entirely.
;;
;; auto-save (`.#file' lockfiles + `#file#' progress files) still goes
;; through `auto-save-file-name-transforms' into a dedicated dir so
;; they don't pollute git status / dired listings.
(let ((backup-dir (expand-file-name "backups/" user-emacs-directory)))
  (unless (file-directory-p backup-dir) (make-directory backup-dir t))
  (setq make-backup-files              nil    ; no `file~' copies per save
        backup-directory-alist         `(("." . ,backup-dir))
        auto-save-file-name-transforms `((".*" ,backup-dir t))))

;; auto-save-visited-mode: save the file you're editing every 60s.
;; Pairs with undo-fu-session — worst-case data loss is ~60s.
;; (Was 30 s; bumped because we save every visited modified buffer
;; on each tick — 80 open buffers × every-30-s = a lot of writes.)
(setq auto-save-visited-interval 60)
(auto-save-visited-mode 1)

;; --- winner-mode: undo/redo window layout changes -------------------
;; Bound to `SPC w u' / `SPC w r' in config-evil.el.
(winner-mode 1)

;; --- Tramp tuning for remote editing -------------------------------
;; Open remote files via:  C-x C-f /ssh:HOST:/path
;; Works with magit, dired, vterm, eshell.  Combine with ~/.ssh/config
;; ControlMaster for instant repeat connections.
(with-eval-after-load 'tramp
  (setq tramp-default-method "ssh"               ; faster than scp default
        tramp-verbose 1                          ; less log spam
        tramp-use-ssh-controlmaster-options nil  ; honor ~/.ssh/config
        tramp-completion-reread-directory-timeout nil
        remote-file-name-inhibit-cache nil)      ; aggressive cache
  ;; Don't probe VC backends on remote paths — huge speedup over SSH.
  (setq vc-ignore-dir-regexp
        (format "%s\\|%s" vc-ignore-dir-regexp tramp-file-name-regexp)))

;; --- Idle preload (Doom-style incremental loading) -------------------
;;
;; First time you press SPC g s, emacs has to load magit + transient +
;; magit-section + ~30 sub-files: that's the 5+ s lag.  Same for vterm
;; (libvterm dynamic module) and consult (orderless tree).  Loading
;; them in the background ~2 s after daemon startup, one package every
;; 0.5 s of idle, makes the first interactive press feel instant.

;; NOTE: lsp-mode/lsp-ui are loaded EAGERLY at daemon startup via
;; `:demand t' in config-ide.el (not here — their :init vars must be
;; set before the load).  On the idle preloader they raced the user:
;; "start daemon, open a nix file right away" lost the race and paid
;; the ~0.7s load synchronously at file-open.

(defvar my/idle-preload-packages
  '(consult       ; SPC s g/s/b — usually first thing hit
    ghostel       ; SPC o t     — loads ghostel native module
    ;; LSP clients (trimmed `lsp-client-packages' set in config-ide.el).
    ;; First `(lsp)' per session requires these synchronously inside the
    ;; attach timer; preloading makes even a restored-session's first
    ;; attach pay ~nothing.
    lsp-go lsp-nix lsp-clangd lsp-pyright lsp-ruff
    ;; org: heavy cold require (~0.5-1 s).  Restored org files are lazy
    ;; placeholders now, so org loads on first DISPLAY of one — preload
    ;; moves that one-time cost into true idle instead of first click.
    org)
  "Heavy packages to pre-load on idle so first-use is not laggy.
Order matters — earliest entries get loaded soonest.
Loaded on demand instead (saves RAM and idle CPU):
  - magit + majutsu (jj/git work happens in the CLI; SPC g s / SPC G
    still work, paying a ~2 s load on first press per session instead
    of taxing EVERY session's startup idle + RAM)
  - tempel    (already loaded by `prog-mode' hook in config-ide.el)
  - notdeft   (Xapian native binding — rarely-searched notes)
  - pdf-tools (heavy PDF renderer — loads on .pdf via :mode)")

(defun my/idle-preload-next ()
  "Pop one package off `my/idle-preload-packages' and require it.
Schedules the next pop after another short idle period so heavy
loads spread across idle slices instead of one freeze."
  (when my/idle-preload-packages
    (let ((pkg (pop my/idle-preload-packages)))
      (require pkg nil 'noerror)
      (run-with-idle-timer 0.5 nil #'my/idle-preload-next))))

;; Kick off 2 s after frame paint.  In daemon mode that's roughly 2 s
;; after the first emacsclient -c attaches.
(add-hook 'window-setup-hook
          (lambda ()
            (run-with-idle-timer 2 nil #'my/idle-preload-next)))

;; --- Deferred-restart notice ----------------------------------------
;; When `darwin-rebuild switch' runs from a shell INSIDE this daemon,
;; the activation skips the daemon bounce (killing us would kill the
;; rebuild's own shell) and drops this flag instead.  Surface it so
;; "did I restart into the new config yet?" never lingers: SPC q
;; applies it (KeepAlive respawns the daemon on the new generation).
(defun my/check-restart-pending ()
  "Notify once if a nix rebuild deferred the daemon restart."
  (let ((flag (expand-file-name ".restart-pending" user-emacs-directory)))
    (when (file-exists-p flag)
      (delete-file flag)
      (message "nix: new generation on disk — SPC q to restart emacs into it"))))
(run-with-idle-timer 5 t #'my/check-restart-pending)

(provide 'config-perf)
;;; config-perf.el ends here
