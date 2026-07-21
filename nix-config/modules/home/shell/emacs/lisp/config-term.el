;;; config-term.el --- Terminal (ghostel) -*- lexical-binding: t; -*-
;;; Commentary:
;; Ghostel-backed terminal (vterm replacement, ~2× faster).
;;
;;   SPC o t  — toggle a bottom 40% half-screen ghostel (VSCode-style)
;;   SPC o f  — toggle ghostel filling the current frame
;;   SPC o d  — force-kill all ghostel buffers
;;   SPC o e  — eshell (built-in, elisp-y shell)
;;
;; Inside any ghostel: C-x 1 maximizes it to the whole frame; C-x 0
;; closes that window; SPC w v / w s split it.  Standard emacs window
;; commands work — the side-window rule only governs INITIAL placement,
;; not what you do after.
;;; Code:

(defvar ghostel-buffer-name)

(defvar my/ghostel-fullscreen-window-configuration nil
  "Window configuration saved before entering ghostel fullscreen.")

(defun my/ghostel-buffer-p (&optional buffer)
  "Return non-nil when BUFFER is a ghostel buffer."
  (string-match-p "\\`\\*ghostel" (buffer-name (or buffer (current-buffer)))))

(defun my/ghostel--buffers ()
  "Return all live ghostel buffers."
  (seq-filter #'my/ghostel-buffer-p (buffer-list)))

(defun my/ghostel--buffer ()
  "Return the primary ghostel buffer, if one exists."
  (or (get-buffer "*ghostel*")
      (car (my/ghostel--buffers))))

(defun my/ghostel--main-window ()
  "Return a non-side window in the selected frame."
  (or (seq-find (lambda (win)
                  (not (window-parameter win 'window-side)))
                (window-list nil 'no-minibuf nil))
      (selected-window)))

;; Display *ghostel* buffers in a bottom side-window taking 40% height.
;; The rule applies to my/ghostel-toggle and any plain (ghostel) call from
;; a regular buffer.  my/ghostel-fullscreen below bypasses it.
(add-to-list 'display-buffer-alist
             '("\\*ghostel.*\\*"
               (display-buffer-in-side-window)
               (side . bottom)
               (slot . 0)
               (window-height . 0.4)
               (window-parameters . ((no-other-window . nil)))))

(defun my/ghostel-toggle ()
  "Toggle the bottom half-screen ghostel.
Visible → hide.  Hidden but exists → show.  Doesn't exist → create.
Fullscreened (via `my/ghostel-fullscreen') → restore the saved layout
and hide — a bare `delete-window' would error with \"Attempt to delete
... sole ordinary window\" since fullscreen makes ghostel the only
window in the frame."
  (interactive)
  (let ((buf (my/ghostel--buffer)))
    (cond
     ((and buf (get-buffer-window buf))
      (let ((win (get-buffer-window buf)))
        (cond
         ;; Fullscreened: leave fullscreen via the saved layout, then
         ;; hide the bottom ghostel that layout brings back.
         ((and my/ghostel-fullscreen-window-configuration
               (not (window-parameter win 'window-side)))
          (let ((config my/ghostel-fullscreen-window-configuration))
            (setq my/ghostel-fullscreen-window-configuration nil)
            (set-window-configuration config))
          (when-let* ((w (get-buffer-window buf)))
            (when (window-deletable-p w) (delete-window w))))
         ;; Sole window but no saved layout (e.g. user maximized by
         ;; hand): can't delete the last window — swap the buffer out.
         ((not (window-deletable-p win))
          (switch-to-buffer (other-buffer buf)))
         (t
          (delete-window win)))))
     (buf
      (select-window (display-buffer buf)))
     (t
      (ghostel)
      (when-let ((win (get-buffer-window (my/ghostel--buffer) t)))
        (select-window win))))))

(defun my/ghostel-fullscreen ()
  "Toggle ghostel as the only visible window in the frame.
The first call saves the current window layout, including splits.  The
next call restores that layout.  Existing ghostel side windows are moved
out of the side-window layout before fullscreening."
  (interactive)
  (unless (my/ghostel-buffer-p)
    (user-error "SPC o f only works from a ghostel buffer"))
  (if my/ghostel-fullscreen-window-configuration
      (let ((config my/ghostel-fullscreen-window-configuration))
        (setq my/ghostel-fullscreen-window-configuration nil)
        (set-window-configuration config))
    (let ((buf (current-buffer))
          (display-buffer-alist nil))
      (setq my/ghostel-fullscreen-window-configuration
            (current-window-configuration))
      (when (buffer-live-p buf)
        (dolist (win (get-buffer-window-list buf nil t))
          (when (window-deletable-p win)
            (delete-window win))))
      (select-window (my/ghostel--main-window))
      (delete-other-windows)
      (if (buffer-live-p buf)
          (switch-to-buffer buf)
        (ghostel)))))

(defun my/ghostel-kill-buffers ()
  "Force-kill all ghostel buffers and delete their windows."
  (interactive)
  (setq my/ghostel-fullscreen-window-configuration nil)
  (dolist (buf (my/ghostel--buffers))
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

(defun my/ghostel-new ()
  "Open a FRESH, independently-named ghostel in the current window.
Use after `SPC \\\\' / `SPC -' to get two parallel shells, tmux-pane style."
  (interactive)
  (let ((ghostel-buffer-name (generate-new-buffer-name "*ghostel*"))
        (display-buffer-alist nil))
    (ghostel)))

(defun my/ghostel-run-command (command)
  "Open/focus ghostel and run shell COMMAND."
  (interactive (list (read-shell-command "Run in ghostel: ")))
  (unless (string= command "")
    (let* ((project (project-current nil))
           (default-directory
            (if project (project-root project) default-directory)))
      (my/ghostel-toggle)
      ;; Send the command + RET into the shell via the buffer's PTY process.
      (when-let* ((buf (my/ghostel--buffer))
                  (proc (get-buffer-process buf)))
        (process-send-string proc (concat command "\n"))))))

(use-package ghostel
  :defer t
  :commands (ghostel ghostel-project ghostel-other
             my/ghostel-toggle my/ghostel-fullscreen my/ghostel-new
             my/ghostel-kill-buffers my/ghostel-run-command)
  :init
  ;; nix derivation (emacs.nix) already installs the prebuilt module
  ;; next to ghostel.el — disable the auto-install prompt entirely.
  (setq ghostel-module-auto-install nil)
  ;; Shrink the exceptions list to shell-friendly defaults.  Upstream
  ;; ships ("C-c" "C-x" "C-u" "C-h" "M-x" "M-:" "C-\\") — those keys
  ;; are eaten by emacs instead of forwarded to the shell, which kills
  ;; muscle memory: `C-u' should clear the line, `C-c' should interrupt
  ;; the running command, `C-x' should be free for the shell.  Keep
  ;; M-x / M-: for emacs commands, C-h for help, C-\ for input methods,
  ;; and M-SPC for the leader (which is actually intercepted higher up
  ;; by general-override-mode-map; listed here for symmetry).  Set BEFORE
  ;; ghostel loads so the initial semi-char-mode-map build picks it up.
  (setq ghostel-keymap-exceptions
        '("M-x" "M-:" "C-h" "C-\\" "M-SPC"))
  ;; Note: leaving `ghostel-kitty-graphics-mediums' at its default nil
  ;; (inline base64 only).  Verified via bookokrat.log that bookokrat's
  ;; SHM probe to ghostel fails and it falls back to chunked transfer
  ;; regardless ("Kitty SHM probe failed; will use chunked transfer"),
  ;; so enabling shared-mem/file/temp-file mediums doesn't help any
  ;; current tool and just widens the SSH-medium attack surface.
  :config
  ;; Belt-and-suspenders: if the keymap was already built with the
  ;; upstream default before our :init ran (depends on use-package
  ;; load ordering with other deferred packages), rebuild it now.
  (when (fboundp 'ghostel--rebuild-semi-char-keymap)
    (ghostel--rebuild-semi-char-keymap))
  ;; evil integration — done by evil-ghostel below, not via forcing
  ;; emacs-state.  See the `use-package evil-ghostel' block after this
  ;; one for the full rationale.
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "o"  '(:ignore t :which-key "open")
        "ot" '(my/ghostel-toggle     :which-key "ghostel (half/toggle)")
        "of" '(my/ghostel-fullscreen :which-key "ghostel (fullscreen)")
        "od" '(my/ghostel-kill-buffers :which-key "ghostel (kill)")
        "on" '(my/ghostel-new        :which-key "ghostel (new shell)")
        "oe" '(eshell                :which-key "eshell")))))

;; evil-ghostel — proper evil integration in ghostel buffers.  Without
;; it, evil's emulation maps eat readline-style Ctrl keys before
;; ghostel can forward them: `.' triggers evil-repeat (empty register
;; error), `C-k' triggers digraph insertion, `C-u'/`C-d' trigger evil
;; scrolling.  vterm only "just worked" because its mode forced
;; emacs-state; ghostel deliberately leaves modal state alone.
;;
;; What evil-ghostel-mode does inside ghostel buffers:
;;   - keeps you in evil-insert state so the prompt feels modal
;;   - rewires C-a/d/e/k/n/p/r/t/u/w/y to send to the terminal PTY
;;     instead of evil's insert-state defaults (gets readline back)
;;   - advises evil-undo to send readline C-_ instead of buffer undo
;;   - smart ESC routing: alt-screen TUIs (less, fzf, vim, claude code)
;;     receive ESC; bare shell prompt drops to evil-normal so you can
;;     hjkl / search / yank the scrollback, then `i'/`a' back into the
;;     live prompt — terminal cursor and emacs point stay synced
;;     across the transition (`evil-ghostel-escape' = 'auto)
;;
;; Installed source-only from upstream extensions/ — see emacs.nix
;; postInstall.  No byte-compile during nix build (would need evil in
;; the build sandbox); natively compiled on first load.
(use-package evil-ghostel
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode)
  :config
  ;; ghostel reserves `C-c' as a prefix (`C-c C-c' -> SIGINT,
  ;; `C-c C-l' -> line-mode, `C-c C-z' -> SIGTSTP, `C-c C-d' -> EOF,
  ;; etc.) the way `comint-mode' does.  In evil-insert state inside a
  ;; shell prompt, though, plain `C-c' should interrupt the foreground
  ;; command like a real terminal — the prefix commands stay reachable
  ;; from other states or via `M-x'.  Layer a direct `ghostel-send-C-c'
  ;; on top of evil-ghostel's insert-state aux map.  Scoped to the aux
  ;; map so it only affects insert-state, leaving ghostel-mode-map's
  ;; `C-c' prefix intact everywhere else.
  (evil-define-key* 'insert evil-ghostel-mode-map
                    (kbd "C-c") #'ghostel-send-C-c))

(provide 'config-term)
;;; config-term.el ends here
