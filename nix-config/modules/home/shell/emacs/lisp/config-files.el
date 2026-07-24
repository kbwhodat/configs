;;; config-files.el --- Oil/netrw-style bottom-popup dired -*- lexical-binding: t; -*-
;;; Commentary:
;; `-' from any buffer → bottom 40% dired popup of file's dir.
;; `-' in dired → up one.  RET on dir → navigate.  RET on file →
;; open in source window + close popup.  `/' = vim search (evil).
;;; Code:

;; Route dired buffers to a bottom 40% side window.  Match by mode
;; (dired buffer names are the directory path, not `*Dired*').
(add-to-list 'display-buffer-alist
             '((lambda (buf _action)
                 (with-current-buffer buf
                   (derived-mode-p 'dired-mode)))
               (display-buffer-in-side-window)
               (side . bottom)
               (slot . 0)
               (window-height . 0.4)
               (window-parameters . ((no-other-window . nil)))))

(defvar my/dired-popup-source-window nil
  "Window that triggered the dired popup — RET on a file opens there.")

(defun my/dired-jump-or-up ()
  "`-' from a buffer: pop dired; from dired: go up."
  (interactive)
  (cond
   ((derived-mode-p 'dired-mode) (dired-up-directory))
   (t (setq my/dired-popup-source-window (selected-window))
      (dired-jump))))

(defun my/dired-find-file-routing ()
  "RET: dir → navigate in popup; file → open in source window + close popup."
  (interactive)
  (let ((file (ignore-errors (dired-get-file-for-visit))))
    (cond
     ((and file (file-directory-p file)) (dired-find-file))
     (file
      (let* ((dired-win (selected-window))
             (source (and (window-live-p my/dired-popup-source-window)
                          (not (eq my/dired-popup-source-window dired-win))
                          (not (window-parameter
                                my/dired-popup-source-window 'window-side))
                          my/dired-popup-source-window))
             (target (or source
                         (seq-find (lambda (w)
                                     (and (not (eq w dired-win))
                                          (not (window-parameter w 'window-side))))
                                   (window-list)))))
        (if target (progn (select-window target) (find-file file))
          (find-file file))
        (when (and (window-live-p dired-win)
                   (window-parameter dired-win 'window-side))
          (delete-window dired-win))
        (setq my/dired-popup-source-window nil)))
     (t (dired-find-file)))))

(with-eval-after-load 'evil
  (define-key evil-normal-state-map (kbd "-") #'my/dired-jump-or-up)
  (define-key evil-motion-state-map (kbd "-") #'my/dired-jump-or-up))

(defun my/dired-create-file (filename)
  "Touch a new empty FILENAME in the current dired dir (netrw-style `%')."
  (interactive "sNew file name: ")
  (let ((path (expand-file-name filename (dired-current-directory))))
    (when (file-exists-p path) (user-error "File already exists: %s" path))
    (with-temp-file path)
    (revert-buffer)
    (dired-goto-file path)))

(defun my/dired-close-popup ()
  "Close the dired side window (or quit-window if not one)."
  (interactive)
  (if (window-parameter (selected-window) 'window-side)
      (delete-window) (quit-window)))

;; netrw/oil keymap inside dired buffers — no need to learn dired defaults.
;; Named function so it can be applied TWICE: once when dired loads,
;; and again after evil-collection sets up its dired bindings —
;; evil-collection initializes on an idle timer AFTER our
;; with-eval-after-load registration, so its bindings land later and
;; were clobbering ours (observed: RET reverted to stock
;; `dired-find-file', opening files INSIDE the popup instead of
;; routing them to the main window).
(defun my/dired-evil-keys ()
  "Apply the netrw-style dired keymap (idempotent)."
  (define-key dired-mode-map (kbd "RET") #'my/dired-find-file-routing)
  (with-eval-after-load 'evil
    (evil-define-key 'normal dired-mode-map
      (kbd "RET") #'my/dired-find-file-routing
      (kbd "l")   #'my/dired-find-file-routing
      (kbd "-")   #'my/dired-jump-or-up
      (kbd "h")   #'my/dired-jump-or-up
      (kbd "R")   #'dired-do-rename
      (kbd "D")   #'dired-do-delete
      (kbd "c")   #'dired-do-copy
      (kbd "+")   #'dired-create-directory
      (kbd "d")   #'dired-create-directory     ; netrw mkdir
      (kbd "%")   #'my/dired-create-file       ; netrw new file
      (kbd "gh")  #'dired-hide-dotfiles
      (kbd "gr")  #'revert-buffer
      (kbd "gs")  #'dired-sort-toggle-or-edit
      (kbd "t")   #'my/ghostel-cd-here        ; terminal in THIS dir (shadows toggle-marks)
      (kbd "q")   #'my/dired-close-popup
      (kbd "?")   #'describe-mode)))

(with-eval-after-load 'dired
  (my/dired-evil-keys))

;; Re-assert after evil-collection's dired setup (it runs later and
;; would otherwise win the last-write race).
(with-eval-after-load 'evil-collection
  (add-hook 'evil-collection-setup-hook
            (lambda (mode &rest _)
              (when (eq mode 'dired)
                (my/dired-evil-keys)))))

;; `dired-hide-dotfiles' = alias for dired-x's `dired-omit-mode'.
(with-eval-after-load 'dired
  (require 'dired-x)
  (setq dired-omit-files "\\`[.][^.]")
  (defalias 'dired-hide-dotfiles #'dired-omit-mode))

(provide 'config-files)
;;; config-files.el ends here
