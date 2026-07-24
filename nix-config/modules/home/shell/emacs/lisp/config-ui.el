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
;; doom-alabaster's defaults for `region' and isearch are dim on its
;; dark bg — saturated blue selection + muted amber search highlight
;; are the tuned values from earlier iterations.
;; Apply only when alabaster is active; reset to `unspecified' when
;; toggling to modus so the light theme's own colors take over.
;; `:distant-foreground' kicks in only when the selected text's own fg
;; is too low-contrast against the selection bg (dim punctuation,
;; muted faces) — normal text renders unchanged.
(defun my/apply-alabaster-tweaks ()
  "Brighten region/search faces under doom-alabaster."
  (custom-set-faces
   '(region  ((t (:background "#525868" :distant-foreground "#ffffff" :extend t))))
   ;; Window dividers in the slate accent — on the true-black bg the
   ;; boundary between a bottom side window (ghostel/dired popup) and
   ;; the buffer above is otherwise nearly invisible.
   '(window-divider             ((t (:foreground "#525868"))))
   '(window-divider-first-pixel ((t (:foreground "#525868"))))
   '(window-divider-last-pixel  ((t (:foreground "#525868")))))
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
   '(window-divider             ((t nil)))
   '(window-divider-first-pixel ((t nil)))
   '(window-divider-last-pixel  ((t nil))))
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

;; --- Tame transient popups ------------------------------------------
;; Help/warnings/backtrace/apropos buffers otherwise split the frame
;; wherever display-buffer feels like it — the "accidental keypress →
;; popup mangles my layout" rage.  Route them ALL into one bottom side
;; window (slot 1; ghostel/dired popups use slot 0) so they appear in
;; a single predictable strip and replace each other instead of
;; stacking.  `q' inside closes them; `SPC w k' (config-evil) nukes
;; every popup from anywhere; `SPC w u' (winner) undoes any mangling.
(add-to-list 'display-buffer-alist
             '((or (derived-mode . help-mode)
                   (derived-mode . helpful-mode)
                   (derived-mode . apropos-mode)
                   (derived-mode . debugger-mode)
                   "\\`\\*\\(Warnings\\|Backtrace\\|Compile-Log\\|Async-native-compile-log\\|lsp-help\\)\\*\\'")
               (display-buffer-in-side-window)
               (side . bottom)
               (slot . 1)
               (window-height . 0.3)))

(defun my/popup-close-all ()
  "Close every side window and stray help-style window in the frame."
  (interactive)
  (dolist (win (window-list nil 'no-minibuf))
    (when (and (window-live-p win)
               (or (window-parameter win 'window-side)
                   (with-current-buffer (window-buffer win)
                     (derived-mode-p 'help-mode 'helpful-mode
                                     'apropos-mode 'debugger-mode))))
      (when (window-deletable-p win)
        (delete-window win)))))

;; --- Visible window dividers (only while a bottom popup exists) -----
;; The boundary where ghostel/dired popups meet the buffer above is
;; invisible on the black bg.  `window-divider-mode' is all-or-nothing
;; though: enabled statically it also draws a useless line under a
;; SOLE full-frame window (above the echo area).  So sync the mode to
;; the presence of a bottom side window: popup appears → dividers on;
;; popup gone → dividers off.  Colored via the `window-divider*' faces
;; in the alabaster tweaks above.
(setq window-divider-default-places 'bottom-only
      window-divider-default-bottom-width 2)
(defun my/window-divider-sync (&rest _)
  "Enable window dividers only while a bottom side window is shown."
  (let ((want (seq-some (lambda (w)
                          (eq (window-parameter w 'window-side) 'bottom))
                        (window-list nil 'no-minibuf))))
    (unless (eq (bound-and-true-p window-divider-mode) want)
      (window-divider-mode (if want 1 -1)))))
(add-hook 'window-configuration-change-hook #'my/window-divider-sync)

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

;; --- In-frame video/web: xwidget-webkit (SPC o w) -------------------
;; Our emacs 31 build ships xwidgets; `xwidget-webkit-browse-url' opens
;; a real WebKit view as a buffer — youtube plays inside the frame.
;;
;; The NS xwidget DOUBLE-DELIVERS keystrokes: emacs processes the key
;; AND the page sees it (observed: SPC pauses the video and pops the
;; leader simultaneously; j/k scroll AND seek).  Give xwidget buffers
;; emacs state so plain keys belong to the PAGE only — SPC=pause,
;; j/k=seek, f=fullscreen, native app semantics — same philosophy as
;; ghostel/vterm.  `M-SPC' remains the leader from any state, so
;; workspace/buffer switching stays one chord away.
(with-eval-after-load 'evil
  (evil-set-initial-state 'xwidget-webkit-mode 'emacs))
;; Crude-but-effective dark mode for pages that ignore the OS
;; `prefers-color-scheme' (macOS dark mode already covers the polite
;; sites): invert the page, re-invert media so images/video look
;; normal.  Applied AUTOMATICALLY on every page load (see the
;; `xwidget-webkit-callback' advice below); `SPC o D' toggles it off
;; for pages that are already dark-and-double-inverted.
(defvar my/xwidget-dark-by-default t
  "Non-nil applies the invert-filter dark mode to every loaded page.")

(defconst my/xwidget--dark-js
  "(function(){var go=function(){if(document.getElementById('emacs-dark'))return;var bg=function(el){if(!el)return null;var c=getComputedStyle(el).backgroundColor;var m=c.match(/rgba?\\((\\d+),\\s*(\\d+),\\s*(\\d+)(?:,\\s*([\\d.]+))?\\)/);if(!m)return null;var a=m[4]===undefined?1:parseFloat(m[4]);if(a<0.1)return null;return[+m[1],+m[2],+m[3]];};var c=bg(document.body)||bg(document.documentElement)||[255,255,255];var lum=(0.2126*c[0]+0.7152*c[1]+0.0722*c[2])/255;if(lum<0.5)return;var s=document.createElement('style');s.id='emacs-dark';s.textContent='html{filter:invert(90%) hue-rotate(180deg)}img,video,iframe,canvas,svg{filter:invert(100%) hue-rotate(180deg)}';document.head.appendChild(s);};setTimeout(go,300);})();"
  "Luminance-aware dark mode for the on-load hook.
Samples the page's real background color (body, falling back to html,
falling back to the white browsers render for transparent) and only
injects the invert filter when relative luminance says the page is
LIGHT — natively dark pages are left untouched instead of being
double-inverted to white.  300ms settle delay lets SPA themes apply
before measuring.")

(defconst my/xwidget--unclutter-js
  "(function(){if(document.getElementById('emacs-unclutter'))return;var s=document.createElement('style');s.id='emacs-unclutter';s.textContent='#masthead-ad,ytd-ad-slot-renderer,ytd-display-ad-renderer,ytd-in-feed-ad-layout-renderer,.adsbygoogle,[id^=google_ads]{display:none!important}';document.head.appendChild(s);setInterval(function(){var b=document.querySelector('.ytp-skip-ad-button,.ytp-ad-skip-button,.ytp-ad-skip-button-modern');if(b)b.click();},700);})();"
  "Cosmetic ad hiding + youtube skip-button auto-clicker.
NOT a real content blocker (WebKit content rules aren't exposed to
elisp): display/feed ads are hidden and skippable video ads get
skipped, but unskippable in-stream ads still play.  For truly ad-free
youtube use mpv/yt-dlp instead.")

(defvar my/xwidget-browse-history nil
  "Minibuffer history for `my/xwidget-browse'.")

(defun my/xwidget-browse (input)
  "Open INPUT in xwidget-webkit, address-bar style.
Clean prompt — stock `xwidget-webkit-browse-url' pre-fills whatever
near point vaguely resembles a URL, which in code buffers is constant
junk.  The url-at-point is still one `M-n' away as the default.
Bare words are searched (duckduckgo); scheme-less domains get https://."
  (interactive
   (list (read-string "browse: " nil 'my/xwidget-browse-history
                      (thing-at-point 'url t))))
  (let* ((input (string-trim (or input "")))
         (url (cond
               ((string-empty-p input) (user-error "Nothing to browse"))
               ((string-match-p "\\`https?://" input) input)
               ((and (string-match-p "\\." input)
                     (not (string-match-p " " input)))
                (concat "https://" input))
               (t (concat "https://duckduckgo.com/?q="
                          (url-hexify-string input))))))
    (xwidget-webkit-browse-url url)))

(defun my/xwidget-toggle-dark ()
  "Toggle the invert-filter dark mode on the current xwidget page."
  (interactive)
  (xwidget-webkit-execute-script
   (xwidget-webkit-current-session)
   "(function(){var s=document.getElementById('emacs-dark');if(s){s.remove();}else{s=document.createElement('style');s.id='emacs-dark';s.textContent='html{filter:invert(90%) hue-rotate(180deg)}img,video,iframe,canvas,svg{filter:invert(100%) hue-rotate(180deg)}';document.head.appendChild(s);}})();"))

(defun my/xwidget--on-load (xwidget xwidget-event-type)
  "Apply dark mode + decluttering after each completed page load.
Mirrors xwidget.el's own load-finished detection: the state string
rides in `last-input-event' slot 3."
  (when (and (eq xwidget-event-type 'load-changed)
             (ignore-errors
               (string-equal (nth 3 last-input-event) "load-finished")))
    (when my/xwidget-dark-by-default
      (xwidget-webkit-execute-script xwidget my/xwidget--dark-js))
    (xwidget-webkit-execute-script xwidget my/xwidget--unclutter-js)))
(advice-add 'xwidget-webkit-callback :after #'my/xwidget--on-load)

;; --- mpv bridge: ad-free playback of the current page ---------------
;; In-stream youtube ads live in the video stream itself — no injected
;; JS/CSS can remove them.  mpv via yt-dlp fetches the raw stream (ads
;; never exist).  Browse/search in webkit, press `m' on a video page,
;; watch ad-free in mpv.
(defun my/xwidget-play-in-mpv ()
  "Play the current xwidget page's URL in mpv (yt-dlp; no ads)."
  (interactive)
  (let ((url (xwidget-webkit-uri (xwidget-webkit-current-session))))
    (start-process "xwidget-mpv" nil "mpv" url)
    (message "mpv: %s" url)))

;; --- Vimium-style link hints ----------------------------------------
;; Architecture: overlays go INTO the page via JS, but all keyboard
;; input stays in EMACS (the page never needs focus).  `f' labels every
;; visible link/button with a 2-char code (asdfghjkl x2 = 81 max);
;; type the code, the element is clicked.  C-g cancels.
(defconst my/xwidget--hint-chars "asdfghjkl")

(defconst my/xwidget--hints-show-js
  "(function(){var old=document.getElementById('emacs-hints');if(old)old.remove();var els=Array.from(document.querySelectorAll('a[href],button,[role=button],input:not([type=hidden]),textarea,select,[onclick]')).filter(function(el){var r=el.getBoundingClientRect();return r.width>2&&r.height>2&&r.bottom>0&&r.top<innerHeight&&r.right>0&&r.left<innerWidth;}).slice(0,81);window.__eh=els;var c='asdfghjkl';var box=document.createElement('div');box.id='emacs-hints';els.forEach(function(el,i){var d=document.createElement('div');d.textContent=c[Math.floor(i/9)]+c[i%9];var r=el.getBoundingClientRect();d.style.cssText='position:fixed;left:'+Math.max(0,r.left)+'px;top:'+Math.max(0,r.top)+'px;background:#fbbf24;color:#000;font:bold 11px monospace;padding:0 3px;z-index:2147483647;border-radius:2px;';box.appendChild(d);});document.body.appendChild(box);return els.length;})();")

(defconst my/xwidget--hint-click-js
  "(function(i){var b=document.getElementById('emacs-hints');if(b)b.remove();var el=window.__eh&&window.__eh[i];if(el){el.focus&&el.focus();el.click();}})(%d);")

(defconst my/xwidget--hints-hide-js
  "(function(){var b=document.getElementById('emacs-hints');if(b)b.remove();})();")

(defun my/xwidget-follow-link ()
  "Vimium-style hints: label visible links, type a 2-char code, click."
  (interactive)
  (let ((session (xwidget-webkit-current-session)))
    (xwidget-webkit-execute-script session my/xwidget--hints-show-js)
    (condition-case nil
        (let* ((c1 (read-char "hint (row: asdfghjkl): "))
               (c2 (read-char (format "hint %c_: " c1)))
               (i1 (cl-position c1 my/xwidget--hint-chars))
               (i2 (cl-position c2 my/xwidget--hint-chars)))
          (if (and i1 i2)
              (xwidget-webkit-execute-script
               session (format my/xwidget--hint-click-js (+ (* 9 i1) i2)))
            (xwidget-webkit-execute-script session my/xwidget--hints-hide-js)
            (message "no such hint")))
      (quit (xwidget-webkit-execute-script
             session my/xwidget--hints-hide-js)))))

;; --- Vimium-flavored keymap -----------------------------------------
;; The buffer is emacs-state, so plain keys reach this map unless a
;; page text field grabbed focus.  Stock keys kept where sane (b back,
;; r reload, +/- zoom, w copy url); vimium muscle memory layered on:
;;   j/k line scroll   d/u page down/up   gg/G top/bottom
;;   f follow-link hints   H/L back/forward   o open url/search
;;   m play page in mpv (ad-free)   q kill browser
;; (stock `g'=browse-url is sacrificed for gg; `o' replaces it.)
(with-eval-after-load 'xwidget
  (let ((map xwidget-webkit-mode-map))
    (define-key map (kbd "q") #'kill-current-buffer)
    (define-key map (kbd "j") #'xwidget-webkit-scroll-up-line)
    (define-key map (kbd "k") #'xwidget-webkit-scroll-down-line)
    (define-key map (kbd "d") #'xwidget-webkit-scroll-up)
    (define-key map (kbd "u") #'xwidget-webkit-scroll-down)
    (define-key map (kbd "g") nil)
    (define-key map (kbd "g g") #'xwidget-webkit-scroll-top)
    (define-key map (kbd "G") #'xwidget-webkit-scroll-bottom)
    (define-key map (kbd "f") #'my/xwidget-follow-link)
    (define-key map (kbd "H") #'xwidget-webkit-back)
    (define-key map (kbd "L") #'xwidget-webkit-forward)
    (define-key map (kbd "o") #'my/xwidget-browse)
    (define-key map (kbd "m") #'my/xwidget-play-in-mpv)
    ;; `M-SPC' is unreliable here: macOS treats option-space as text
    ;; input and the WKWebView swallows it (types an nbsp page-side)
    ;; before emacs can read the leader — while PLAIN keys still reach
    ;; this map, so `M-SPC b b' became two page-backs instead of a
    ;; buffer switch.  Give webkit buffers `,' as a literal leader:
    ;; `, b b' switch buffer, `, 1..9' workspaces, `, o t' terminal.
    (when (boundp 'my/leader-prefix-map)
      (define-key map (kbd ",") my/leader-prefix-map))))

;; config-evil, not general: config-ui loads BEFORE config-evil, and
;; `my/leader' only exists after general's :config runs — same trap as
;; the theme-toggle binding above.
(with-eval-after-load 'config-evil
  (when (fboundp 'my/leader)
    (my/leader
      "ow" '(my/xwidget-browse :which-key "browse (in-frame webkit)")
      "oD" '(my/xwidget-toggle-dark    :which-key "xwidget: dark toggle"))))

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
               (switch-to-buffer target-buf)
               ;; macOS focus-stealing: launchers that spawn us WITHOUT
               ;; LaunchServices activation (Tuna) leave this fresh
               ;; frame BEHIND the launcher — first press "does
               ;; nothing", second press hits the raise branch.  An app
               ;; may always activate ITSELF: bare `activate' in
               ;; ns-do-applescript targets us, no app-name resolution.
               ;; (Spotlight launches don't need this — harmless there.)
               (when (fboundp 'ns-do-applescript)
                 (ignore-errors (ns-do-applescript "activate"))))
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
