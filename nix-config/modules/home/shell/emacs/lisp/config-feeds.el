;;; config-feeds.el --- RSS (elfeed) + PDF (pdf-tools) -*- lexical-binding: t; -*-
;;; Commentary:
;; elfeed feed list lives at ~/.emacs.d/elfeed-feeds.el (user maintained).
;; pdf-tools auto-loads when opening *.pdf.
;;; Code:

(use-package elfeed
  :defer t
  :commands (elfeed)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader "or" '(elfeed :which-key "rss"))))
  :config
  (setq elfeed-db-directory
        (expand-file-name "elfeed-db" user-emacs-directory))
  (let ((feeds-file
         (expand-file-name "elfeed-feeds.el" user-emacs-directory)))
    (when (file-exists-p feeds-file) (load feeds-file))))

;; --- Full-article reader (R) -----------------------------------------
;; Most feeds publish only a snippet.  Pressing `R' on an entry fetches
;; the link in eww and immediately runs `eww-readable' to strip nav /
;; ads / footers — equivalent to newsboat's full-content view.
;;
;; The hook is buffer-local + self-removing so it only fires once per
;; render and only in the eww buffer we just opened (no global state).
(defun my/elfeed--make-readable-once ()
  "Run `eww-readable' the first time eww renders, then unhook self."
  (eww-readable)
  (remove-hook 'eww-after-render-hook #'my/elfeed--make-readable-once 'local))

(defun my/elfeed-show-readable ()
  "Open the current entry's full article in eww with readability."
  (interactive)
  (let ((entry (or (and (boundp 'elfeed-show-entry) elfeed-show-entry)
                   (and (fboundp 'elfeed-search-selected)
                        (elfeed-search-selected :ignore-region)))))
    (unless entry (user-error "No elfeed entry at point"))
    (let ((url (elfeed-entry-link entry)))
      (eww url)
      (add-hook 'eww-after-render-hook
                #'my/elfeed--make-readable-once nil 'local))))

(with-eval-after-load 'elfeed-search
  (evil-define-key 'normal elfeed-search-mode-map (kbd "R") #'my/elfeed-show-readable))
(with-eval-after-load 'elfeed-show
  (evil-define-key 'normal elfeed-show-mode-map (kbd "R") #'my/elfeed-show-readable))

;; --- Full-article in-place (`f' in elfeed-show) ---------------------
;; Replaces the elfeed-show buffer's body with the full article fetched
;; from the entry's URL, rendered via shr (inline images, native fonts).
;; You stay in the elfeed-show buffer — `q' still returns to the search
;; list, `n/p' still walks entries.
;;
;; `f'        fetch + render (uses cache if URL has been fetched before)
;; `C-u f'    force refetch (bypasses cache — for retrying failed loads
;;            or updating an article that changed)
;;
;; Tuning: shr's image/scroll behavior set below for clean reading.
(defvar my/elfeed-fulltext-cache (make-hash-table :test 'equal)
  "URL → fetched HTML body string.  Process-local; cleared on restart.")

(defcustom my/elfeed-fulltext-width 130
  "Max column width for full-text rendering.  Window margins fill the rest."
  :type 'integer :group 'elfeed)
;; defcustom only initializes when unbound — re-loading this file leaves
;; the previous value in place.  Force it so width edits take effect on
;; `(load ...)' without a daemon restart.
(setq my/elfeed-fulltext-width 130)

(defvar my/elfeed-fulltext-user-agent
  "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
  "User-Agent sent when fetching full-text articles.
Many sites (Medium, NYT, Quartz, paywalled blogs) serve full text to
search-engine crawlers for SEO indexing while showing logged-out
browser clients a paywall preview.  Sending Googlebot's UA bypasses
the paywall for these sites.  This is exactly what reader apps like
Reeder, NetNewsWire, and Inoreader's full-text mode do.")

(defcustom my/elfeed-medium-proxy nil
  "Proxy prefix used to bypass Cloudflare on Medium articles.
Set to e.g. \"https://freedium.cfd/\" to rewrite Medium URLs through
a proxy that clears Cloudflare's JS challenge server-side.

Default is nil — every public Medium proxy I could find is either
dead (freedium.cfd → NXDOMAIN, scribe.rip → 404, medium.rip parked),
gets CF-challenged itself (r.jina.ai), or is unreachable.  Leave nil
and accept that CF-walled Medium articles will return the challenge
page until a working proxy emerges.  Use the vterm-cha path for
those instead — interactive cha clears CF given seconds of JS time."
  :type '(choice (const :tag "Disabled" nil) string)
  :group 'elfeed)

(defun my/elfeed--maybe-proxy-url (url)
  "Rewrite URL through `my/elfeed-medium-proxy' if URL is a Medium link.
Medium uses Cloudflare on most articles — direct fetch with any UA
returns the JS challenge page, not the article.  The proxy does the
challenge dance and returns plain HTML."
  (if (and my/elfeed-medium-proxy
           (string-match-p "^https?://\\([a-z0-9-]+\\.\\)?medium\\.com/" url))
      (concat my/elfeed-medium-proxy url)
    url))

;; Cleaning strategy:
;;   1. Strip chrome TAGS (nav/header/footer/aside/script/style/etc.).
;;   2. Strip elements whose class/id matches a deny TOKEN — only via
;;      EXACT-match or hyphen-suffix (`-foo').  Naive substring matching
;;      breaks: e.g. DZone wraps article bodies in `trending-article-body'
;;      and `widget-top-border', so any rule matching `trending' or
;;      `widget' as a substring nukes the article.  Hyphen-suffix only
;;      catches the common BEM/utility-naming chrome patterns
;;      (`site-nav', `*-sidebar', `*-modal') without touching content.
;;   3. POSITIVE-select the article body via known content classes
;;      (`article-body', `entry-content', ...).  Fall back to <article>,
;;      then <main>, then `eww-highest-readability'.
(defvar my/elfeed-fulltext-prune-tags
  '(script style noscript nav header footer aside iframe form button svg)
  "DOM tags removed wholesale before body extraction.
`svg' is included because most inline SVGs on article pages are UI
icons (clap, share, follow, etc.) that shr renders as the unhelpful
text \"SVG Image\".  Sites that use SVG for technical diagrams will
lose those — rare enough to accept for cleaner article rendering.")

(defvar my/elfeed-fulltext-deny-class-tokens
  '("nav" "menu" "sidebar" "footer" "header" "related" "trending"
    "comments" "share" "social" "breadcrumb" "skip-link" "screen-reader"
    "advertisement" "advert" "ads" "promo" "popup" "modal" "banner"
    "newsletter" "subscribe" "cookie-banner" "cookie-notice"
    "signin-prompt" "signup-prompt" "engagement-modal" "engagement-toolbar"
    "ad-container" "ad-billboard" "site-nav" "post-nav" "post-meta"
    "author-bio" "action-label" "view-count" "share-count" "like-count"
    "comment-count"
    ;; Medium-specific chrome (pw-author-name, pw-multi-vote-icon, etc.)
    "author-name" "multi-vote-icon" "multi-vote-count" "multi-vote-button"
    "published-date" "reading-time" "publication-name")
  "Class/id tokens that mark an element as boilerplate.
Matched on EXACT equality or hyphen-suffix (`*-token').  Substring
matching would false-positive on content wrappers like
`trending-article-body'.")

(defvar my/elfeed-fulltext-body-selectors
  '("article-body" "trending-article-body" "entry-content"
    "post-content" "post-body" "article-content"
    "story-body" "article-text" "single-content" "markdown-body")
  "Class names searched in order to locate the main article wrapper.
`dom-by-class' substring-matches, so `article-body' also catches
e.g. `trending-article-body'.")

(defvar my/elfeed-fulltext-deny-testid
  '("authorPhoto" "authorName" "storyReadTime" "storyPublishDate"
    "headerSocialShareButton" "postSidebar" "publicationName"
    "headerAvatar" "headerAvatarLink" "tagLink" "footerSocialShareButton")
  "Medium-style `data-testid' values that mark chrome elements.
Different from class tokens because Medium uses camelCase for testids.")

(defun my/elfeed-fulltext--class-bad-p (cls)
  "Non-nil if CLS (one whitespace-split class token) is boilerplate."
  (let ((c (downcase cls)))
    (cl-some (lambda (w) (or (string= c w) (string-suffix-p (concat "-" w) c)))
             my/elfeed-fulltext-deny-class-tokens)))

(defun my/elfeed-fulltext--node-bad-p (node)
  "Non-nil if any class/id/data-testid on NODE is in a deny list."
  (or
   (cl-some
    (lambda (attr)
      (let ((v (dom-attr node attr)))
        (when (stringp v)
          (cl-some #'my/elfeed-fulltext--class-bad-p
                   (split-string v "[ \t\n]+" t)))))
    '(class id))
   (let ((tid (dom-attr node 'data-testid)))
     (and (stringp tid) (member tid my/elfeed-fulltext-deny-testid)))))

(defun my/elfeed-fulltext--collect-bad (dom)
  "Walk DOM, return list of nodes matching the class/id deny rule."
  (let (acc)
    (cl-labels ((walk (n)
                  (when (and (consp n) (symbolp (car n)))
                    (when (my/elfeed-fulltext--node-bad-p n) (push n acc))
                    (dolist (c (dom-children n)) (walk c)))))
      (walk dom)
      acc)))

(defun my/elfeed-fulltext--resolve-picture-imgs (dom)
  "Hoist srcset URLs onto bare <img> children of <picture> elements.
shr has no handler for <picture>/<source>, so Medium-style markup
<picture><source srcset=...><img src=\"\"></picture> renders as
nothing.  This walks the DOM and, for each <img> with no src whose
parent is <picture>, picks the first URL from a sibling <source>'s
srcset and sets it as the <img>'s src.  After this, shr-tag-img
renders the image normally."
  (cl-labels
      ((walk (node)
         (when (and (consp node) (symbolp (car node)))
           (when (eq (dom-tag node) 'picture)
             (let* ((sources (dom-by-tag node 'source))
                    (srcset (cl-some (lambda (s)
                                       (or (dom-attr s 'srcset)
                                           (dom-attr s 'srcSet)))
                                     sources))
                    (img (car (dom-by-tag node 'img))))
               (when (and srcset img
                          (let ((s (dom-attr img 'src)))
                            (or (null s) (string-empty-p s))))
                 ;; srcset format: "URL1 width1w, URL2 width2w, ..."
                 ;; Take the first URL — usually smallest, good for our
                 ;; column width.
                 (let ((first-url (car (split-string srcset "[, ]+" t))))
                   (when (and first-url (string-match-p "^https?://" first-url))
                     (dom-set-attribute img 'src first-url))))))
           (dolist (c (dom-children node)) (walk c)))))
    (walk dom))
  dom)

(defun my/elfeed-fulltext--scrub (dom)
  "Destructively strip chrome tags + token-matched class/id boilerplate.
Also resolves <picture><source srcset> → <img src> so shr renders the
image (Medium etc. ship <img> as empty placeholders)."
  (dolist (tag my/elfeed-fulltext-prune-tags)
    (dolist (n (dom-by-tag dom tag))
      (ignore-errors (dom-remove-node dom n))))
  (dolist (n (my/elfeed-fulltext--collect-bad dom))
    (ignore-errors (dom-remove-node dom n)))
  (my/elfeed-fulltext--resolve-picture-imgs dom)
  dom)

(defun my/elfeed-fulltext--node-ancestors (dom node)
  "List of NODE and all its ancestors in DOM, root-first."
  (let ((acc (list node))
        (parent (dom-parent dom node)))
    (while parent
      (push parent acc)
      (setq parent (dom-parent dom parent)))
    acc))

(defun my/elfeed-fulltext--lca (dom nodes)
  "Return the deepest node in DOM that is an ancestor of every node in NODES.
For Medium-style markup where body paragraphs live in multiple sibling
section divs, this returns the div that wraps ALL of them — usually the
<article> tag or one level below."
  (when nodes
    (let ((first-anc (my/elfeed-fulltext--node-ancestors dom (car nodes))))
      (cl-loop for ancestor in (reverse first-anc) ; deepest first
               when (cl-every
                     (lambda (n)
                       (memq ancestor (my/elfeed-fulltext--node-ancestors dom n)))
                     (cdr nodes))
               return ancestor))))

(defun my/elfeed-fulltext--find-body (dom)
  "Locate the article body in DOM via known content selectors.
When a selector matches multiple elements split across sibling sections
\(Medium: intro, content, conclusion in separate divs), returns their
LOWEST COMMON ANCESTOR — the wrapper that contains all of them.  Falls
back to <article>, <main>, then the readability heuristic."
  (let ((matches
         (cl-loop for cls in my/elfeed-fulltext-body-selectors
                  for hits = (dom-by-class dom cls)
                  when hits return hits)))
    (cond
     ((null matches)
      (or (car (dom-by-tag dom 'article))
          (car (dom-by-tag dom 'main))
          (ignore-errors (eww-highest-readability dom))
          dom))
     ((= 1 (length matches))
      (car matches))
     (t
      (or (my/elfeed-fulltext--lca dom matches)
          (dom-parent dom (car matches))
          (car matches))))))

(defun my/elfeed-show--center-window ()
  "Set window margins so the article column sits centered in the window."
  (let* ((win (get-buffer-window (current-buffer) t))
         (cols (or (and win (window-total-width win)) (frame-width)))
         (margin (max 0 (/ (- cols my/elfeed-fulltext-width) 2))))
    (setq-local left-margin-width margin
                right-margin-width margin)
    (when win (set-window-margins win margin margin))))

(defun my/elfeed-show--reset-margins (&rest _)
  "Clear full-text margins — elfeed-show reuses one buffer across entries."
  (setq-local left-margin-width 0
              right-margin-width 0)
  (when-let ((win (get-buffer-window (current-buffer) t)))
    (set-window-margins win 0 0)))

(advice-add 'elfeed-show-refresh :before #'my/elfeed-show--reset-margins)

(defun my/elfeed-show--render-fulltext (html)
  "Replace this elfeed-show buffer's body with scrubbed + readable HTML,
rendered into a `my/elfeed-fulltext-width'-column centered column."
  (let ((inhibit-read-only t)
        (shr-width my/elfeed-fulltext-width))
    (save-excursion
      ;; mail-style renderer ends headers with a blank line; body follows.
      (goto-char (point-min))
      (or (re-search-forward "^$" nil t) (goto-char (point-max)))
      (delete-region (point) (point-max))
      (insert "\n\n")
      (let* ((dom (with-temp-buffer
                    (insert html)
                    (libxml-parse-html-region (point-min) (point-max))))
             (clean (my/elfeed-fulltext--scrub dom))
             (body  (my/elfeed-fulltext--find-body clean)))
        (shr-insert-document body))))
  (my/elfeed-show--center-window))

(defun my/elfeed-show-fetch-fulltext (&optional refresh)
  "Fetch full article from entry's URL and render in this buffer.
With prefix arg REFRESH (`C-u f'), ignore cache and refetch."
  (interactive "P")
  (unless (derived-mode-p 'elfeed-show-mode)
    (user-error "Not in an elfeed entry"))
  (let* ((entry elfeed-show-entry)
         (raw-url (elfeed-entry-link entry))
         (url   (my/elfeed--maybe-proxy-url raw-url))
         (buf   (current-buffer))
         (cached (and (not refresh) (gethash url my/elfeed-fulltext-cache))))
    (cond
     (cached
      (my/elfeed-show--render-fulltext cached)
      (message "elfeed: rendered from cache (C-u f to refetch)"))
     (t
      (message "elfeed: fetching %s…" url)
      ;; UA spoof — Medium et al. serve full text to crawlers, paywall
      ;; everyone else.  See `my/elfeed-fulltext-user-agent' for context.
      (let ((url-user-agent my/elfeed-fulltext-user-agent)
            (url-request-extra-headers
             `(("Accept" . "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
               ("Accept-Language" . "en-US,en;q=0.5"))))
        (url-retrieve
         url
         (lambda (status)
         (let ((err (plist-get status :error)))
           (cond
            (err
             (message "elfeed: fetch failed — %S" err))
            ((not (buffer-live-p buf))
             (message "elfeed: target buffer gone, skipping render"))
            (t
             (goto-char (point-min))
             (re-search-forward "\r?\n\r?\n" nil t)
             (let ((html (decode-coding-string
                          (buffer-substring-no-properties (point) (point-max))
                          'utf-8)))
               (kill-buffer)
               (puthash url html my/elfeed-fulltext-cache)
               (with-current-buffer buf
                 (my/elfeed-show--render-fulltext html))
               (message "elfeed: full article rendered"))))))
         nil 'silent 'inhibit-cookies))))))

;; --- Full-article via curl_cffi TLS impersonation (`H' in elfeed-show) ----
;; `f' (url-retrieve + shr) fails on Cloudflare — emacs's TLS handshake is
;; trivially distinguishable from a real browser's, and CF flags it.
;; `H' (this) shells out to a tiny uv-managed Python script that uses
;; `curl_cffi' to perform a byte-for-byte Chrome TLS handshake.  CF
;; can't tell our request apart from real Chrome at the network layer,
;; so the JS challenge never fires.  Output is HTML, rendered through
;; the same scrub + find-body + shr pipeline as `f' — images render
;; inline.  ~30 MB during fetch (Python + curl_cffi), <1s cold start
;; after uv has cached the wheel.  Empirically clears Medium / Substack
;; / most CF-walled article sites.  Falls down on Cloudflare Turnstile +
;; Bot Fight Mode (those need a real browser via `chromium --headless
;; --dump-dom').
(defcustom my/elfeed-cf-fetch-script
  (expand-file-name "scripts/cf-fetch.py" "~/.config/nix-config")
  "Path to the curl_cffi-based CF-bypass fetcher script.
Invoked via `make-process'; takes a URL on argv, writes HTML to stdout."
  :type 'string :group 'elfeed)

(defvar my/elfeed-cf-cache (make-hash-table :test 'equal)
  "URL → HTML fetched via curl_cffi.  Process-local; cleared on restart.")

(defun my/elfeed-show-fetch-via-cffi (&optional refresh)
  "Render the current entry's URL via curl_cffi Chrome TLS impersonation.
Bypasses Cloudflare's TLS-fingerprint check by issuing a real
Chrome-shaped handshake.  With prefix arg REFRESH (`C-u H'), bypass
cache and refetch."
  (interactive "P")
  (unless (derived-mode-p 'elfeed-show-mode)
    (user-error "Not in an elfeed entry"))
  (unless (file-executable-p my/elfeed-cf-fetch-script)
    (user-error "cf-fetch script missing or not executable: %s"
                my/elfeed-cf-fetch-script))
  (let* ((entry elfeed-show-entry)
         (url (elfeed-entry-link entry))
         (buf (current-buffer))
         (cached (and (not refresh) (gethash url my/elfeed-cf-cache))))
    (cond
     (cached
      (my/elfeed-show--render-fulltext cached)
      (message "cffi: rendered from cache (C-u H to refetch)"))
     (t
      (message "cffi: fetching %s (Chrome TLS impersonation)…" url)
      (let ((out-buf (generate-new-buffer " *cf-fetch-out*"))
            (err-buf (get-buffer-create " *cf-fetch-stderr*")))
        (make-process
         :name "cf-fetch"
         :buffer out-buf
         :stderr err-buf
         :noquery t
         :command (list my/elfeed-cf-fetch-script url)
         :sentinel
         (lambda (proc _event)
           (when (memq (process-status proc) '(exit signal))
             (let ((html (with-current-buffer (process-buffer proc)
                           (buffer-string)))
                   (rc (process-exit-status proc)))
               (kill-buffer (process-buffer proc))
               (cond
                ((not (zerop rc))
                 (message "cffi: exit %d (see ` *cf-fetch-stderr*')" rc))
                ((not (buffer-live-p buf))
                 (message "cffi: target buffer gone"))
                ((zerop (length html))
                 (message "cffi: empty response"))
                (t
                 (puthash url html my/elfeed-cf-cache)
                 (with-current-buffer buf
                   (my/elfeed-show--render-fulltext html))
                 (message "cffi: render complete"))))))))))))

;; --- shr tuning for elfeed-show + eww reading -----------------------
;; Without max-image-proportion, hero images push article text two
;; screens down.  Animate off = no GIF jitter while reading.
(with-eval-after-load 'shr
  (setq shr-max-image-proportion 0.7
        shr-image-animate nil
        shr-cookie-policy 'same-origin))

;; --- Full-article via chawan dump (`C' in elfeed-show) --------------
;; `f' uses emacs's own shr + readability.  `C' instead pipes the URL
;; through chawan's full HTML/CSS/JS engine (`cha -d') and renders the
;; dump into this buffer with ANSI bold/italic/underline applied via
;; `ansi-color'.  No images (chawan would emit sixel escapes that
;; emacs can't render), but text-extraction quality on heavy-JS sites
;; (Medium, NYT, blog frameworks) is dramatically better than what
;; shr + eww-highest-readability can produce.  Width is set via the
;; COLUMNS env var so chawan's word-wrap matches our centered column.
(defvar my/elfeed-cha-cache (make-hash-table :test 'equal)
  "URL → chawan dump output.  Process-local cache.")

(defun my/elfeed-show--render-cha-output (text)
  "Replace this elfeed-show buffer's body with TEXT (a `cha -d' dump).
Apply ANSI face escapes and center the rendered column."
  (require 'ansi-color)
  (let ((inhibit-read-only t))
    (save-excursion
      (goto-char (point-min))
      (or (re-search-forward "^$" nil t) (goto-char (point-max)))
      (delete-region (point) (point-max))
      (insert "\n\n")
      (let ((start (point)))
        (insert text)
        (ansi-color-apply-on-region start (point-max)))))
  (my/elfeed-show--center-window))

(defun my/elfeed-show-fetch-via-cha (&optional refresh)
  "Render the current entry's URL via `cha -d' (chawan) in this buffer.
With prefix arg REFRESH (`C-u C'), bypass cache and refetch."
  (interactive "P")
  (unless (derived-mode-p 'elfeed-show-mode)
    (user-error "Not in an elfeed entry"))
  (unless (executable-find "cha")
    (user-error "`cha' (chawan) not on PATH"))
  (let* ((entry elfeed-show-entry)
         (raw-url (elfeed-entry-link entry))
         (url (my/elfeed--maybe-proxy-url raw-url))
         (buf (current-buffer))
         (cached (and (not refresh) (gethash url my/elfeed-cha-cache))))
    (cond
     (cached
      (my/elfeed-show--render-cha-output cached)
      (message "cha: rendered from cache (C-u C to refetch)"))
     (t
      (message "cha: fetching %s via chawan…" url)
      (let* ((out-buf (generate-new-buffer " *cha-out*"))
             (process-environment
              (cons (format "COLUMNS=%d" my/elfeed-fulltext-width)
                    process-environment)))
        (make-process
         :name "cha-elfeed"
         :buffer out-buf
         :stderr (get-buffer-create " *cha-stderr*")
         :noquery t
         :command (list "cha" "-d"
                        "-o" "display.image-mode=\"none\""
                        url)
         :sentinel
         (lambda (proc _event)
           (when (memq (process-status proc) '(exit signal))
             (let ((output (with-current-buffer (process-buffer proc)
                             (buffer-string)))
                   (rc (process-exit-status proc)))
               (kill-buffer (process-buffer proc))
               (cond
                ((not (zerop rc))
                 (message "cha: exited %d (see ` *cha-stderr*')" rc))
                ((not (buffer-live-p buf))
                 (message "cha: target buffer gone"))
                (t
                 (puthash url output my/elfeed-cha-cache)
                 (with-current-buffer buf
                   (my/elfeed-show--render-cha-output output))
                 (message "cha: render complete"))))))))))))

(with-eval-after-load 'elfeed-show
  ;; Bind in BOTH normal and motion states — elfeed-show is read-only and
  ;; evil-collection puts it in motion-state, so a 'normal-only binding
  ;; gets shadowed by motion-state defaults (e.g. H = evil-window-top).
  (evil-define-key '(normal motion) elfeed-show-mode-map
    (kbd "f") #'my/elfeed-show-fetch-fulltext
    (kbd "C") #'my/elfeed-show-fetch-via-cha
    (kbd "F") #'my/elfeed-show-fetch-via-cffi))

(use-package pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  ;; pdf-tools-install eagerly tries to enable pdf-occur-global-minor-mode
  ;; which lives in pdf-occur.el and isn't loaded yet at install time
  ;; (autoload-ordering bug in vedang/pdf-tools v20240429). Skip it —
  ;; the :mode autoload above routes *.pdf to pdf-view-mode without
  ;; needing the global install. If we ever need pdf-tools-install,
  ;; require 'pdf-occur first or wrap in (ignore-errors ...).
  )

(provide 'config-feeds)
;;; config-feeds.el ends here
