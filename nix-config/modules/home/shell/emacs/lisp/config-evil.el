;;; config-evil.el --- Evil + leader + which-key -*- lexical-binding: t; -*-
;;; Commentary:
;; evil-collection deferred 0.5s idle (keymaps for ~100 modes).
;; which-key delay tightened from 1.0s to 0.3s.
;;; Code:

;; --- Must be set BEFORE evil loads ---
(setq evil-want-C-u-scroll t
      evil-want-C-i-jump t
      evil-want-keybinding nil)

(use-package evil
  :init
  (setq evil-undo-system 'undo-fu
        evil-normal-state-cursor '(box . 1)
        evil-insert-state-cursor '(bar . 1)
        evil-visual-state-cursor '(hollow . 1))
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config
  (run-with-idle-timer
   0.5 nil
   (lambda () (evil-collection-init))))

(use-package evil-surround
  :after evil
  :config (global-evil-surround-mode 1))

;; --- Ctrl-Q = blockwise-visual (alias for vanilla evil's C-v) -------
;; C-q stays as `quoted-insert' in insert state so you can still
;; insert literal tabs / control chars there.
(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "C-q") #'evil-visual-block)
  (define-key evil-motion-state-map (kbd "C-q") #'evil-visual-block)
  (define-key evil-visual-state-map (kbd "C-q") #'evil-visual-block))

(use-package undo-fu :after evil)
(use-package undo-fu-session
  :after undo-fu
  :config (global-undo-fu-session-mode 1))

(use-package which-key
  :config
  (setq which-key-idle-delay 1.5)
  (which-key-mode 1))

(use-package general
  :config
  (general-create-definer my/leader
    :states '(normal visual motion)
    :keymaps 'override
    :prefix "SPC" :non-normal-prefix "M-SPC")

  ;; --- windmove leaves (preserved from user's existing setup) ---
  (my/leader
    "h" '(windmove-left  :which-key "← window")
    "j" '(windmove-down  :which-key "↓ window")
    "k" '(windmove-up    :which-key "↑ window")
    "l" '(windmove-right :which-key "→ window"))

  ;; --- buffers / quit / nav ---
  (my/leader
    "b"  '(:ignore t :which-key "buffers")
    ;; `persp-switch-to-buffer' restricts the picker to the current
    ;; workspace's buffers.  Vanilla `switch-to-buffer' would also
    ;; filter (because `persp-set-read-buffer-function t' in
    ;; config-sessions.el), but binding the persp variant explicitly
    ;; keeps the intent visible at the call site.
    "bb" '(persp-switch-to-buffer :which-key "switch (in workspace)")
    "bB" '(switch-to-buffer       :which-key "switch (all buffers)")
    ;; `kill-this-buffer' was retired in emacs 30 — it errors unless
    ;; called as a menu event.  Use `kill-buffer' (prompts via vertico)
    ;; for "kill a buffer" and `kill-current-buffer' for the no-prompt
    ;; "kill the one I'm in" path.
    "bd" '(kill-buffer         :which-key "kill (pick)")
    "bq" '(bury-buffer         :which-key "bury (hide, keep)")
    "d"  '(kill-current-buffer :which-key "kill current")
    "D"  '(bury-buffer         :which-key "bury current")
    ";"  '(previous-buffer     :which-key "prev buffer")
    "'"  '(next-buffer         :which-key "next buffer")
    "q"  '(save-buffers-kill-terminal :which-key "quit"))

  ;; --- windows ---
  ;;   SPC -   split below  (key looks like a horizontal divider)
  ;;   SPC \   split right  (key looks like a vertical divider)
  ;; Both jump into the new window so you can start typing immediately.
  (defun my/split-below ()
    (interactive) (split-window-below) (other-window 1))
  (defun my/split-right ()
    (interactive) (split-window-right) (other-window 1))
  (defvar my/window-focus-configuration nil
    "Window configuration saved before focusing one window.")
  (defun my/window-focus-toggle ()
    "Toggle the selected window between focused and restored layout."
    (interactive)
    (if my/window-focus-configuration
        (let ((config my/window-focus-configuration))
          (setq my/window-focus-configuration nil)
          (set-window-configuration config))
      (when (window-parameter (selected-window) 'window-side)
        (user-error "Cannot focus a side window"))
      (setq my/window-focus-configuration (current-window-configuration))
      (delete-other-windows)))
  (my/leader
    "-"  '(my/split-below     :which-key "split below")
    "\\" '(my/split-right     :which-key "split right")
    "w"  '(:ignore t :which-key "windows")
    "wv" '(split-window-right :which-key "vsplit")
    "ws" '(split-window-below :which-key "hsplit")
    "wf" '(my/window-focus-toggle :which-key "focus toggle")
    "wd" '(delete-window      :which-key "close")
    "wu" '(winner-undo        :which-key "layout undo")
    "wr" '(winner-redo        :which-key "layout redo"))

  ;; --- help under SPC ? (SPC h is windmove leaf — general rejects double-bind) ---
  ;; `helpful' replaces describe-* for function/var/key — adds callers,
  ;; references, and source jump.  `describe-mode' has no helpful peer
  ;; (mode docstrings come from the major mode object, not a symbol).
  (my/leader
    "?"   '(:ignore t :which-key "help")
    "? k" '(helpful-key       :which-key "describe key")
    "? f" '(helpful-callable  :which-key "describe func")
    "? v" '(helpful-variable  :which-key "describe var")
    "? m" '(describe-mode     :which-key "describe mode"))

  ;; --- toggles ---
  (my/leader
    "t"  '(:ignore t :which-key "toggle")
    "tl" '(display-line-numbers-mode :which-key "line numbers")
    "tw" '(visual-line-mode          :which-key "wrap")))

;; --- helpful: also rebind the C-h prefix globally --------------------
(use-package helpful
  :defer t
  :commands (helpful-callable helpful-variable helpful-key helpful-command
             helpful-at-point)
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)
         ("C-h o" . helpful-symbol)))

;; --- Avy under SPC SPC (SPC j is windmove leaf — general rejects double-bind) ---
(use-package avy
  :defer t
  :commands (avy-goto-word-1 avy-goto-line avy-goto-char-timer)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "SPC"   '(:ignore t :which-key "jump")
        "SPC w" '(avy-goto-word-1     :which-key "word")
        "SPC l" '(avy-goto-line       :which-key "line")
        "SPC c" '(avy-goto-char-timer :which-key "char")))))

(provide 'config-evil)
;;; config-evil.el ends here
