;;; config-perf.el --- Persistence + cheap built-ins + idle preload -*- lexical-binding: t; -*-
;;; Commentary:
;; benchmark-init is loaded from early-init.el (must be first).
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
;; Eliminates the stutter that happens when our 64MB gc-cons-threshold
;; trips mid-keystroke on large buffers. Doom uses this; widely
;; recommended.  1 GiB high-threshold based on monkeynut.org report
;; that 64 MiB still trips during typical scrolling.
(use-package gcmh
  :hook (after-init . gcmh-mode)
  :init
  (setq gcmh-idle-delay 'auto
        gcmh-auto-idle-delay-factor 10
        gcmh-high-cons-threshold (* 1024 1024 1024)))   ; 1 GiB

;; Restrict VC backends to ones we actually use. Default has 8 entries
;; (RCS CVS SVN SCCS SRC Bzr Git Hg); each costs a stat() per file
;; open as VC sniffs for the backend.  Trim to Git + JJ (vc-jj).
(setq vc-handled-backends '(Git JJ))

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
    vterm         ; SPC o t     — loads C dynamic module
    gptel         ; SPC a a     — loads provider backends
    notdeft       ; SPC n s     — Xapian binding load
    tempel        ; prog-mode hook
    elfeed        ; SPC o f
    pdf-tools)    ; opening *.pdf
  "Heavy packages to pre-load on idle so first-use is not laggy.
Order matters — earliest entries get loaded soonest.")

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
