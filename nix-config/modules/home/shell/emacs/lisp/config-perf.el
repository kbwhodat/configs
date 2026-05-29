;;; config-perf.el --- Persistence + cheap built-ins + idle preload -*- lexical-binding: t; -*-
;;; Commentary:
;; This file enables built-in modes that are cheap, and pre-loads heavy
;; packages on idle so first-use lag (SPC g s, SPC o t, SPC s g, ...)
;; is paid in the background instead of in front of the user.
;;; Code:

;; Remember cursor position per file
(save-place-mode 1)

;; Recent files — needed for SPC f r binding
(setq recentf-max-saved-items 500)
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

;; eldoc fires textDocument/hover at the LSP every time the cursor
;; rests for 0.5 s.  With slow servers (pyright, tsserver) that means
;; the echo area flickers while you're trying to read it.  1 s gives
;; you breathing room before the round-trip starts.
(setq eldoc-idle-delay 1.0)

;; flymake reruns diagnostics 0.5 s after every change — that triggers
;; an LSP didChange + republish cycle on every keystroke pause.  1 s
;; throttles it to the speed of human typing.
(with-eval-after-load 'flymake
  (setq flymake-no-changes-timeout 1.0))

;; Faster mode-line / cursor-blink / which-key wake-up.  Marginal but
;; free — default 0.5 s is conservative for terminal emacs from 1996.
(setq idle-update-delay 0.1)

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

;; --- Crash safety: backup files + auto-save -------------------------
;; By default emacs litters `file~' and `.#file' next to every save —
;; pollutes git status and dired. Send them to a dedicated dir.
(let ((backup-dir (expand-file-name "backups/" user-emacs-directory)))
  (unless (file-directory-p backup-dir) (make-directory backup-dir t))
  (setq backup-directory-alist        `(("." . ,backup-dir))
        auto-save-file-name-transforms `((".*" ,backup-dir t))
        backup-by-copying t            ; safer (preserves inode for watching tools)
        version-control t              ; numbered backups
        delete-old-versions t
        kept-new-versions 6
        kept-old-versions 2))

;; auto-save-visited-mode: save the file you're editing every 30s.
;; Pairs with undo-fu-session — worst-case data loss is ~30s.
;; Bump interval to 60-120 if you run aggressive file-watchers.
(setq auto-save-visited-interval 30)
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

(defvar my/idle-preload-packages
  '(consult       ; SPC s g/s/b — usually first thing hit
    magit         ; SPC g s     — pulls ~30 sub-files
    majutsu       ; SPC G       — magit-style jj UI; depends on magit
    ghostel       ; SPC o t     — loads ghostel native module
    tempel)       ; prog-mode hook
  "Heavy packages to pre-load on idle so first-use is not laggy.
Order matters — earliest entries get loaded soonest.
Loaded on demand instead (saves RAM and idle CPU):
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

(provide 'config-perf)
;;; config-perf.el ends here
