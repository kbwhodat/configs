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

;; --- Minimal modeline: filled vs hollow dot + buffer name; workspace on right ---
(defun my/modeline-workspace-name ()
  "Return the current persp-mode workspace name, or empty string."
  (or (and (bound-and-true-p persp-mode)
           (fboundp 'get-current-persp)
           (fboundp 'safe-persp-name)
           (let ((name (safe-persp-name (get-current-persp))))
             (and (stringp name) name)))
      ""))

(setq-default
 mode-line-format
 '((:eval
    (let* ((left
            (if (buffer-modified-p)
                (concat
                 (propertize "   ● " 'face '(:foreground "#ffffff" :weight bold))
                 (propertize "%b"    'face '(:foreground "#ffffff" :weight bold)))
              (concat
               (propertize "   ○ " 'face '(:weight bold))
               (propertize "%b"    'face '(:weight bold)))))
           (ws (my/modeline-workspace-name))
           ;; +1 for the right-side trailing space.
           (right-width (1+ (length ws))))
      (concat
       left
       (propertize " " 'display
                   `((space :align-to (- right ,right-width))))
       (propertize ws 'face '(:weight bold)))))))

;; --- Theme load path (kbwhodat doom-alabaster fetched via nix) ---
(add-to-list 'custom-theme-load-path
             (expand-file-name "themes/doom-alabaster-theme" user-emacs-directory))

;; --- Theme: load after first frame is visible ---
(use-package doom-themes
  :defer t
  :init
  (add-hook 'window-setup-hook
            (lambda () (load-theme 'doom-alabaster t))))

;; --- Pulsar: pulse the line on jumps (lightweight) ------------------
;; 3 iterations × 0.04 s = 120 ms animation (was 8 × 0.04 = 320 ms).
;; Visible enough to track where the cursor went without stuttering on
;; weaker hardware.
(use-package pulsar
  :hook (after-init . pulsar-global-mode)
  :config
  (setq pulsar-pulse t
        pulsar-delay 0.04
        pulsar-iterations 3
        pulsar-face 'pulsar-yellow
        pulsar-region-face 'pulsar-yellow)
  (dolist (cmd '(evil-scroll-up evil-scroll-down
                 evil-scroll-page-up evil-scroll-page-down
                 evil-window-up evil-window-down
                 evil-window-left evil-window-right
                 evil-goto-line evil-goto-first-line
                 evil-search-next evil-search-previous
                 windmove-up windmove-down
                 windmove-left windmove-right
                 avy-goto-word-1 avy-goto-line avy-goto-char-timer))
    (add-to-list 'pulsar-pulse-functions cmd)))

;; --- Selection / region highlight ----------------------------------
;; Theme default `region' background is `#5C5C5C' — barely visible on
;; the alabaster dark background.  Use a saturated blue so visual-mode
;; selections (and treemacs highlights, which inherit `region') are
;; obviously visible.  `:extend t' makes the highlight span to the
;; line end like vim's visual-line, not stop at the last char.
(custom-theme-set-faces
 'user
 '(region    ((t (:background "#525868" :extend t))))
 '(hl-line   ((t (:background "#1f2733" :extend t)))))

;; --- Font: apply after first frame ---
(add-hook 'window-setup-hook
          (lambda ()
            (set-face-attribute 'default nil
                                :family "ComicShannsMono Nerd Font Mono"
                                :height 135)))

;; --- Browse URL: use the system default browser ---
(setq browse-url-browser-function 'browse-url-default-browser)

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

Hardened against the \"blank black box\" symptom on macOS:
  - If the existing GUI frame is iconified, un-minimize it first.
  - The new-frame path explicitly switches to a known-good buffer
    (persisted file or *scratch*) BEFORE the frame appears, so the
    frame is never created with an internal/process buffer in its
    window slot.
  - A `(redisplay t)' forces a synchronous paint at the end of every
    path to defeat the Cocoa NSWindow-shown-before-NSView race."
  (let ((gui (seq-find #'display-graphic-p (frame-list))))
    (cond
     ;; Have a GUI frame already.
     (gui
      (when (eq (frame-visible-p gui) 'icon)
        (make-frame-visible gui))
      (select-frame-set-input-focus gui)
      (raise-frame gui)
      (redisplay t))
     ;; No GUI frame — create one, ensuring its buffer is sane.
     (t
      (let ((target-buf nil))
        (when (fboundp 'my/session-lite-read)
          (let* ((snap (my/session-lite-read))
                 (file (and snap (plist-get snap :selected-file))))
            (when (and file (file-exists-p file) (file-readable-p file))
              (let ((enable-local-variables nil))
                (setq target-buf (find-file-noselect file))))))
        ;; Fallback: *scratch* — never trust the daemon's current-buffer
        ;; which may be an invisible process buffer that breaks redisplay.
        (unless (and target-buf (buffer-live-p target-buf))
          (setq target-buf (get-buffer-create "*scratch*")))
        (set-buffer target-buf)
        (let ((frame (make-frame '((window-system . ns)))))
          (with-selected-frame frame
            (switch-to-buffer target-buf))
          (select-frame-set-input-focus frame)
          (raise-frame frame)
          (redisplay t)))))))

;; --- Search highlight: make it actually visible ---------------------
;; The default `lazy-highlight' from doom-alabaster was `#2c2c1c'
;; (near-black olive) — invisible on our dark background.  Override
;; both the isearch faces (path used by evil's `/' since
;; `evil-search-module' = 'isearch) AND the evil-ex faces (path used
;; when search-module is 'evil-search) so a future module switch
;; doesn't undo this.  Black text on bright amber for the current
;; match (`isearch'), softer yellow for other matches in the buffer
;; (`lazy-highlight').  Theme-agnostic: stays legible on any
;; background since contrast is enforced explicitly.
(dolist (spec '((isearch              "#fbbf24" t)   ; amber-400, bold
                (evil-ex-search       "#fbbf24" t)
                (lazy-highlight       "#facc15" nil) ; yellow-400
                (evil-ex-lazy-highlight "#facc15" nil)))
  (let ((face (nth 0 spec))
        (bg   (nth 1 spec))
        (bold (nth 2 spec)))
    (when (facep face)
      (set-face-attribute face nil
                          :background bg
                          :foreground "#000000"
                          :weight (if bold 'bold 'normal)
                          :underline nil
                          :box nil))))

(provide 'config-ui)
;;; config-ui.el ends here
