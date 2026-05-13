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

(use-package undo-fu :after evil)
(use-package undo-fu-session
  :after undo-fu
  :config (global-undo-fu-session-mode 1))

(use-package which-key
  :config
  (setq which-key-idle-delay 0.3)
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
    "bb" '(switch-to-buffer    :which-key "switch")
    "bd" '(kill-this-buffer    :which-key "kill")
    "d"  '(kill-current-buffer :which-key "kill current")
    ";"  '(previous-buffer     :which-key "prev buffer")
    "'"  '(next-buffer         :which-key "next buffer")
    "q"  '(save-buffers-kill-terminal :which-key "quit"))

  ;; --- windows ---
  (my/leader
    "w"  '(:ignore t :which-key "windows")
    "wv" '(split-window-right :which-key "vsplit")
    "ws" '(split-window-below :which-key "hsplit")
    "wd" '(delete-window      :which-key "close"))

  ;; --- help under SPC h (in addition to windmove leaf) ---
  (my/leader
    "h k" '(describe-key      :which-key "describe key")
    "h f" '(describe-function :which-key "describe func")
    "h v" '(describe-variable :which-key "describe var")
    "h m" '(describe-mode     :which-key "describe mode")
    "h b" '(benchmark-init/show-durations-tabulated :which-key "bench report"))

  ;; --- toggles ---
  (my/leader
    "t"  '(:ignore t :which-key "toggle")
    "tl" '(display-line-numbers-mode :which-key "line numbers")
    "tw" '(visual-line-mode          :which-key "wrap")))

;; --- Avy (deferred until first SPC j sub-binding) ---
(use-package avy
  :defer t
  :commands (avy-goto-word-1 avy-goto-line avy-goto-char-timer)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "j w" '(avy-goto-word-1     :which-key "word")
        "j l" '(avy-goto-line       :which-key "line")
        "j c" '(avy-goto-char-timer :which-key "char")))))

(provide 'config-evil)
;;; config-evil.el ends here
