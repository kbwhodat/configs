;; ~/.emacs.d/init.el

(setq-default
 mode-line-format
 '((:eval
    (concat
     (if (buffer-modified-p)
         ;; unsaved: filled dot, bold buffer name
         (concat
          (propertize "   ● " 'face '(:foreground "#ffffff" :weight bold))
          (propertize "%b" 'face '(:foreground "#ffffff" :weight bold)))
       ;; saved: hollow dot, regular weight
       (concat
        (propertize "   ○ " 'face '(:weight bold))
        (propertize "%b" 'face '(:weight bold))))))))

(require 'doom-themes)

;; Remove messages from the *Messages* buffer.
(setq-default message-log-max nil)

;; Kill both buffers on startup.
(kill-buffer "*Messages*")
(kill-buffer "*scratch*")

(defun buffer-change-hook (frame)
  (unless
      (seq-every-p
       (lambda (elt) (string-match "^ *\\*" (buffer-name elt)))
       (buffer-list))
    (kill-buffer "*scratch*")))

(set-face-attribute 'default nil
  :family "ComicShannsMono Nerd Font Mono"
  :height 135)

;; point Emacs to the folder Home-Manager created
(add-to-list 'custom-theme-load-path
             (expand-file-name "themes/doom-alabaster-theme" user-emacs-directory))

;; load the Doom-style theme (its symbol name is doom-alabaster)
(load-theme 'doom-alabaster t)

;; Evil
(setq evil-want-C-u-scroll t
      evil-want-C-i-jump t
      evil-want-keybinding nil
      evil-undo-system 'undo-redo)
(require 'evil)
(evil-mode 1)
(setq evil-normal-state-cursor '(box . 1)
      evil-insert-state-cursor '(bar . 1)
      evil-visual-state-cursor '(hollow . 1))

;; Evil-collection
(run-with-idle-timer
  0.5 nil
  (lambda ()
    (when (require 'evil-collection nil t)
      (evil-collection-init))))

;; which-key
(when (require 'which-key nil t)
  (which-key-mode 1))

;; Leader with general
(when (require 'general nil t)
  (general-create-definer my/leader
    :states '(normal visual motion)
    :keymaps 'override 
    :prefix "SPC" :non-normal-prefix "M-SPC")
  (my/leader
    "f"  '(:ignore t :which-key "files")
    "ff" '(find-file :which-key "find file")
    "fs" '(save-buffer :which-key "save")
    "b"  '(:ignore t :which-key "buffers")
    "bb" '(switch-to-buffer :which-key "switch")
    "bd" '(kill-this-buffer :which-key "kill")
    "w"  '(:ignore t :which-key "windows")
    "wv" '(split-window-right :which-key "vsplit")
    "ws" '(split-window-below :which-key "hsplit")
    "wd" '(delete-window :which-key "close")
    "q"  '(save-buffers-kill-terminal :which-key "quit")))

;; Surround: ysiw"  ds"  cs"'
(when (require 'evil-surround nil t)
  (global-evil-surround-mode 1))

;; Markdown-specific evil motions/text-objects
(when (require 'evil-markdown nil t)
  (add-hook 'markdown-mode-hook #'evil-markdown-mode))

;; Comment: gc / gcc
(when (require 'evil-nerd-commenter nil t)
  (define-key evil-normal-state-map "gc" #'evilnc-comment-operator)
  (define-key evil-visual-state-map "gc"  #'evilnc-comment-operator))
  ; (define-key evil-normal-state-map "gcc" #'evilnc-comment-or-uncomment-lines))

;; Matchit: % jumps across pairs/tags/blocks
(when (require 'evil-matchit nil t)
  (global-evil-matchit-mode 1))

;; Args text-objects: daa / cia / via
(when (require 'evil-args nil t)
  (define-key evil-inner-text-objects-map "a" #'evil-inner-arg)
  (define-key evil-outer-text-objects-map "a" #'evil-outer-arg))

;; Easymotion-style jumps: gs w / gs l / gs s
(when (require 'evil-easymotion nil t)
  (evilem-default-keybindings "gs"))

;; Avy quick-jumps (add a few handy bindings under your leader)
(when (require 'avy nil t)
  (when (fboundp 'my/leader)
    (my/leader
      "j"  '(:ignore t :which-key "jump")
      "jw" '(avy-goto-word-1   :which-key "word")
      "jl" '(avy-goto-line     :which-key "line")
      "jc" '(avy-goto-char-timer :which-key "char"))))

(when (require 'anzu nil t)
  (global-anzu-mode 1))

;; Stable undo like Doom (optional; if you prefer this over Emacs’ built-in undo)
(when (require 'undo-fu nil t)
  (setq evil-undo-system 'undo-fu)
  (when (require 'undo-fu-session nil t)
    (when (fboundp 'global-undo-fu-session-mode)
      (global-undo-fu-session-mode 1))))

(defun my/notdeft-display-filename-only (file)
  "Display just the base filename for FILE in NotDeft list."
  (file-name-base file))

;; --- NotDeft: fast note search / Zettelkasten-style viewer ---
(autoload 'deft "deft" nil t)
(with-eval-after-load 'deft
  (setq deft-directory "~/vault"        
        deft-extensions '("md")   
        deft-recursive t         
        deft-filter-only-filenames nil 
        deft-use-filename-as-title t
        deft-file-naming-rules
        '((noslash . "-")
          (nospace . "-"))))

(when (fboundp 'my/leader)
  (my/leader
    "ns" '(deft  :which-key "search")))

;;; --- Minimal completion/search (lightweight, Doom-like flow) ---
;; Vertico completion UI
(when (require 'vertico nil t) (vertico-mode 1))
;; Keep minibuffer history
(when (require 'savehist nil t) (savehist-mode 1))
;; Orderless matching
(when (require 'orderless nil t)
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles basic partial-completion)))))
;; Extra annotations in M-x etc.
(when (require 'marginalia nil t) (marginalia-mode 1))
;; Consult: ripgrep, line search, buffers, etc. (bind under your leader)
(when (require 'consult nil t)
  (when (fboundp 'my/leader)
    (my/leader
      "s"  '(:ignore t :which-key "search")
      "ss" '(consult-line :which-key "in-buffer")
      "sg" '(consult-ripgrep :which-key "ripgrep")
      "sb" '(consult-buffer :which-key "buffers")))
  ;; project.el integration (project-find-file, consult-ripgrep in project)
  (with-eval-after-load 'project
    (when (fboundp 'my/leader)
      (my/leader
        "p"  '(:ignore t :which-key "project")
        "pp" '(project-switch-project :which-key "switch")
        "pf" '(project-find-file     :which-key "find file")
        "pb" '(consult-project-buffer :which-key "buffers")
        "ps" '(consult-ripgrep       :which-key "ripgrep")))))


(with-eval-after-load 'markdown-mode
  ;; --- behavior/tweaks ---
  (setq markdown-fontify-code-blocks-natively nil
        markdown-hide-markup nil
        markdown-list-item-bullets (make-list 6 "-")
        markdown-header-scaling nil)

  ;; --- faces (vanilla replacement for custom-set-faces!) ---
  ;; use the 'user theme so this works regardless of your theme package
  (custom-theme-set-faces
   'user
   ;; text styles
   '(markdown-bold-face             ((t (:inherit default :weight bold :foreground unspecified))))
   '(markdown-italic-face           ((t (:inherit default :slant italic :foreground unspecified))))
   ;; headers (no scaling, just bold)
   '(markdown-header-face           ((t (:inherit default :weight bold :height 1.35))))
   '(markdown-header-face-1         ((t (:inherit default :weight bold :height 1.25))))
   '(markdown-header-face-2         ((t (:inherit default :weight bold :height 1.15))))
   '(markdown-header-face-3         ((t (:inherit default :weight bold :height 1.10))))
   '(markdown-header-face-4         ((t (:inherit default :weight bold :height 1.05))))
   ;; code & inline code: no special bg/fg
   '(markdown-code-face             ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-inline-code-face      ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-language-keyword-face ((t (:inherit default :foreground unspecified :background unspecified))))
   ;; misc
   '(markdown-metadata-key-face     ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-line-break-face       ((t (:inherit default :foreground unspecified :background unspecified))))
   '(markdown-blockquote-face       ((t (:inherit default))))
   '(markdown-header-delimiter-face ((t (:inherit default :weight bold :foreground unspecified :background unspecified))))
   '(markdown-markup-face           ((t (:inherit default))))
   '(hl-line                        ((t (:inherit default :foreground unspecified :background unspecified))))))  ; neutralize hl-line in md buffers

;;; --- Workspaces & session persistence (persp-mode) ---
;; Directory to store sessions, e.g. ~/.emacs.d/persp-sessions/
(defconst my/persp-save-dir
  (expand-file-name "persp-sessions/" user-emacs-directory))

(unless (file-directory-p my/persp-save-dir)
  (make-directory my/persp-save-dir t))

;; Match your Doom settings
(setq persp-autosave-fname "autosave"                 ; session filename
      persp-save-dir my/persp-save-dir                ; where to save
      persp-autosave-default t)                        ; autosave on exit
      

(require 'persp-mode)
(setq persp-auto-resume-time -1)
(persp-mode 1)

;; Restore the last session on startup (if it exists)
(let ((autosave-file (expand-file-name persp-autosave-fname persp-save-dir)))
  (when (file-readable-p autosave-file)
    (ignore-errors
      (persp-load-state-from-file autosave-file))))

;; Save session when Emacs exits
(add-hook 'kill-emacs-hook
          (lambda ()
            (ignore-errors
              (persp-save-state-to-file
               (expand-file-name persp-autosave-fname persp-save-dir)))))

(auto-save-visited-mode -1)

(require 'markup)

(require 'minions)
(minions-mode 1)

(setq browse-url-browser-function 'browse-url-generic
      browse-url-generic-program "/etc/profiles/per-user/katob/bin/firefox")

(defun my/new-markdown-note (title)
  "Create a new Markdown note with TITLE."
  (interactive "sNote title: ")
  (let* ((dir  (expand-file-name "~/vault/"))
         (slug (replace-regexp-in-string "[^[:alnum:]-]+" "-" (downcase title)))
         (file (expand-file-name (concat slug ".md") dir))
         (new? (not (file-exists-p file))))
    (unless (file-directory-p dir)
      (make-directory dir t))
    (find-file file)
    (when new?
      (insert (my/markdown-template title slug))
      (save-buffer))))

(defun my/markdown-template (title slug)
  "Return default Markdown template using TITLE and SLUG."
  (let ((uid (format "%d-%s"
                     (random (expt 10 10))
                     (substring (md5 (number-to-string (float-time))) 0 4))))
    (format
     "---\nid: %s\naliases:\n  - %s\ntags: []\ndate: %s\nuid: %s\n---\n\n# %s\n\n"
     slug title (format-time-string "%Y-%m-%d") uid title)))

;; --- normal-state g x / g X to follow markdown links ---
(with-eval-after-load 'evil
  ;; bind globally (works best inside markdown buffers)
  (evil-define-key 'normal 'global (kbd "g x") #'markdown-follow-link-at-point)
  (evil-define-key 'normal 'global (kbd "g X") #'markdown-follow-link-at-point))

;; --- Leader bindings (SPC …) ---
(with-eval-after-load 'general
  (when (fboundp 'my/leader)
    ;; Notes/search: prefer NotDeft if present, else Deft if installed
    ;; New plain markdown note (your function)
    (when (fboundp 'my/new-markdown-note)
      (my/leader
        "n n" '(my/new-markdown-note :which-key "new markdown note")))

    ;; Delete current buffer
    (my/leader
      "d"  '(kill-current-buffer :which-key "kill buffer"))

    ;; Window moves (h/j/k/l)
    (my/leader
      "h" '(windmove-left  :which-key "← window")
      "j" '(windmove-down  :which-key "↓ window")
      "k" '(windmove-up    :which-key "↑ window")
      "l" '(windmove-right :which-key "→ window"))

    ;; Previous/Next buffer on ; and '
    (my/leader
      ";" '(previous-buffer :which-key "prev buffer")
      "'" '(next-buffer     :which-key "next buffer"))))


(with-eval-after-load 'deft
  ;; store Deft window
  (defvar my/deft-window nil
    "Window showing the *Deft* buffer.")

  (add-hook 'deft-mode-hook
            (lambda ()
              (setq my/deft-window (selected-window))))

  (defun my/deft-open-and-close ()
    "Open the file at point, then close the Deft buffer/window."
    (interactive)
    (let ((file (deft-filename-at-point)))
      (unless file
        (user-error "No file at point"))
      ;; open the note first
      (deft-open-file file)
      ;; then clean up Deft window/buffer
      (let ((buf (get-buffer "*Deft*")))
        (when buf
          (when-let ((win (get-buffer-window buf t)))
            (when (window-live-p win)
              (if (one-window-p)
                  (kill-buffer buf)  ; if it's the only window
                (delete-window win)))) ; otherwise just close the window
          ;; ensure the buffer is gone either way
          (when (buffer-live-p buf)
            (kill-buffer buf))))))

  ;; rebind RET and <return> in Deft buffers
  (define-key deft-mode-map (kbd "RET") #'my/deft-open-and-close)
  (define-key deft-mode-map (kbd "<return>") #'my/deft-open-and-close))

(require 'persistent-scratch)
(setq persistent-scratch-save-file
      (expand-file-name "scratch-pad.el" user-emacs-directory))
(persistent-scratch-setup-default)
(persistent-scratch-autosave-mode 1)

(add-hook 'kill-buffer-query-functions
          (lambda ()
            (if (string= (buffer-name) "*scratch*")
                (progn
                  (persistent-scratch-save)
                  (bury-buffer)
                  (ignore-errors (delete-window))
                  nil) ; stop kill
              t))) ; allow normal kills

(defun my/open-persistent-scratch ()
  (interactive) (pop-to-buffer "*scratch*"))

(when (fboundp 'my/leader)
  (my/leader "x" '(my/open-persistent-scratch :which-key "scratch")))

(when (fboundp 'my/leader)
  (my/leader "m" '(markdown-toggle-markup-hiding :which-key "toggle markup")))


;; Keep GUI customizations separate
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file) (load custom-file))

(provide 'init)
