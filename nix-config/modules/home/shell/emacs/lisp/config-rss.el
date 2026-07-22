;;; config-rss.el --- Elfeed: extraction-first RSS reading -*- lexical-binding: t; -*-
;;; Commentary:
;; Newsify-style reading: opening an entry shows the FULL extracted
;; article with inline images — not the feed's excerpt.  Extraction is
;; pure elisp (eww's readability scoring over libxml DOM; the external
;; extractor rdrview is linux-only in nixpkgs), runs asynchronously
;; after the excerpt renders, and the result is CACHED in the elfeed
;; db: each article is fetched and extracted once, ever.
;; Feeds live in elfeed.org (converted from the old newsboat urls;
;; query-feeds became search filters, e.g. `s +database').
;;; Code:

(use-package elfeed
  :defer t
  :commands (elfeed)
  :init
  (setq elfeed-search-filter "@2-weeks-ago +unread"
        elfeed-db-directory (expand-file-name "elfeed-db" user-emacs-directory))
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader "or" '(elfeed :which-key "rss (elfeed)"))))
  :config
  ;; Kick a feed refresh when opening elfeed with a stale db.
  (advice-add 'elfeed :after #'my/elfeed--maybe-update)
  ;; Extraction-first: after an entry buffer is shown, upgrade it.
  (advice-add 'elfeed-show-entry :after #'my/elfeed--fulltext-maybe))

;; elfeed-org drags in org, whose default `org-modules' load a museum
;; of link integrations (gnus/irc/bbdb/rmail...).  In our mixed-org
;; setup (ELPA org from the elfeed-org dependency + emacs 31 built-in)
;; ol-gnus fails to load and warns "Problems while trying to load
;; feature 'ol-gnus'".  We use org solely as elfeed's feed-list format
;; — load no optional modules at all.  Must be set BEFORE org loads.
(setq org-modules nil)

(use-package elfeed-org
  :after elfeed
  :config
  (setq rmh-elfeed-org-files
        (list (expand-file-name "elfeed.org" user-emacs-directory)))
  (elfeed-org))

;; Medium-style reading column, DETERMINISTIC.  Two layers:
;;   1. `shr-width' pinned buffer-locally to a fixed 80 columns — shr
;;      hard-wraps the article at 80 no matter which window (or NO
;;      window: the async fulltext upgrade re-renders in the
;;      background) is current at render time.  Without this, shr
;;      picked up whatever width surrounded the render and produced
;;      over-wide lines that re-wrapped raggedly — the unreadable
;;      mess.  elfeed only reads shr-width (url truncation), never
;;      binds it, so the buffer-local value always wins.
;;   2. olivetti at a slightly wider fixed body centers that column
;;      with even margins in any window size.
(defun my/elfeed-reading-setup ()
  "Fixed centered prose column for elfeed article buffers."
  (setq-local shr-width 80
              shr-max-width 80
              shr-max-image-proportion 0.9
              line-spacing 0.15
              olivetti-body-width 86)
  (visual-line-mode 1)
  (olivetti-mode 1)
  ;; Register the article buffer with the current workspace: persp only
  ;; auto-adds on find-file, so *elfeed-entry* was invisible to
  ;; SPC ; cycling and SPC b b — no buffer-picker road back to a
  ;; half-read article while note-taking.
  (when (and (bound-and-true-p persp-mode)
             (fboundp 'persp-add-buffer)
             (get-current-persp))
    (ignore-errors (persp-add-buffer (current-buffer) (get-current-persp) nil))))
(add-hook 'elfeed-show-mode-hook #'my/elfeed-reading-setup)

;; Crash-safety for the db index: elfeed only saves on kill-emacs and
;; on quitting the search buffer — an abrupt daemon kill (terminal
;; rebuild's kickstart, crash) would lose that session's read-states/
;; stars.  (Cached article CONTENT is safe regardless: refs hit disk
;; immediately.)  Save on long idle, only when the db is loaded.
(run-with-idle-timer
 120 t (lambda ()
         (when (and (featurep 'elfeed) elfeed-db)
           (ignore-errors (elfeed-db-save)))))

(defvar my/elfeed-update-interval (* 4 60 60)
  "Refresh feeds when the db is older than this many seconds.")

(defun my/elfeed--maybe-update (&rest _)
  "Update feeds if the last update is older than the interval."
  (when (> (- (float-time) (elfeed-db-last-update)) my/elfeed-update-interval)
    (elfeed-update)))

;; --- Full-text extraction (pure elisp) ------------------------------

(defun my/elfeed--extract-readable (html base-url)
  "Return readability-extracted article HTML from HTML string, or nil.
Parses with libxml, scores the DOM with eww's readability engine, and
serializes the best subtree back to HTML (relative link/image URLs
resolve against BASE-URL via the libxml base argument)."
  (require 'eww)
  (when (and html (fboundp 'libxml-parse-html-region))
    (with-temp-buffer
      (insert html)
      (let ((dom (libxml-parse-html-region (point-min) (point-max) base-url)))
        (when dom
          (eww-score-readability dom)
          (let ((best (eww-highest-readability dom)))
            (when best
              (cond
               ((fboundp 'shr-dom-print)
                (with-temp-buffer (shr-dom-print best) (buffer-string)))
               ((fboundp 'shr-dom-to-xml)
                (shr-dom-to-xml best))))))))))

(defun my/elfeed--response-body ()
  "Extract and decode the body from a `url-retrieve' response buffer."
  (goto-char (point-min))
  (when (search-forward "\n\n" nil t)
    (decode-coding-string
     (buffer-substring-no-properties (point) (point-max))
     'utf-8 t)))

(defun my/elfeed--fulltext-cb (status entry)
  "Replace ENTRY's content with the extracted article; refresh viewers."
  (unless (plist-get status :error)
    (let* ((body (my/elfeed--response-body))
           (article (my/elfeed--extract-readable
                     body (elfeed-entry-link entry))))
      ;; Guard: only accept extractions that are plausibly the article
      ;; (paywalls/consent pages score *something*; a tiny result means
      ;; the excerpt from the feed is the better content).
      (when (and article (> (length article) 600))
        (setf (elfeed-entry-content entry) (elfeed-ref article))
        (setf (elfeed-meta entry :fulltext) t)
        ;; Live-upgrade any buffer currently showing this entry.
        (dolist (buf (buffer-list))
          (with-current-buffer buf
            (when (and (derived-mode-p 'elfeed-show-mode)
                       (eq elfeed-show-entry entry))
              (elfeed-show-refresh))))))))

(defun my/elfeed--fulltext-maybe (entry)
  "Asynchronously upgrade ENTRY to extracted full text (cached)."
  (let ((url (elfeed-entry-link entry)))
    (when (and url
               (string-match-p "\\`https?://" url)
               (not (elfeed-meta entry :fulltext)))
      (ignore-errors
        (url-retrieve url #'my/elfeed--fulltext-cb (list entry) t t)))))

;; --- Starring: keep-forever bookmarks --------------------------------
;; The db already keeps every entry indefinitely (filters hide, never
;; delete).  Starring adds an explicit "come back to this" tag:
;;   m            toggle star (search list or article view)
;;   s +starred   view everything ever starred (add @6-months-ago etc.)
(defun my/elfeed-toggle-star ()
  "Toggle the `starred' tag on the current/selected elfeed entries."
  (interactive)
  (cond
   ((derived-mode-p 'elfeed-search-mode)
    (dolist (entry (elfeed-search-selected))
      (if (memq 'starred (elfeed-entry-tags entry))
          (elfeed-untag entry 'starred)
        (elfeed-tag entry 'starred)))
    (elfeed-search-update--force))
   ((derived-mode-p 'elfeed-show-mode)
    (when elfeed-show-entry
      (if (memq 'starred (elfeed-entry-tags elfeed-show-entry))
          (elfeed-untag elfeed-show-entry 'starred)
        (elfeed-tag elfeed-show-entry 'starred))
      (elfeed-show-refresh)))))

(defun my/elfeed-evil-keys ()
  "Bind our keys in elfeed maps (idempotent; survives evil-collection)."
  (with-eval-after-load 'evil
    (evil-define-key 'normal elfeed-search-mode-map
      (kbd "m") #'my/elfeed-toggle-star)
    (evil-define-key 'normal elfeed-show-mode-map
      (kbd "m") #'my/elfeed-toggle-star)))

(with-eval-after-load 'elfeed
  (my/elfeed-evil-keys))
;; Same clobber-guard as dired: evil-collection's elfeed setup runs
;; later and must not win the last-write race.
(with-eval-after-load 'evil-collection
  (add-hook 'evil-collection-setup-hook
            (lambda (mode &rest _)
              (when (eq mode 'elfeed)
                (my/elfeed-evil-keys)))))

(provide 'config-rss)
;;; config-rss.el ends here
