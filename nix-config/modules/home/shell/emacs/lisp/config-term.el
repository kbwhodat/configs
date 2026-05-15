;;; config-term.el --- Terminal (vterm) -*- lexical-binding: t; -*-
;;; Commentary:
;; Flexible terminal layout:
;;
;;   SPC o t  — toggle a bottom 40% half-screen vterm (VSCode-style)
;;   SPC o T  — open vterm filling the current window (full-screen feel)
;;   SPC o e  — eshell (built-in, elisp-y shell)
;;
;; Inside any vterm: C-x 1 maximizes it to the whole frame; C-x 0
;; closes that window; SPC w v / w s split it.  Standard emacs window
;; commands work — the side-window rule only governs INITIAL placement,
;; not what you do after.
;;; Code:

;; Display *vterm* buffers in a bottom side-window taking 40% height.
;; The rule applies to my/vterm-toggle and any plain (vterm) call from
;; a regular buffer.  my/vterm-fullscreen below bypasses it.
(add-to-list 'display-buffer-alist
             '("\\*vterm.*\\*"
               (display-buffer-in-side-window)
               (side . bottom)
               (slot . 0)
               (window-height . 0.4)
               (window-parameters . ((no-other-window . nil)))))

(defun my/vterm-toggle ()
  "Toggle the bottom half-screen vterm.
Visible → hide.  Hidden but exists → show.  Doesn't exist → create."
  (interactive)
  (let ((buf (or (get-buffer "*vterm*")
                 (seq-find (lambda (b)
                             (string-match-p "\\`\\*vterm" (buffer-name b)))
                           (buffer-list)))))
    (cond
     ((and buf (get-buffer-window buf))
      (delete-window (get-buffer-window buf)))
     (buf
      (display-buffer buf))
     (t
      (vterm)))))

(defun my/vterm-fullscreen ()
  "Open vterm in the current window (bypasses the side-window rule).
Use C-x 1 inside to maximize across the frame, SPC w v / w s to split
side-by-side with code."
  (interactive)
  (let ((display-buffer-alist nil))
    (vterm)))

(defun my/vterm-new ()
  "Open a FRESH, independently-named vterm in the current window.
Use after `SPC \\\\' / `SPC -' to get two parallel shells, tmux-pane style."
  (interactive)
  (let ((vterm-buffer-name (generate-new-buffer-name "*vterm*"))
        (display-buffer-alist nil))
    (vterm)))

(use-package vterm
  :defer t
  :commands (vterm vterm-other-window my/vterm-toggle my/vterm-fullscreen my/vterm-new)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "o"  '(:ignore t :which-key "open")
        "ot" '(my/vterm-toggle     :which-key "vterm (half/toggle)")
        "oT" '(my/vterm-fullscreen :which-key "vterm (fullscreen)")
        "on" '(my/vterm-new        :which-key "vterm (new shell)")
        "oe" '(eshell              :which-key "eshell")))))

(provide 'config-term)
;;; config-term.el ends here
