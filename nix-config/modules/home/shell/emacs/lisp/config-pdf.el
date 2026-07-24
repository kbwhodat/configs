;;; config-pdf.el --- PDF viewer -*- lexical-binding: t; -*-
;;; Commentary:
;; pdf-tools auto-loads when opening *.pdf.
;;; Code:

(use-package pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  ;; pdf-tools-install eagerly tries to enable pdf-occur-global-minor-mode
  ;; which lives in pdf-occur.el and isn't loaded yet at install time
  ;; (autoload-ordering bug in vedang/pdf-tools v20240429). Skip it —
  ;; the :mode autoload above routes *.pdf to pdf-view-mode without
  ;; needing the global install. If we ever need pdf-tools-install,
  ;; require 'pdf-occur first or wrap in (ignore-errors ...).
  )

;; No text cursor in a page viewer.  Evil re-asserts its per-state
;; cursor on EVERY state change, overriding a plain buffer-local
;; `cursor-type nil' (root cause of the returning blinker: the spec
;; `(list nil)' is a no-op to evil, so whatever cursor the previous
;; state set just stayed).  A FUNCTION spec is honored on each state
;; entry — hide it actively, for every state.
(defconst my/evil-cursor-hidden
  (list (lambda () (setq cursor-type nil)))
  "Evil cursor spec that actively hides the cursor.")

(defun my/pdf-hide-cursor ()
  "Hide the (meaningless, blinking) text cursor in pdf buffers."
  (setq-local cursor-type nil)
  (setq-local evil-normal-state-cursor my/evil-cursor-hidden
              evil-motion-state-cursor my/evil-cursor-hidden
              evil-insert-state-cursor my/evil-cursor-hidden
              evil-emacs-state-cursor  my/evil-cursor-hidden))
(add-hook 'pdf-view-mode-hook #'my/pdf-hide-cursor)

;; Render pages in the CURRENT THEME's colors (near-white text on the
;; black alabaster bg) instead of blinding white pages.  Themed mode
;; follows `SPC t t' automatically — light theme gives light pages.
;; Toggle off per-buffer with `M-x pdf-view-themed-minor-mode' for
;; PDFs where color fidelity matters (figures, scans).
;;
;; GUARDED: in the daemon's early non-graphical context (session
;; restore opening pdfs before/while the first GUI frame appears),
;; theme colors resolve to the TTY placeholder "unspecified-fg" and
;; themed-mode errors `(wrong-type-argument color-defined-p ...)' —
;; a File-mode-specification error that ABORTED the session restore
;; mid-flight and left the frame unthemed/white (observed 2026-07-23).
(defvar-local my/pdf--rendered-width nil
  "Window pixel width the page layout was last computed against.")

(defun my/pdf--sync-display ()
  "Keep themed rendering and page centering in sync with the window.
Persistent (NOT one-shot) buffer-local hook: pdf-view computes the
horizontal centering pad (overlay `before-string') only during
redisplay, and at a fixed numeric zoom a window RESIZE skips
re-rendering — so the small initial emacsclient frame being maximized
left the page off-center, permanently (observed 2026-07-23; a one-shot
first-show fixup fired on the small frame and disarmed itself).
Redisplay whenever the displaying window's width differs from the
width we last rendered for; enable themed mode here too (idempotent,
and this is also the earliest safe graphical moment for restored
buffers — the frameless-daemon crash context never has a window)."
  (let ((win (get-buffer-window (current-buffer))))
    (when (and win (display-graphic-p (window-frame win)))
      (unless (bound-and-true-p pdf-view-themed-minor-mode)
        (ignore-errors (pdf-view-themed-minor-mode 1)))
      (let ((w (window-body-width win t)))
        (unless (eql w my/pdf--rendered-width)
          (setq my/pdf--rendered-width w)
          (ignore-errors (pdf-view-redisplay win)))))))

(defun my/pdf-themed-maybe ()
  "Theme immediately when safely possible; keep display synced always."
  (when (display-graphic-p)
    (ignore-errors (pdf-view-themed-minor-mode 1)))
  (add-hook 'window-configuration-change-hook #'my/pdf--sync-display nil t))
(add-hook 'pdf-view-mode-hook #'my/pdf-themed-maybe)

;; Remember the PAGE per pdf across sessions (nov does this for epubs
;; via `nov-save-place-file'; pdf-view had nothing — every restored
;; pdf opened at page 1).
(use-package pdf-view-restore
  :after pdf-tools
  :hook (pdf-view-mode . pdf-view-restore-mode)
  :init
  (setq pdf-view-restore-filename
        (expand-file-name "pdf-view-restore" user-emacs-directory)))

;; --- Per-file ZOOM persistence ---------------------------------------
;; pdf-view-restore remembers the page; nothing remembers the zoom
;; (`pdf-view-display-size': fit-width/fit-page/scale number).  Tiny
;; file-backed alist: recorded whenever a zoom command runs, applied
;; on every open (incl. session restore — value applies pre-display).
(defvar my/pdf-zoom-db-file
  (expand-file-name "pdf-zoom.eld" user-emacs-directory)
  "File persisting per-pdf `pdf-view-display-size'.")
(defvar my/pdf-zoom-db 'unloaded)

(defun my/pdf-zoom--db ()
  (when (eq my/pdf-zoom-db 'unloaded)
    (setq my/pdf-zoom-db
          (when (file-readable-p my/pdf-zoom-db-file)
            (ignore-errors
              (with-temp-buffer
                (insert-file-contents my/pdf-zoom-db-file)
                (read (current-buffer)))))))
  my/pdf-zoom-db)

(defun my/pdf-zoom-remember (&rest _)
  "Record this pdf's current zoom (advice after zoom commands)."
  (when (and buffer-file-name (boundp 'pdf-view-display-size))
    (my/pdf-zoom--db)
    (setf (alist-get buffer-file-name my/pdf-zoom-db nil nil #'equal)
          pdf-view-display-size)
    (with-temp-file my/pdf-zoom-db-file
      (prin1 my/pdf-zoom-db (current-buffer)))))

(defun my/pdf-zoom-restore-here ()
  "Apply this pdf's remembered zoom, if any."
  (when buffer-file-name
    (when-let* ((size (alist-get buffer-file-name (my/pdf-zoom--db)
                                 nil nil #'equal)))
      (setq-local pdf-view-display-size size))))
(add-hook 'pdf-view-mode-hook #'my/pdf-zoom-restore-here)

(with-eval-after-load 'pdf-view
  (dolist (fn '(pdf-view-enlarge pdf-view-shrink pdf-view-scale-reset
                pdf-view-fit-width-to-window pdf-view-fit-page-to-window
                pdf-view-fit-height-to-window))
    (advice-add fn :after #'my/pdf-zoom-remember)))

;; J/K = page turn.  evil-collection binds J to `ignore' and leaves K
;; on `evil-lookup' (useless in a page viewer); its own page keys are
;; C-j/C-k, ]]/[[ and gj/gk — kept, this is additive.  Applied twice
;; (the standard clobber-guard): once when pdf-view loads, again after
;; evil-collection's pdf setup so ours lands last.
(defun my/pdf-evil-keys ()
  "Vim-feel page navigation for pdf buffers (idempotent)."
  (with-eval-after-load 'evil
    (evil-define-key 'normal pdf-view-mode-map
      (kbd "J") #'pdf-view-next-page-command
      (kbd "K") #'pdf-view-previous-page-command)))
(with-eval-after-load 'pdf-view
  (my/pdf-evil-keys))
(with-eval-after-load 'evil-collection
  (add-hook 'evil-collection-setup-hook
            (lambda (mode &rest _)
              (when (eq mode 'pdf)
                (my/pdf-evil-keys)))))

(provide 'config-pdf)
;;; config-pdf.el ends here
