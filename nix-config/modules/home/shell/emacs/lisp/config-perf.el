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
