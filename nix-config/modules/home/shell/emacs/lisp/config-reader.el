;;; config-reader.el --- EPUB / long-form reading -*- lexical-binding: t; -*-
;;; Commentary:
;; nov.el = native EPUB reader for emacs.  Renders via `shr' (the
;; built-in HTML engine, also used by eww and notmuch) and emacs's
;; native image system — no kitty graphics protocol involved, so it
;; works correctly in any frame including ghostel without the
;; multi-image coalesce bug that bookokrat hits.
;;
;; olivetti-mode centres prose at a comfortable column width.
;; visual-line-mode word-wraps long paragraphs at the window edge so
;; you read by visual line rather than buffer line.
;;
;; Bindings:
;;   .epub file  → opens in nov-mode automatically (auto-mode-alist)
;;   SPC o b     → prompt for an EPUB file under ~/Documents/books/
;;
;; Inside an EPUB buffer:
;;   n / p       next / previous chapter
;;   t           table of contents
;;   g           refresh
;;   SPC / DEL   scroll forward / backward
;;   C-x r m     bookmark this location (standard emacs bookmark)
;;; Code:

(use-package nov
  :mode ("\\.epub\\'" . nov-mode)
  :init
  ;; Cache extracted EPUB content under XDG cache so the unzip step
  ;; doesn't repeat on every open of the same book.
  (setq nov-save-place-file
        (expand-file-name "nov-places" user-emacs-directory))
  :config
  ;; Comfortable defaults — adjust to taste.  nov-text-width is the
  ;; source-side wrap; olivetti-body-width below controls the visual
  ;; column width on screen.  Both need to be roomy for the text to
  ;; actually be wide — if either is tight, the narrower one wins.
  ;; `t' = don't soft-wrap the source at all — let visual-line-mode +
  ;; olivetti's window-relative width do all the wrapping at display
  ;; time.  A small integer here would force a narrow column even if
  ;; the window is wide.
  (setq nov-text-width t
        nov-variable-pitch t               ; render prose in a proportional font
        nov-render-html-function 'nov-render-html))

(use-package olivetti
  :defer t
  :commands olivetti-mode
  :init
  ;; Fractional width (0.0-1.0) = % of window — scales with whatever
  ;; window size you give it.  0.92 = 92% of window width, leaving a
  ;; small breathing margin on each side; on a typical 200-col window
  ;; that's ~184 cols of content.  An integer here would cap content
  ;; at that many columns regardless of window size, which is why
  ;; "160" looked like half on a wide monitor.
  (setq olivetti-body-width 0.92
        olivetti-minimum-body-width 100
        olivetti-recall-visual-line-mode-entry-state t))

;; --- nov + olivetti integration -------------------------------------
;; When opening an EPUB, automatically centre with olivetti and
;; word-wrap with visual-line-mode.  Both are buffer-local so they
;; don't leak into other buffers.
(defun my/nov-reading-setup ()
  "Configure an EPUB buffer for long-form prose reading."
  (visual-line-mode 1)
  (olivetti-mode 1)
  ;; nov sets buffer-read-only; cursor type matters less.  Hide the
  ;; cursor entirely for distraction-free reading — `n'/`p' scrolling
  ;; doesn't need cursor visibility.
  (setq-local cursor-type nil))
(add-hook 'nov-mode-hook #'my/nov-reading-setup)

;; --- Leader binding -------------------------------------------------
;; `SPC o b' — pick an EPUB from your books library.  Adjust the
;; default path to wherever you keep ebooks.
(defcustom my/nov-library-dir
  (expand-file-name "Documents/books" (getenv "HOME"))
  "Directory containing your EPUB library.  Used by the `SPC o b'
quick-open binding to scope the file picker."
  :type 'directory
  :group 'nov)

(defun my/nov-open-from-library ()
  "Prompt for an EPUB under `my/nov-library-dir'."
  (interactive)
  (let ((default-directory
         (if (file-directory-p my/nov-library-dir)
             my/nov-library-dir
           default-directory)))
    (call-interactively #'find-file)))

(with-eval-after-load 'general
  (when (fboundp 'my/leader)
    (my/leader
      "o b" '(my/nov-open-from-library :which-key "open EPUB (books)"))))

(provide 'config-reader)
;;; config-reader.el ends here
