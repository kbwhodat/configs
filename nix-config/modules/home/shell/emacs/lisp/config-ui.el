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

;; --- Theme: doom-alabaster ↔ doom-alabaster-light ------------------
;; Same minimal-syntax-highlighting identity, just bg/fg flipped.
;;   - dark : kbwhodat's `doom-alabaster' fork (black bg, soft fg)
;;   - light: in-repo `doom-alabaster-light' (Sublime alabaster
;;            original palette — white bg, red comments)
;; Toggle on `SPC t t' feels like flipping the page, not changing
;; themes.
(add-to-list 'custom-theme-load-path
             (expand-file-name "themes/doom-alabaster-theme" user-emacs-directory))
(add-to-list 'custom-theme-load-path
             (expand-file-name "themes/doom-alabaster-light-theme" user-emacs-directory))

(defvar my/dark-theme  'doom-alabaster
  "Dark theme used by `my/toggle-theme'.")
(defvar my/light-theme 'doom-alabaster-light
  "Light theme used by `my/toggle-theme' — Sublime Alabaster port.")
(defvar my/current-theme my/dark-theme
  "Theme currently applied.  Updated by `my/toggle-theme'.")

;; --- doom-alabaster face polish ------------------------------------
;; doom-alabaster's defaults for `region', `hl-line', and isearch are
;; dim on its dark bg — saturated blue selection + muted amber search
;; highlight are the tuned values from earlier iterations.
;; Apply only when alabaster is active; reset to `unspecified' when
;; toggling to modus so the light theme's own colors take over.
(defun my/apply-alabaster-tweaks ()
  "Brighten region/hl-line/search faces under doom-alabaster."
  (custom-set-faces
   '(region  ((t (:background "#525868" :extend t))))
   '(hl-line ((t (:background "#1f2733" :extend t)))))
  (dolist (spec '((isearch                "#5d4e16" t)   ; muted amber bold (current)
                  (evil-ex-search         "#5d4e16" t)
                  (lazy-highlight         "#3d3622" nil) ; even dimmer (other matches)
                  (evil-ex-lazy-highlight "#3d3622" nil)))
    (let ((face (nth 0 spec)) (bg (nth 1 spec)) (bold (nth 2 spec)))
      (when (facep face)
        (set-face-attribute face nil
                            :background bg
                            :foreground "#fde68a"
                            :weight (if bold 'bold 'normal)
                            :underline nil
                            :box nil)))))

(defun my/clear-alabaster-tweaks ()
  "Reset alabaster-tuned faces so the active theme's own colors win."
  (custom-set-faces
   '(region  ((t nil)))
   '(hl-line ((t nil))))
  (dolist (face '(isearch evil-ex-search lazy-highlight evil-ex-lazy-highlight))
    (when (facep face)
      (set-face-attribute face nil
                          :background 'unspecified
                          :foreground 'unspecified
                          :weight 'unspecified
                          :underline 'unspecified
                          :box 'unspecified))))

(defun my/load-current-theme ()
  "Activate `my/current-theme' and apply alabaster-specific face polish.
Type face brightness (base8 = pure white for dark, pure black for
light) and weight (normal) are baked directly into both theme files'
face-override blocks — no runtime override needed."
  (mapc #'disable-theme custom-enabled-themes)
  (load-theme my/current-theme t)
  (if (eq my/current-theme my/dark-theme)
      (my/apply-alabaster-tweaks)
    (my/clear-alabaster-tweaks)))

;; Load theme at DAEMON STARTUP, not on first GUI frame.  Earlier we
;; deferred to `after-make-frame-functions' to skip the work on the
;; daemon's TTY F1 — but that moved the ~300-face theme apply to the
;; critical path of `emacsclient -c', which the user perceives as a
;; 30 s "blank black frame" while theme + font + session restore all
;; run synchronously before the frame can paint.
;;
;; `load-theme' itself doesn't need a graphical frame; it registers
;; face specs that resolve to TTY colors on TTY frames and RGB on GUI.
;; Calling it at `window-setup-hook' (daemon TTY F1 paint) means the
;; daemon is fully themed before any emacsclient connects — the GUI
;; frame inherits the styled state and paints immediately.
(add-hook 'window-setup-hook #'my/load-current-theme)

(defun my/toggle-theme ()
  "Swap between dark and light alabaster."
  (interactive)
  (setq my/current-theme
        (if (eq my/current-theme my/dark-theme)
            my/light-theme
          my/dark-theme))
  (my/load-current-theme)
  (message "Theme: %s" my/current-theme))

;; Wait on `config-evil', not `general' — `my/leader' is created
;; INSIDE general's `:config' block, and `with-eval-after-load 'general'
;; fires the moment `(provide 'general)' runs (end of general.el) which
;; is BEFORE that `:config' block executes.  Other modules using the
;; same `general' eval-after-load pattern only get away with it because
;; they're required AFTER config-evil — config-ui is the one loaded
;; before, so we key off the file that actually defines the leader.
(with-eval-after-load 'config-evil
  (when (fboundp 'my/leader)
    (my/leader "tt" '(my/toggle-theme :which-key "theme (dark/light)"))))

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

;; --- Font: apply after first GRAPHICAL frame ---------------------
;; Same FRAME-arg fix as the theme loader above — bare
;; `(display-graphic-p)' consults the daemon's TTY F1 and would
;; never trigger, leaving the GUI frame at the default font.
(defun my/set-font-when-graphical (&optional frame)
  (let ((target (or frame (selected-frame))))
    (when (display-graphic-p target)
      (set-face-attribute 'default nil
                          :family "ComicShannsMono Nerd Font Mono"
                          :height 140)
      (remove-hook 'after-make-frame-functions
                   #'my/set-font-when-graphical))))
(add-hook 'window-setup-hook        #'my/set-font-when-graphical)
(add-hook 'after-make-frame-functions #'my/set-font-when-graphical)

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
     ;; No GUI frame — defer make-frame via timer.  On emacs 31 +
     ;; macOS, `make-frame' from an --eval context deadlocks the main
     ;; event loop; timer fires after --eval returns.
     (t
      (run-at-time
       0 nil
       (lambda ()
         (let ((target-buf nil))
           (when (fboundp 'my/session-lite-read)
             (let* ((snap (my/session-lite-read))
                    (file (and snap (plist-get snap :selected-file))))
               (when (and file (file-exists-p file) (file-readable-p file))
                 (let ((enable-local-variables nil))
                   (setq target-buf (find-file-noselect file))))))
           ;; Fallback to *scratch* if no persisted file.
           (unless (and target-buf (buffer-live-p target-buf))
             (setq target-buf (get-buffer-create "*scratch*")))
           (set-buffer target-buf)
           ;; Explicit window-system: bare make-frame from daemon = TTY.
           (let* ((gui-ws (cond ((eq system-type 'darwin) 'ns)
                                ((getenv "WAYLAND_DISPLAY") 'pgtk)
                                (t 'x)))
                  (frame (make-frame `((window-system . ,gui-ws)))))
             (with-selected-frame frame
               (switch-to-buffer target-buf))
             (select-frame-set-input-focus frame)
             (raise-frame frame)
             (redisplay t)))))
      ;; Return t so the --eval caller sees success immediately.
      t))))

;; Search highlight, region, hl-line: using modus's defaults.  Modus
;; ships proper WCAG-AAA `isearch' / `lazy-highlight' / `region' /
;; `hl-line' colors for both vivendi and operandi — overriding them
;; with hardcoded hex breaks the toggle (one palette won't suit both).

(provide 'config-ui)
;;; config-ui.el ends here
