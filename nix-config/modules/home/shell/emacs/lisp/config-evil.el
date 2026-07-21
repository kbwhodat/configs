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

;; vim-commentary: `gcc' toggles the line, `gc' is an operator so it
;; composes with everything — `gcap' (paragraph), `gcif' (function via
;; treesit textobj), visual selection + `gc'.  Comment syntax comes
;; from each major mode, so it does the right thing in nix/elisp/go/py.
(use-package evil-commentary
  :after evil
  :config (evil-commentary-mode 1))

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
  ;; Predefine the leader keymap so we can pass its value (not symbol)
  ;; to the M-SPC alias below — passing the symbol made general try to
  ;; call it as a command, hence the `commandp' error.
  (defvar my/leader-prefix-map (make-sparse-keymap)
    "Leader keymap.  Invoked by both `SPC' and `M-SPC' in every state.")

  (general-create-definer my/leader
    ;; SPC = leader in MODAL states only (normal/visual/motion).  Do
    ;; NOT include insert/emacs here — that would shadow plain SPC in
    ;; vterm / minibuffer / magit popups, breaking typing.
    :states '(normal visual motion)
    :keymaps 'override
    :prefix "SPC"
    :prefix-map 'my/leader-prefix-map)

  ;; M-SPC = same leader, accessible from every state including insert
  ;; and emacs.  Bound at the top level of the override map (not a
  ;; state-specific aux map), so it works regardless of evil state and
  ;; doesn't collide with plain SPC.  Pair with adding "M-SPC" to
  ;; `vterm-keymap-exceptions' (config-term.el) so vterm passes it
  ;; through to emacs instead of forwarding to the shell.
  (define-key general-override-mode-map (kbd "M-SPC") my/leader-prefix-map)

  ;; Belt-and-suspenders: in some major modes (`*Messages*',
  ;; help-mode, magit, etc.) evil's `evil-motion-state-map' default
  ;; binding (`SPC' = `evil-forward-char') wins over the general-
  ;; override aux through evil's intercept chain.  Re-bind SPC in evil's
  ;; own motion-state-map to the leader prefix so SPC works as the
  ;; leader EVERYWHERE normal/motion/visual state is active.  Loses
  ;; SPC = forward-char in motion state, but `l' still does that.
  (with-eval-after-load 'evil
    (define-key evil-motion-state-map (kbd "SPC") my/leader-prefix-map))

  ;; --- windmove leaves (preserved from user's existing setup) ---
  (my/leader
    "h" '(windmove-left  :which-key "← window")
    "j" '(windmove-down  :which-key "↓ window")
    "k" '(windmove-up    :which-key "↑ window")
    "l" '(windmove-right :which-key "→ window"))

  ;; --- buffers / quit / nav ---
  (my/leader
    "b"  '(:ignore t :which-key "buffers")
    ;; `bb' — current workspace only.  `persp-switch-to-buffer' uses
    ;; persp-mode's filtered reader directly.
    "bb" '(persp-switch-to-buffer    :which-key "switch (in workspace)")
    ;; `bB' — ALL buffers, bypassing both the persp filter and the
    ;; chatter filter.  Vanilla `switch-to-buffer' goes through
    ;; `persp-set-read-buffer-function t' (set in config-sessions.el)
    ;; and is therefore restricted to current-workspace buffers too,
    ;; meaning `*Messages*' etc. are unreachable AND a typed name silently
    ;; becomes a NEW empty buffer instead of finding the existing one.
    ;; `my/switch-to-buffer-global' (in config-sessions.el) dynamically
    ;; rebinds `read-buffer-function' to nil so the picker sees the true
    ;; global buffer-list.
    "bB" '(my/switch-to-buffer-global :which-key "switch (all buffers, global)")
    ;; `kill-this-buffer' was retired in emacs 30 — it errors unless
    ;; called as a menu event.  Use `kill-buffer' (prompts via vertico)
    ;; for "kill a buffer" and `kill-current-buffer' for the no-prompt
    ;; "kill the one I'm in" path.
    "bd" '(kill-buffer         :which-key "kill (pick)")
    "bq" '(bury-buffer         :which-key "bury (hide, keep)")
    "d"  '(kill-current-buffer :which-key "kill current")
    "D"  '(bury-buffer         :which-key "bury current")
    ;; Workspace-aware: only cycles buffers in the current persp-mode
    ;; workspace.  See `my/persp-cycle-buffer' in config-sessions.el.
    ;; Vanilla `previous-buffer'/`next-buffer' walk the global list and
    ;; would leak buffers from other workspaces into the cycle.
    ";"  '(my/persp-previous-buffer :which-key "prev buffer (workspace)")
    "'"  '(my/persp-next-buffer     :which-key "next buffer (workspace)")
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

;; --- Tree-sitter text objects (syntax units as vim text objects) -----
;; Uses the same treesit grammars the *-ts-modes run on.  Adds:
;;   dif / daf   delete inner/whole function       vif / vaf  select it
;;   cic / vac   change/select class
;;   cia / daa   change inner argument / delete argument (incl. comma)
;;   dil / val   loops
;; Languages without bundled queries (e.g. nix) just echo
;; "No textobject query" — harmless no-op.
(use-package evil-textobj-tree-sitter
  :after evil
  :config
  (define-key evil-outer-text-objects-map "f"
              (evil-textobj-tree-sitter-get-textobj "function.outer"))
  (define-key evil-inner-text-objects-map "f"
              (evil-textobj-tree-sitter-get-textobj "function.inner"))
  (define-key evil-outer-text-objects-map "c"
              (evil-textobj-tree-sitter-get-textobj "class.outer"))
  (define-key evil-inner-text-objects-map "c"
              (evil-textobj-tree-sitter-get-textobj "class.inner"))
  (define-key evil-outer-text-objects-map "a"
              (evil-textobj-tree-sitter-get-textobj "parameter.outer"))
  (define-key evil-inner-text-objects-map "a"
              (evil-textobj-tree-sitter-get-textobj "parameter.inner"))
  (define-key evil-outer-text-objects-map "l"
              (evil-textobj-tree-sitter-get-textobj "loop.outer"))
  (define-key evil-inner-text-objects-map "l"
              (evil-textobj-tree-sitter-get-textobj "loop.inner")))

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
