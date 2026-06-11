;;; config-files.el --- Oil/netrw-style bottom-popup dired -*- lexical-binding: t; -*-
;;; Commentary:
;; Minimal file-manager UX layered on plain dired — no new package,
;; no wdired wiring.  Behaviour:
;;
;;   "-" from any buffer  → bottom 40% dired popup of current file's dir
;;   "-" in dired         → go up one directory (stays in the popup)
;;   "RET" on a directory → navigate in (stays in the popup)
;;   "RET" on a file      → open in the main window + close the popup
;;   "/" inside dired     → evil's normal search (vim incremental search)
;;
;; Matches oil.nvim / netrw muscle memory: `-' is the universal "show me
;; this folder" trigger, file selection commits and tears down the popup.
;;; Code:

;; --- Bottom-popup placement for ANY dired buffer ------------------
;; Routes every dired buffer (matched by major mode, NOT by name —
;; dired buffers are named after the directory path like `/Users/katob/'
;; rather than `*Dired*', so a name regex misses them) to a side window
;; at the bottom occupying 40% of frame height.  Same slot ghostel
;; uses; `no-other-window nil' so window-cycling still visits dired.
(add-to-list 'display-buffer-alist
             '((lambda (buf _action)
                 (with-current-buffer buf
                   (derived-mode-p 'dired-mode)))
               (display-buffer-in-side-window)
               (side . bottom)
               (slot . 0)
               (window-height . 0.4)
               (window-parameters . ((no-other-window . nil)))))

;; --- "-" opens dired-jump / goes up ----------------------------
(defun my/dired-jump-or-up ()
  "From any buffer: pop bottom dired for current file's directory.
From dired itself: navigate one directory up."
  (interactive)
  (if (derived-mode-p 'dired-mode)
      (dired-up-directory)
    (dired-jump)))

;; --- RET handler: route files to main window, close popup -------
;; Default `dired-find-file' reuses the current window — when that
;; window is the bottom side popup, the file would either get jammed
;; into a side window (emacs may refuse) or replace dired in place
;; (leaving the popup open with the new buffer).  Neither matches oil.
;; This wrapper:
;;   - directories: hand off to `dired-find-file' (popup stays, navigates in)
;;   - files from the side popup: find a non-side window, open file there,
;;     close the popup
;;   - files from a non-side window (rare): normal `dired-find-file'
(defun my/dired-find-file-routing ()
  "RET in dired: directories navigate in place, files open + close popup."
  (interactive)
  (let ((file (ignore-errors (dired-get-file-for-visit))))
    (cond
     ((and file (file-directory-p file))
      (dired-find-file))
     ((and file (window-parameter (selected-window) 'window-side))
      (let* ((dired-win (selected-window))
             (target (seq-find (lambda (w)
                                 (not (window-parameter w 'window-side)))
                               (window-list))))
        (if target
            (progn (select-window target) (find-file file))
          (find-file file))
        (when (and (window-live-p dired-win)
                   (window-parameter dired-win 'window-side))
          (delete-window dired-win))))
     (t (dired-find-file)))))

;; --- Global "-" binding (oil/netrw signature) --------------------
(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "-") #'my/dired-jump-or-up)
  (define-key evil-motion-state-map (kbd "-") #'my/dired-jump-or-up))

;; --- Helpers used by the netrw/oil keymap below -------------------
(defun my/dired-create-file (filename)
  "Touch a new empty FILENAME inside the current dired directory.
Mirrors netrw's `%' (new-file) prompt without entering wdired."
  (interactive "sNew file name: ")
  (let ((path (expand-file-name filename (dired-current-directory))))
    (when (file-exists-p path)
      (user-error "File already exists: %s" path))
    (with-temp-file path)
    (revert-buffer)
    (dired-goto-file path)))

(defun my/dired-close-popup ()
  "Close the dired side window, or quit the buffer if it isn't one."
  (interactive)
  (if (window-parameter (selected-window) 'window-side)
      (delete-window)
    (quit-window)))

;; --- Dired-buffer-local bindings (netrw + oil muscle memory) ------
;; Designed so you NEVER need to remember a dired default.  Each row
;; below maps a netrw or oil key to its dired equivalent.
;;
;;   key   action                  source
;;   ---   ----------------------  ----------------
;;   RET   open (close popup)      oil / netrw
;;   l     open                    oil
;;   -     up one dir              oil / netrw
;;   h     up one dir              oil
;;   R     rename                  netrw
;;   D     delete                  netrw
;;   c     copy                    convention
;;   +     mkdir                   dired default (intuitive "add")
;;   %     new file                netrw
;;   gh    toggle hidden           netrw
;;   gr    refresh                 oil
;;   gs    cycle sort              oil
;;   q     close popup             oil
;;   ?     help (which-key)        oil/netrw `g?'
(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd "RET") #'my/dired-find-file-routing)
  (with-eval-after-load 'evil
    (evil-define-key 'normal dired-mode-map
      ;; --- Navigation ---
      (kbd "RET") #'my/dired-find-file-routing
      (kbd "l")   #'my/dired-find-file-routing
      (kbd "-")   #'my/dired-jump-or-up
      (kbd "h")   #'my/dired-jump-or-up
      ;; --- File ops ---
      (kbd "R")   #'dired-do-rename            ; rename/move
      (kbd "D")   #'dired-do-delete            ; delete
      (kbd "c")   #'dired-do-copy              ; copy
      (kbd "+")   #'dired-create-directory     ; mkdir
      (kbd "d")   #'dired-create-directory     ; mkdir (netrw style)
      (kbd "%")   #'my/dired-create-file       ; new file (netrw style)
      ;; --- Toggles / display ---
      (kbd "gh")  #'dired-hide-dotfiles        ; netrw-style toggle
      (kbd "gr")  #'revert-buffer              ; refresh
      (kbd "gs")  #'dired-sort-toggle-or-edit  ; cycle sort
      ;; --- Misc ---
      (kbd "q")   #'my/dired-close-popup
      (kbd "?")   #'describe-mode)))           ; full dired help via which-key

;; `dired-hide-dotfiles' isn't built-in — use the toggle from
;; `dired-x' (ships with emacs) which hides files matching
;; `dired-omit-files'.  Set the pattern to dotfiles and toggle via
;; `dired-omit-mode'.
(with-eval-after-load 'dired
  (require 'dired-x)
  (setq dired-omit-files "\\`[.][^.]")  ; everything starting with `.' except `..'
  (defalias 'dired-hide-dotfiles #'dired-omit-mode))

(provide 'config-files)
;;; config-files.el ends here
