;;; config-ui.el --- Theme, font, modeline, frame, browse-url -*- lexical-binding: t; -*-
;;; Commentary:
;; Theme + font deferred to window-setup-hook so they don't block first paint.
;;; Code:

;; --- Silence the bell (no flash, no system "alert" sound on macOS) ---
;; Evil's end-of-buffer, search-no-match, etc. ring the bell by default.
;; On macOS that pipes through the system alert sound — annoying.
(setq ring-bell-function 'ignore
      visible-bell nil)

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

;; --- Idempotent "summon emacs" entry point --------------------------
;; Hammerspoon Ctrl+Shift+Space + EmacsClient.app both used to run
;; `emacsclient -c -a ""' which ALWAYS creates a new frame — pressing
;; the hotkey twice gave you two stacked scratch frames.  This function
;; focuses an existing GUI frame if one is open, else creates one;
;; called from both endpoints so behavior is consistent.
(defun my/raise-or-make-frame ()
  "Focus an existing graphical frame, or create one if none exist.
Intended to be called via `emacsclient --eval' from a global hotkey or
.app launcher.  TTY frames (e.g. the daemon's F1) are ignored.

When making a new frame, pre-open the last persisted file (from
`config-session-lite') so the new frame opens directly on that buffer
— no `*scratch*' flash before restore catches up.  Falls back to
whatever buffer is current if no usable snapshot exists."
  (let ((gui (seq-find #'display-graphic-p (frame-list))))
    (if gui
        (progn
          (select-frame-set-input-focus gui)
          (raise-frame gui))
      ;; Pre-open the persisted file in the daemon's current buffer slot
      ;; BEFORE creating the frame.  `make-frame' inherits current-buffer
      ;; for the new frame's initial window, so the frame appears with
      ;; the right file already loaded — no scratch-then-swap visible.
      (when (fboundp 'my/session-lite-read)
        (let* ((snap (my/session-lite-read))
               (file (and snap (plist-get snap :selected-file))))
          (when (and file
                     (file-exists-p file)
                     (file-readable-p file))
            (find-file file))))
      (make-frame '((window-system . ns))))))

(provide 'config-ui)
;;; config-ui.el ends here
