;;; config-term.el --- Terminal (vterm) -*- lexical-binding: t; -*-
;;; Commentary:
;; Flexible terminal layout:
;;
;;   SPC o t  — toggle a bottom 40% half-screen vterm (VSCode-style)
;;   SPC o f  — toggle vterm filling the current frame
;;   SPC o d  — force-kill all vterm buffers
;;   SPC o e  — eshell (built-in, elisp-y shell)
;;
;; Inside any vterm: C-x 1 maximizes it to the whole frame; C-x 0
;; closes that window; SPC w v / w s split it.  Standard emacs window
;; commands work — the side-window rule only governs INITIAL placement,
;; not what you do after.
;;; Code:

(defvar vterm-buffer-name)

(defvar my/vterm-fullscreen-window-configuration nil
  "Window configuration saved before entering vterm fullscreen.")

(defun my/vterm-buffer-p (&optional buffer)
  "Return non-nil when BUFFER is a vterm buffer."
  (string-match-p "\\`\\*vterm" (buffer-name (or buffer (current-buffer)))))

(defun my/vterm--buffers ()
  "Return all live vterm buffers."
  (seq-filter #'my/vterm-buffer-p (buffer-list)))

(defun my/vterm--buffer ()
  "Return the primary vterm buffer, if one exists."
  (or (get-buffer "*vterm*")
      (car (my/vterm--buffers))))

(defun my/vterm--main-window ()
  "Return a non-side window in the selected frame."
  (or (seq-find (lambda (win)
                  (not (window-parameter win 'window-side)))
                (window-list nil 'no-minibuf nil))
      (selected-window)))

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
  (let ((buf (my/vterm--buffer)))
    (cond
     ((and buf (get-buffer-window buf))
       (delete-window (get-buffer-window buf)))
      (buf
       (select-window (display-buffer buf)))
      (t
       (vterm)
       (when-let ((win (get-buffer-window (my/vterm--buffer) t)))
         (select-window win))))))

(defun my/vterm-fullscreen ()
  "Toggle vterm as the only visible window in the frame.
The first call saves the current window layout, including splits.  The
next call restores that layout.  Existing vterm side windows are moved
out of the side-window layout before fullscreening."
  (interactive)
  (unless (my/vterm-buffer-p)
    (user-error "SPC o f only works from a vterm buffer"))
  (if my/vterm-fullscreen-window-configuration
      (let ((config my/vterm-fullscreen-window-configuration))
        (setq my/vterm-fullscreen-window-configuration nil)
        (set-window-configuration config))
    (let ((buf (current-buffer))
          (display-buffer-alist nil))
      (setq my/vterm-fullscreen-window-configuration
            (current-window-configuration))
      (when (buffer-live-p buf)
        (dolist (win (get-buffer-window-list buf nil t))
          (when (window-deletable-p win)
            (delete-window win))))
      (select-window (my/vterm--main-window))
      (delete-other-windows)
      (if (buffer-live-p buf)
          (switch-to-buffer buf)
        (vterm)))))

(defun my/vterm-kill-buffers ()
  "Force-kill all vterm buffers and delete their windows."
  (interactive)
  (setq my/vterm-fullscreen-window-configuration nil)
  (dolist (buf (my/vterm--buffers))
    (dolist (win (get-buffer-window-list buf nil t))
      (when (window-deletable-p win)
        (delete-window win)))
    (when (buffer-live-p buf)
      (with-current-buffer buf
        (set-buffer-modified-p nil)
        (when-let ((proc (get-buffer-process buf)))
          (set-process-query-on-exit-flag proc nil)))
      (let ((kill-buffer-query-functions nil)
            (kill-buffer-hook nil))
        (kill-buffer buf)))))

(defun my/vterm-new ()
  "Open a FRESH, independently-named vterm in the current window.
Use after `SPC \\\\' / `SPC -' to get two parallel shells, tmux-pane style."
  (interactive)
  (let ((vterm-buffer-name (generate-new-buffer-name "*vterm*"))
        (display-buffer-alist nil))
    (vterm)))

(defun my/vterm-run-command (command)
  "Open/focus vterm and run shell COMMAND."
  (interactive (list (read-shell-command "Run in vterm: ")))
  (unless (string= command "")
    (let* ((project (project-current nil))
           (default-directory
            (if project (project-root project) default-directory)))
      (my/vterm-toggle)
      (vterm-send-string command)
      (vterm-send-return))))

(use-package vterm
  :defer t
  :commands (vterm vterm-other-window my/vterm-toggle my/vterm-fullscreen my/vterm-new my/vterm-kill-buffers my/vterm-run-command)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "o"  '(:ignore t :which-key "open")
        "ot" '(my/vterm-toggle     :which-key "vterm (half/toggle)")
        "of" '(my/vterm-fullscreen :which-key "vterm (fullscreen)")
        "od" '(my/vterm-kill-buffers :which-key "vterm (kill)")
        "on" '(my/vterm-new        :which-key "vterm (new shell)")
        "oe" '(eshell              :which-key "eshell")))))

(provide 'config-term)
;;; config-term.el ends here
