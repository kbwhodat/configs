;;; config-llm.el --- LLM chat (gptel) -*- lexical-binding: t; -*-
;;; Commentary:
;; ANTHROPIC_API_KEY / OPENAI_API_KEY come from the shell env.
;; Per-project system prompts live in `.dir-locals.el' — see HOW-TO
;; at the bottom of this file.
;;; Code:

(require 'cl-lib)
(require 'subr-x)

(defun my/gptel-menu ()
  "Open gptel's transient menu, loading its current home first."
  (interactive)
  (require 'gptel-transient)
  (call-interactively #'gptel-menu))

(defun my/gptel-load-skill (path)
  "Load a Claude Code SKILL.md as the system prompt for the current gptel chat.
Strips the YAML frontmatter (between leading `---' fences) so the LLM
sees only the prose instructions.  Buffer-local — different chat
buffers can have different skills loaded simultaneously."
  (interactive
   (list (read-file-name "Skill file: "
                          (expand-file-name "~/.claude/skills/"))))
  (require 'gptel)
  (let ((content (with-temp-buffer
                   (insert-file-contents path)
                   (goto-char (point-min))
                   ;; Strip YAML frontmatter if present.
                   (when (looking-at "^---[[:space:]]*\n")
                     (let ((end (save-excursion
                                  (forward-line)
                                  (re-search-forward "^---[[:space:]]*\n" nil t))))
                       (when end (delete-region (point-min) end))))
                   (string-trim (buffer-string)))))
    (setq-local gptel--system-message content)
    (message "Skill loaded (%d chars): %s"
             (length content)
             (file-name-nondirectory
              (directory-file-name (file-name-directory path))))))

(defcustom my/gptel-context-files
  '("CLAUDE.md" "AGENTS.md" "MEMORY.md" ".cursorrules" "GEMINI.md")
  "Filenames searched at project root for auto-loadable agent context.
Order matters — found files are concatenated in this order.

Conventions:
- CLAUDE.md     Anthropic / Claude Code — user-authored rules
- AGENTS.md     cross-agent standard (Sourcegraph/OpenAI/Google/Cursor/...)
                maintained under the Linux Foundation's Agentic AI Foundation
- MEMORY.md     agent-captured learnings (Claude Code auto-writes here).
                Auto-loads the first ~200 lines per Claude Code spec.
- .cursorrules  older Cursor convention (still widely seen)
- GEMINI.md     Gemini CLI"
  :type '(repeat string)
  :group 'gptel)

(defun my/gptel--find-project-root (&optional dir)
  "Find the nearest project root above DIR (default: `default-directory').
A root is the closest ancestor containing any of: .git/  .jj/  flake.nix
package.json  Cargo.toml  pyproject.toml.  Returns nil if not in a project."
  (locate-dominating-file
   (or dir default-directory)
   (lambda (d)
     (cl-some (lambda (m) (file-exists-p (expand-file-name m d)))
              '(".git" ".jj" "flake.nix" "package.json"
                "Cargo.toml" "pyproject.toml" "go.mod")))))

(defun my/gptel-project-chat ()
  "Open or continue THIS project's persistent gptel chat.

File lives at  <project-root>/.gptel/chat.md  —  a plain markdown file.
gptel-mode handles parsing the conversation on re-open, so you continue
where you left off.  Save with `C-x C-s' as usual; nothing auto-writes.

Add `.gptel/' to your project's .gitignore if you don't want chats in
version control."
  (interactive)
  (require 'gptel)
  (let ((root (my/gptel--find-project-root)))
    (unless root
      (user-error "Not in a project — no .git/.jj/flake.nix/etc. found upward"))
    (let* ((dir  (expand-file-name ".gptel" root))
           (file (expand-file-name "chat.md" dir)))
      (unless (file-directory-p dir)
        (make-directory dir t)
        (set-file-modes dir #o700))
      (find-file file)
      (unless (bound-and-true-p gptel-mode) (gptel-mode 1))
      (goto-char (point-max)))))

(defun my/gptel-maybe-load-project-context ()
  "Soft variant of `my/gptel-load-project-context' — silent on miss.
Suitable for `gptel-mode-hook' so opening a chat auto-pulls project
agent context when present, but doesn't error out in non-project dirs."
  (when (my/gptel--find-project-root)
    (ignore-errors (my/gptel-load-project-context))))

(defun my/gptel-load-project-context ()
  "Auto-load CLAUDE.md / AGENTS.md / MEMORY.md / .cursorrules / GEMINI.md
from the current project root into `gptel--system-message' (buffer-local).
Run from any buffer inside the project, or from a gptel chat buffer
  whose `default-directory' is within the project."
  (interactive)
  (require 'gptel)
  (let* ((root (my/gptel--find-project-root))
         (sections '()))
    (unless root
      (user-error "Not in a project — no .git/.jj/flake.nix/etc. found upward"))
    (dolist (name my/gptel-context-files)
      (let ((f (expand-file-name name root)))
        (when (file-readable-p f)
          (push (format "# %s\n\n%s"
                        name
                        (with-temp-buffer
                          (insert-file-contents f)
                          (string-trim (buffer-string))))
                sections))))
    (if sections
        (let ((content (mapconcat #'identity (nreverse sections)
                                  "\n\n---\n\n")))
          (setq-local gptel--system-message content)
          (message "Loaded %d file(s), %d chars from %s"
                   (length sections) (length content)
                   (abbreviate-file-name root)))
      (user-error "No %s found in %s"
                  (mapconcat #'identity my/gptel-context-files "/")
                  (abbreviate-file-name root)))))

(defun my/gptel-feedback-line ()
  "Send the current line to a gptel chat for feedback.
Opens a chat buffer, drops the line in a code fence with the
major-mode name, leaves point ready for you to type the question."
  (interactive)
  (require 'gptel)
  (let* ((line (string-trim-right (or (thing-at-point 'line t) "")))
         (mode (replace-regexp-in-string
                "-ts-mode$\\|-mode$" ""
                (symbol-name major-mode)))
         (file (or (buffer-file-name) (buffer-name))))
    (gptel "*gptel-feedback*")
    (with-current-buffer "*gptel-feedback*"
      (goto-char (point-max))
      (insert (format "Feedback on this line (`%s`, %s):\n```%s\n%s\n```\n\n"
                      file mode mode line)))))

(defun my/gptel-rewrite-region-prompt (instruction)
  "Prompt for INSTRUCTION and rewrite the active region in place."
  (interactive
   (progn
     (unless (use-region-p)
       (user-error "Select a region before rewriting"))
     (require 'gptel-rewrite)
     (list (read-string "Rewrite instruction: "))))
  (require 'gptel-rewrite)
  (unless (use-region-p)
    (user-error "Select a region before rewriting"))
  (setq-local gptel-rewrite-default-action 'accept)
  (message "gptel rewrite: sending to %s/%s..."
           (gptel-backend-name gptel-backend)
           (gptel--model-name gptel-model))
  (gptel--suffix-rewrite instruction))

(defconst my/gptel-selection-file
  (expand-file-name "gptel-selection.el" user-emacs-directory)
  "Small local state file storing the selected gptel backend/model.")

(defvar my/gptel--restoring-selection nil
  "Non-nil while restoring gptel selection from disk.")

(defun my/gptel--selection-readable-p (backend-name)
  "Return non-nil if BACKEND-NAME has credentials/config for startup use."
  (pcase backend-name
    ("Claude" (not (string-empty-p (or (getenv "ANTHROPIC_API_KEY") ""))))
    ("ChatGPT" (not (string-empty-p (or (getenv "OPENAI_API_KEY") ""))))
    ("Kimi-Coder" (file-readable-p my/kimi-credentials-file))
    ("Codex" (file-readable-p my/codex-credentials-file))
    (_ t)))

(defun my/gptel--save-selection (&optional backend model)
  "Persist BACKEND and MODEL names without storing secrets."
  (unless my/gptel--restoring-selection
    (let* ((backend (or backend gptel-backend))
           (model (or model gptel-model))
           (backend-name (and backend (gptel-backend-name backend))))
      (when (and backend-name model)
        (make-directory (file-name-directory my/gptel-selection-file) t)
        (with-temp-file my/gptel-selection-file
          (let ((print-level nil)
                (print-length nil))
            (prin1 `(:backend ,backend-name :model ,model) (current-buffer))))))))

(defun my/gptel--read-selection ()
  "Read persisted gptel backend/model selection, or nil."
  (when (file-readable-p my/gptel-selection-file)
    (ignore-errors
      (with-temp-buffer
        (insert-file-contents my/gptel-selection-file)
        (read (current-buffer))))))

(defun my/gptel--set-default (backend-name model)
  "Set default gptel BACKEND-NAME and MODEL when available."
  (when-let* ((backend (alist-get backend-name gptel--known-backends nil nil #'equal)))
    (setq gptel-backend backend
          gptel-model model)
    t))

(defun my/gptel--model-supported-p (backend-name model)
  "Return non-nil when BACKEND-NAME advertises MODEL."
  (when-let* ((backend (alist-get backend-name gptel--known-backends nil nil #'equal)))
    (cl-some (lambda (candidate)
               (eq (if (consp candidate) (car candidate) candidate) model))
             (gptel-backend-models backend))))

(defun my/gptel--restore-or-choose-default ()
  "Restore a usable gptel default, avoiding unconfigured providers."
  (let ((my/gptel--restoring-selection t)
        (selection (my/gptel--read-selection)))
    (or (when-let* ((backend-name (plist-get selection :backend))
                    (model (plist-get selection :model)))
          (when (and (my/gptel--selection-readable-p backend-name)
                     (my/gptel--model-supported-p backend-name model))
            (my/gptel--set-default backend-name model)))
        (when (and (file-readable-p my/codex-credentials-file)
                   (my/gptel--set-default "Codex" 'gpt-5.5))
          t)
        (when (and (file-readable-p my/kimi-credentials-file)
                   (my/gptel--set-default "Kimi-Coder" 'kimi-for-coding))
          t)
        (when (and (not (string-empty-p (or (getenv "ANTHROPIC_API_KEY") "")))
                   (my/gptel--set-default "Claude" 'claude-opus-4-7))
          t)
        (my/gptel--set-default "ChatGPT" 'gpt-4o))))

(defun my/gptel--selection-watcher (symbol newval operation _where)
  "Persist gptel selection after SYMBOL changes to NEWVAL by OPERATION."
  (when (and (eq operation 'set)
             (not my/gptel--restoring-selection)
             (boundp 'gptel-backend)
             (boundp 'gptel-model))
    (pcase symbol
      ('gptel-backend (my/gptel--save-selection newval gptel-model))
      ('gptel-model (my/gptel--save-selection gptel-backend newval)))))

;; =============================================================================
;; Kimi K2 Coding Plan — OAuth 2.0 Device Authorization Grant in pure elisp
;; =============================================================================
;; Reimplements the flow that `pi-kimi-coder' does in JS — no external CLI
;; needed.  Endpoints, client_id, and token-file format are the documented
;; pi-kimi-coder/kimi-cli convention so the credential store stays
;; interoperable with both tools.

(require 'url)
(require 'json)

(defconst my/kimi-oauth-host "https://auth.kimi.com")
(defconst my/kimi-client-id "17e5f671-d194-4dfb-9706-5516cb48c098"
  "Moonshot-registered OAuth client_id for the Kimi K2 Coding Plan.
Matches the constant baked into pi-kimi-coder's source.")
(defconst my/kimi-credentials-file
  (expand-file-name "~/.kimi/credentials/kimi-code.json")
  "Shared credential store. Read/written by my/kimi-* AND pi-kimi-coder.")
(defconst my/kimi-refresh-skew-seconds 300
  "Refresh Kimi OAuth access tokens when less than this many seconds remain.")

(defun my/kimi--http-post (path params)
  "POST form-encoded PARAMS (alist) to `my/kimi-oauth-host'+PATH.
Returns parsed JSON response as alist.  HTTP 4xx is NOT signaled —
OAuth uses 4xx for normal polling states; caller inspects `error' field."
  (let* ((url (concat my/kimi-oauth-host path))
         (url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/x-www-form-urlencoded")))
         (url-request-data
          (mapconcat
           (lambda (kv)
             (format "%s=%s"
                     (url-hexify-string (car kv))
                     (url-hexify-string (cdr kv))))
           params "&")))
    (with-current-buffer (url-retrieve-synchronously url t t)
      (unwind-protect
          (progn
            (goto-char (point-min))
            (re-search-forward "\n\n" nil 'noerror)
            (let ((json-object-type 'alist))
              (json-read)))
        (kill-buffer (current-buffer))))))

(defun my/kimi--build-token (response)
  "Construct the on-disk token alist from a parsed OAuth RESPONSE."
  (let ((expires-in (or (alist-get 'expires_in response) 3600)))
    `((access_token  . ,(alist-get 'access_token response))
      (refresh_token . ,(alist-get 'refresh_token response))
      (expires_at    . ,(+ (float-time) expires-in))
      (scope         . ,(or (alist-get 'scope response) "kimi-code"))
      (token_type    . ,(or (alist-get 'token_type response) "Bearer")))))

(defun my/kimi--save-token (token-alist)
  "Write TOKEN-ALIST to `my/kimi-credentials-file' at mode 0600."
  (let ((dir (file-name-directory my/kimi-credentials-file)))
    (unless (file-directory-p dir) (make-directory dir t)))
  (with-temp-file my/kimi-credentials-file
    (insert (json-encode token-alist)))
  (set-file-modes my/kimi-credentials-file #o600))

(defun my/kimi--request-device-code ()
  "Initiate the OAuth device flow.  Returns parsed device-auth alist."
  (let ((resp (my/kimi--http-post
               "/api/oauth/device_authorization"
               `(("client_id" . ,my/kimi-client-id)))))
    (unless (alist-get 'device_code resp)
      (error "Kimi device authorization failed: %S" resp))
    resp))

(defun my/kimi--poll-token (device-code interval)
  "Poll the token endpoint with DEVICE-CODE every INTERVAL seconds.
Returns success-response alist or signals user-error.  Blocking but
interruptible via C-g.  Caps at 10 minutes."
  (let ((max-attempts (/ 600 (max interval 1)))
        (attempt 0)
        (result nil))
    (while (and (< attempt max-attempts) (not result))
      (sleep-for interval)
      (setq attempt (1+ attempt))
      (let* ((resp (my/kimi--http-post
                    "/api/oauth/token"
                    `(("client_id"   . ,my/kimi-client-id)
                      ("device_code" . ,device-code)
                      ("grant_type"  . "urn:ietf:params:oauth:grant-type:device_code"))))
             (access (alist-get 'access_token resp))
             (err    (alist-get 'error resp)))
        (cond
         (access (setq result resp))
         ((equal err "expired_token")
          (user-error "Device code expired before approval — run M-x my/kimi-login again"))
         ((equal err "access_denied")
          (user-error "Access denied"))
         ;; authorization_pending / slow_down — keep polling
         )))
    (unless result (user-error "Kimi login timed out after 10 minutes"))
    result))

(defun my/kimi--refresh-token (refresh-token)
  "Exchange REFRESH-TOKEN for a fresh access_token.  Returns response alist."
  (let ((resp (my/kimi--http-post
               "/api/oauth/token"
               `(("client_id"     . ,my/kimi-client-id)
                 ("grant_type"    . "refresh_token")
                 ("refresh_token" . ,refresh-token)))))
    (unless (alist-get 'access_token resp)
      (user-error "Kimi token refresh failed (%s) — run M-x my/kimi-login"
                  (or (alist-get 'error_description resp)
                      (alist-get 'error resp) "unknown")))
    ;; Server may omit refresh_token on refresh responses — preserve the old one.
    (unless (alist-get 'refresh_token resp)
      (push (cons 'refresh_token refresh-token) resp))
    resp))

;; =============================================================================
;; OpenAI Codex (ChatGPT subscription) — OAuth 2.0 Authorization Code + PKCE
;; =============================================================================
;; Reimplements `loginOpenAICodex' from @earendil-works/pi-ai purely in
;; elisp.  Constants are the upstream values baked into Pi's source.
;;
;; STATUS NOTE: the Codex API endpoint is `chatgpt.com/backend-api'
;; speaking the OpenAI Responses API shape — NOT the standard
;; chat-completions shape that gptel-make-openai produces.  The OAuth
;; flow saves valid tokens to ~/.codex/auth.json (interop with Pi).
;; The registered gptel `Codex' backend is experimental: basic chat may
;; work, streaming/tool-use likely won't.  Use the official codex CLI
;; (which speaks Responses API correctly) for production agentic work.

(defconst my/codex-oauth-host "https://auth.openai.com")
(defconst my/codex-client-id "app_EMoamEEZ73f0CkXaXp7hrann"
  "Moonshot-... wait, OpenAI-registered client_id from pi-ai upstream source.")
(defconst my/codex-redirect-uri "http://localhost:1455/auth/callback")
(defconst my/codex-scope "openid profile email offline_access")
(defconst my/codex-callback-port 1455)
(defconst my/codex-credentials-file (expand-file-name "~/.codex/auth.json"))
(defconst my/codex-jwt-claim-path "https://api.openai.com/auth")

(defvar my/codex--callback-result nil
  "Set by the local HTTP callback server when OAuth completes.")

(defun my/codex--base64url-encode (data)
  "Base64url-encode DATA (string of bytes), no padding."
  (let ((b64 (base64-encode-string data t)))
    (replace-regexp-in-string
     "=+\\'" ""
     (replace-regexp-in-string
      "/" "_"
      (replace-regexp-in-string "+" "-" b64)))))

(defun my/codex--base64url-decode (str)
  "Decode base64url STR back to a string of bytes."
  (let* ((padded (concat str (make-string (mod (- 4 (length str)) 4) ?=)))
         (b64 (replace-regexp-in-string
               "_" "/"
               (replace-regexp-in-string "-" "+" padded))))
    (base64-decode-string b64)))

(defun my/codex--random-bytes (n)
  "Return a string of N random bytes."
  (let ((s (make-string n 0)))
    (dotimes (i n) (aset s i (random 256)))
    s))

(defun my/codex--pkce-pair ()
  "Return (VERIFIER . CHALLENGE) for PKCE S256."
  (let* ((verifier (my/codex--base64url-encode (my/codex--random-bytes 32)))
         (challenge (my/codex--base64url-encode
                     (secure-hash 'sha256 verifier nil nil t))))
    (cons verifier challenge)))

(defun my/codex--gen-state ()
  "Return a 32-hex-char state string."
  (let ((out ""))
    (dotimes (_ 16) (setq out (concat out (format "%02x" (random 256)))))
    out))

(defun my/codex--decode-jwt-payload (token)
  "Decode the payload segment of a JWT TOKEN to an alist (or nil)."
  (let ((parts (split-string token "\\.")))
    (when (= (length parts) 3)
      (condition-case nil
          (let ((json-object-type 'alist))
            (json-read-from-string
             (decode-coding-string
              (my/codex--base64url-decode (nth 1 parts)) 'utf-8)))
        (error nil)))))

(defun my/codex--extract-account-id (access-token)
  "Extract chatgpt_account_id from ACCESS-TOKEN's JWT claims."
  (let* ((payload (my/codex--decode-jwt-payload access-token))
         (auth (alist-get (intern my/codex-jwt-claim-path) payload nil nil #'equal)))
    (alist-get 'chatgpt_account_id auth)))

(defun my/codex--http-post-form (url params)
  "POST URL-encoded PARAMS alist to URL.  Returns parsed JSON alist."
  (let* ((url-request-method "POST")
         (url-request-extra-headers
          '(("Content-Type" . "application/x-www-form-urlencoded")))
         (url-request-data
          (mapconcat (lambda (kv)
                       (format "%s=%s"
                               (url-hexify-string (car kv))
                               (url-hexify-string (cdr kv))))
                     params "&")))
    (with-current-buffer (url-retrieve-synchronously url t t)
      (unwind-protect
          (progn (goto-char (point-min))
                 (re-search-forward "\n\n" nil 'noerror)
                 (let ((json-object-type 'alist)) (json-read)))
        (kill-buffer (current-buffer))))))

(defun my/codex--exchange-code (code verifier)
  "Exchange CODE (authorization code) + VERIFIER (PKCE) for tokens."
  (my/codex--http-post-form
   (concat my/codex-oauth-host "/oauth/token")
   `(("grant_type"    . "authorization_code")
     ("client_id"     . ,my/codex-client-id)
     ("code"          . ,code)
     ("code_verifier" . ,verifier)
     ("redirect_uri"  . ,my/codex-redirect-uri))))

(defun my/codex--refresh-token (refresh-token)
  "Refresh access token using REFRESH-TOKEN."
  (my/codex--http-post-form
   (concat my/codex-oauth-host "/oauth/token")
   `(("grant_type"    . "refresh_token")
     ("client_id"     . ,my/codex-client-id)
     ("refresh_token" . ,refresh-token))))

(defun my/codex--save-tokens (resp)
  "Persist token RESP to `my/codex-credentials-file' matching Pi's schema."
  (let* ((dir (file-name-directory my/codex-credentials-file))
         (access (alist-get 'access_token resp))
         (refresh (alist-get 'refresh_token resp))
         (expires-in (or (alist-get 'expires_in resp) 3600))
         (account-id (and access (my/codex--extract-account-id access)))
         (token `((type    . "oauth")
                  (access  . ,access)
                  (refresh . ,refresh)
                  (expires . ,(round (* 1000 (+ (float-time) expires-in))))
                  (accountId . ,account-id))))
    (unless (file-directory-p dir) (make-directory dir t))
    (with-temp-file my/codex-credentials-file
      (insert (json-encode `((openai-codex . ,token)))))
    (set-file-modes my/codex-credentials-file #o600)
    token))

(defun my/codex--load-tokens ()
  "Read the openai-codex token entry, or nil."
  (when (file-readable-p my/codex-credentials-file)
    (with-temp-buffer
      (insert-file-contents my/codex-credentials-file)
      (let ((json-object-type 'alist))
        (alist-get 'openai-codex (json-read-from-string (buffer-string)))))))

(defun my/codex--callback-filter (proc data)
  "Process filter for the local OAuth callback server.
Parses ?code=&state= from the GET request, stores the result, writes
a success page, closes the connection."
  (when (string-match "GET /auth/callback\\?\\([^ ]+\\) HTTP" data)
    (let* ((query (match-string 1 data))
           (params (url-parse-query-string query))
           (code (cadr (assoc "code" params)))
           (state (cadr (assoc "state" params))))
      (setq my/codex--callback-result (list :code code :state state))
      (ignore-errors
        (process-send-string
         proc
         (concat "HTTP/1.1 200 OK\r\n"
                 "Content-Type: text/html; charset=utf-8\r\n"
                 "Connection: close\r\n\r\n"
                 "<!doctype html><html><body style='font-family:system-ui;text-align:center;padding:4em'>"
                 "<h1>✓ Codex login complete</h1>"
                 "<p>You can close this window and return to Emacs.</p>"
                 "</body></html>")))
      (ignore-errors (delete-process proc)))))

(defun my/codex--start-callback-server ()
  "Start local OAuth callback listener on `my/codex-callback-port'."
  (setq my/codex--callback-result nil)
  (make-network-process
   :name "codex-oauth-server"
   :server t
   :host "127.0.0.1"
   :service my/codex-callback-port
   :family 'ipv4
   :coding 'utf-8
   :filter #'my/codex--callback-filter
   :log nil))

(defun my/codex-login ()
  "Authenticate to OpenAI Codex (ChatGPT subscription) via OAuth + PKCE.
Spins up a local HTTP server on 127.0.0.1:1455 to catch the redirect,
opens your browser to auth.openai.com, exchanges code+verifier for
tokens, saves to ~/.codex/auth.json (Pi-compatible schema)."
  (interactive)
  (let* ((pkce (my/codex--pkce-pair))
         (verifier (car pkce))
         (challenge (cdr pkce))
         (state (my/codex--gen-state))
         (auth-url
          (concat my/codex-oauth-host "/oauth/authorize?"
                  (mapconcat
                   (lambda (kv) (format "%s=%s"
                                        (url-hexify-string (car kv))
                                        (url-hexify-string (cdr kv))))
                   `(("response_type" . "code")
                     ("client_id"     . ,my/codex-client-id)
                     ("redirect_uri"  . ,my/codex-redirect-uri)
                     ("scope"         . ,my/codex-scope)
                     ("code_challenge" . ,challenge)
                     ("code_challenge_method" . "S256")
                     ("state"         . ,state)
                     ("id_token_add_organizations" . "true")
                     ("codex_cli_simplified_flow"  . "true")
                     ("originator"    . "emacs"))
                   "&"))))
    (my/codex--start-callback-server)
    (unwind-protect
        (progn
          (browse-url auth-url)
          (message "Codex login: browser opened. Waiting on localhost:%d… (C-g to cancel)"
                   my/codex-callback-port)
          (let ((waited 0) (poll 0.5) (timeout 600))
            (while (and (null my/codex--callback-result) (< waited timeout))
              (sit-for poll)
              (setq waited (+ waited poll)))))
      (let ((srv (get-process "codex-oauth-server")))
        (when srv (ignore-errors (delete-process srv)))))
    (unless my/codex--callback-result
      (user-error "Codex login timed out (10 min)"))
    (let* ((cb my/codex--callback-result)
           (cb-state (plist-get cb :state))
           (cb-code (plist-get cb :code)))
      (unless (equal cb-state state)
        (user-error "OAuth state mismatch — possible CSRF, aborting"))
      (unless cb-code
        (user-error "OAuth callback missing authorization code"))
      (message "Codex login: code received, exchanging for tokens…")
      (let ((resp (my/codex--exchange-code cb-code verifier)))
        (unless (alist-get 'access_token resp)
          (user-error "Codex token exchange failed: %S" resp))
        (my/codex--save-tokens resp)
        (message "Codex OAuth ✓ — tokens saved to %s" my/codex-credentials-file)))))

(defun my/codex-access-token ()
  "Return current Codex access token, refreshing if near expiry."
  (let ((data (my/codex--load-tokens)))
    (unless data
      (user-error "Codex credentials missing — run M-x my/codex-login (SPC a O)"))
    (let ((access (alist-get 'access data))
          (refresh (alist-get 'refresh data))
          (expires-ms (or (alist-get 'expires data) 0)))
      (if (> expires-ms (+ (* (float-time) 1000) 60000))
          access
        (unless refresh
          (user-error "No Codex refresh token; re-run M-x my/codex-login"))
        (message "Codex: refreshing OAuth token…")
        (let ((resp (my/codex--refresh-token refresh)))
          (unless (alist-get 'access_token resp)
            (user-error "Codex token refresh failed: %S" resp))
          (alist-get 'access (my/codex--save-tokens resp)))))))

(defun my/codex-account-id ()
  "Return chatgpt-account-id from saved Codex tokens (for backend header)."
  (or (alist-get 'accountId (my/codex--load-tokens))
      (user-error "No Codex accountId — run M-x my/codex-login")))

;; -----------------------------------------------------------------------------
;; Codex gptel backend — translates between Chat Completions (what gptel speaks)
;; and the OpenAI Responses API (what chatgpt.com/backend-api expects).
;; Non-streaming, non-tool-using.  ~70 lines — lightweight replacement
;; for Pi's 491-line openai-responses-shared.js (basic chat scope only).
;; -----------------------------------------------------------------------------

(with-eval-after-load 'gptel
  (require 'gptel-openai)
  (require 'gptel-anthropic)

  (eval
   '(cl-defstruct (gptel-codex (:include gptel-openai)
                               (:constructor gptel-codex--create)
                               (:copier nil))))

  (cl-defun my/gptel-make-codex (name &key models)
    "Register a gptel backend speaking the Codex Responses API.
Streaming + tool-use supported.  Auth via `my/codex-access-token'."
    (let* ((host "chatgpt.com")
           (endpoint "/backend-api/codex/responses")
           (backend (gptel-codex--create
                     :name name
                     :host host
                     :endpoint endpoint
                     :protocol "https"
                     :stream t
                      :coding-system 'utf-8
                      :models models
                      :header (lambda ()
                                `(("Authorization" . ,(concat "Bearer " (my/codex-access-token)))
                                  ("chatgpt-account-id" . ,(my/codex-account-id))
                                  ("Originator" . "emacs-gptel")))
                      :key #'my/codex-access-token
                      :url (concat "https://" host endpoint))))
      (setf (alist-get name gptel--known-backends nil nil #'equal) backend)
      backend))

;; ---- helpers: prompts -> Responses-API input items + tool defs translate ----

  (defun gptel-codex--flatten-text (content)
    "Reduce gptel's possibly-structured CONTENT to a single string.
`gptel-rewrite' (and other gptel paths) pass `:content' as a list or
vector of `(:type \"text\" :text STRING)' parts instead of a bare
string.  The Codex Responses API rejects that with
    \"Invalid type for 'input[N].content[N].text': expected a string,
     but got an array instead.\"
so we concatenate the inner `:text' fields into a single string."
    (cond
     ((null content) "")
     ((stringp content) content)
     ((or (listp content) (vectorp content))
      (mapconcat
       (lambda (part)
         (cond ((stringp part) part)
               ((and (listp part) (plist-get part :text))
                (gptel-codex--flatten-text (plist-get part :text)))
               (t "")))
       content
       ""))
     (t (format "%s" content))))

  (defun gptel-codex--prompts-to-input (prompts)
    "Translate gptel PROMPTS list into Responses API input items.
Handles: user/assistant text messages, assistant tool_calls (function_call
items), and role=tool messages (function_call_output items)."
  (let (items)
    (dolist (p prompts)
      (let ((role (if (stringp p) "user" (plist-get p :role))))
        (cond
         ((stringp p)
          (push `(:type "message"
                  :role "user"
                  :content [(:type "input_text" :text ,p)])
                items))
         ((equal role "tool")
          (push `(:type "function_call_output"
                  :call_id ,(plist-get p :tool_call_id)
                  :output ,(gptel-codex--flatten-text (plist-get p :content)))
                items))
         ((and (equal role "assistant") (plist-get p :tool_calls))
          (cl-loop for tc across (plist-get p :tool_calls)
                   for fn = (plist-get tc :function)
                   do (push `(:type "function_call"
                              :call_id ,(plist-get tc :id)
                              :name ,(plist-get fn :name)
                              :arguments ,(or (plist-get fn :arguments) ""))
                            items))
          (let ((c (gptel-codex--flatten-text (plist-get p :content))))
            (when (and c (not (string-empty-p c)))
              (push `(:type "message"
                      :role "assistant"
                      :content [(:type "output_text" :text ,c)])
                    items))))
         (t
          (let* ((text (gptel-codex--flatten-text (plist-get p :content)))
                 (ctype (if (equal role "assistant") "output_text" "input_text")))
            (push `(:type "message"
                    :role ,role
                    :content [(:type ,ctype :text ,text)])
                  items))))))
    (nreverse items)))

  (defun gptel-codex--tool-arg-properties (args)
    "Build a JSON Schema :properties plist from gptel-tool ARGS."
  (let (out)
    (dolist (a args)
      (let* ((name (plist-get a :name))
             (type (plist-get a :type))
             (type-str (cond ((symbolp type) (symbol-name type))
                             ((stringp type) type)
                             (t "string"))))
        (setq out (append out
                          (list (intern (format ":%s" name))
                                (list :type type-str
                                      :description (or (plist-get a :description) "")))))))
    out))

  (defun gptel-codex--tools-translate (tools)
    "Translate gptel TOOLS (`gptel-tool' structs) to Responses-API tool defs.
Differs from Chat Completions by flattening :function fields."
  (vconcat
   (mapcar
    (lambda (tool)
      (let ((args (gptel-tool-args tool)))
        `(:type "function"
          :name ,(gptel-tool-name tool)
          :description ,(or (gptel-tool-description tool) "")
          :parameters (:type "object"
                       :properties ,(gptel-codex--tool-arg-properties args)
                       :required ,(vconcat
                                   (cl-loop for a in args
                                            unless (plist-get a :optional)
                                            collect (plist-get a :name)))))))
    tools)))

;; ---- request body builder -----------------------------------------------

  (cl-defmethod gptel--request-data ((_backend gptel-codex) prompts)
    "Build Codex Responses API body from gptel PROMPTS, with tools+stream."
  (let* ((sys (or gptel--system-message ""))
         (input (vconcat (gptel-codex--prompts-to-input prompts)))
         (body `(:model ,(gptel--model-name gptel-model)
                 :instructions ,sys
                 :input ,input
                  :stream ,(if gptel-stream t :json-false)
                 :store :json-false)))
    (when (and gptel-use-tools gptel-tools)
      (plist-put body :tools (gptel-codex--tools-translate gptel-tools))
      (when (eq gptel-use-tools 'force)
        (plist-put body :tool_choice "required")))
    body))

;; ---- non-streaming response parser --------------------------------------

  (cl-defmethod gptel--parse-response ((_backend gptel-codex) response info)
    "Parse a Codex Responses API non-streaming RESPONSE."
  (let* ((output (plist-get response :output))
         text-pieces tool-uses)
    (when (vectorp output)
      (cl-loop for item across output
               for itype = (plist-get item :type)
               do (cond
                   ((equal itype "message")
                    (let ((c (plist-get item :content)))
                      (when (vectorp c)
                        (cl-loop for seg across c
                                 when (equal (plist-get seg :type) "output_text")
                                 do (push (plist-get seg :text) text-pieces)))))
                   ((equal itype "function_call")
                    (push (list :id (plist-get item :call_id)
                                :name (plist-get item :name)
                                :args (ignore-errors
                                        (gptel--json-read-string
                                         (or (plist-get item :arguments) "{}"))))
                          tool-uses)))))
    (plist-put info :output-tokens
               (map-nested-elt response '(:usage :output_tokens)))
    (when tool-uses
      (plist-put info :tool-use (nreverse tool-uses)))
    (apply #'concat (nreverse text-pieces))))

;; ---- streaming SSE parser -----------------------------------------------
;; Responses API stream event types we handle:
;;   response.output_text.delta            -> append text
;;   response.output_item.added (function_call) -> start new tool call
;;   response.function_call_arguments.delta -> accumulate args
;;   response.function_call_arguments.done  -> finalize args on current tool
;;   response.completed                    -> finalize tool-use into INFO

  (cl-defmethod gptel-curl--parse-stream ((_backend gptel-codex) info)
    "Parse a Codex Responses-API SSE stream chunk."
  (let (content-strs)
    (condition-case nil
        (while (re-search-forward "^data:[ \t]*" nil t)
          (save-match-data
            (let ((evt (gptel--json-read)))
              (when evt
                (let ((typ (plist-get evt :type)))
                  (cond
                   ((equal typ "response.output_text.delta")
                    (let ((d (plist-get evt :delta)))
                      (when (and (stringp d) (not (string-empty-p d)))
                        (push d content-strs))))
                   ((equal typ "response.output_item.added")
                    (let* ((item (plist-get evt :item))
                           (itype (plist-get item :type)))
                      (when (equal itype "function_call")
                        (plist-put info :tool-use
                                   (cons (list :id (or (plist-get item :call_id)
                                                       (plist-get item :id))
                                               :function
                                               (list :name (plist-get item :name)
                                                     :arguments ""))
                                         (plist-get info :tool-use)))
                        (plist-put info :partial_json nil))))
                   ((equal typ "response.function_call_arguments.delta")
                    (let ((d (plist-get evt :delta)))
                      (when (stringp d)
                        (plist-put info :partial_json
                                   (cons d (plist-get info :partial_json))))))
                   ((equal typ "response.function_call_arguments.done")
                    (let* ((tu (plist-get info :tool-use))
                           (current (car tu))
                           (args (apply #'concat
                                        (nreverse (plist-get info :partial_json)))))
                      (when current
                        (plist-put (plist-get current :function) :arguments args))
                      (plist-put info :partial_json nil)))
                   ((equal typ "response.completed")
                    (when-let* ((tu (plist-get info :tool-use)))
                      (gptel--inject-prompt
                       (plist-get info :backend) (plist-get info :data)
                       `(:role "assistant"
                         :tool_calls
                         ,(vconcat
                           (mapcar
                            (lambda (tc)
                              `(:id ,(plist-get tc :id)
                                :type "function"
                                :function (:name ,(plist-get (plist-get tc :function) :name)
                                           :arguments ,(plist-get (plist-get tc :function) :arguments))))
                            tu))))
                      (plist-put info :tool-use
                                 (cl-loop for tc in tu
                                          for fn = (plist-get tc :function)
                                          collect (list :id (plist-get tc :id)
                                                        :name (plist-get fn :name)
                                                        :args (ignore-errors
                                                                (gptel--json-read-string
                                                                 (plist-get fn :arguments))))))))))))))
      (error (goto-char (match-beginning 0))))
    (apply #'concat (nreverse content-strs))))

;; ---- tool result translation: function_call_output input items -----------

  (cl-defmethod gptel--parse-tool-results ((_backend gptel-codex) tool-use)
    "Return Responses-API input items for completed TOOL-USE results."
  (mapcar (lambda (tc)
            (list :role "tool"
                  :tool_call_id (plist-get tc :id)
                  :content (or (plist-get tc :result) "")))
          tool-use))

  )

(defun my/kimi-login ()
  "Authenticate to the Kimi K2 Coding Plan via OAuth device flow.
Pure elisp — no external CLI required.  Opens your browser to
kimi.com, displays the user code, polls until you confirm, then
writes `my/kimi-credentials-file' (interop with pi-kimi-coder +
kimi-cli, mode 0600).  After success, gptel's Kimi-Coder backend
works immediately."
  (interactive)
  (let* ((auth (my/kimi--request-device-code))
         (user-code (alist-get 'user_code auth))
         (device-code (alist-get 'device_code auth))
         (interval (or (alist-get 'interval auth) 5))
         (uri (or (alist-get 'verification_uri_complete auth)
                  (alist-get 'verification_uri auth))))
    (kill-new user-code)
    (browse-url uri)
    (message "Kimi login: code %s (copied).  Polling auth.kimi.com…" user-code)
    (let ((token (my/kimi--build-token
                  (my/kimi--poll-token device-code interval))))
      (my/kimi--save-token token)
      (message "Kimi OAuth ✓ — token saved to %s" my/kimi-credentials-file))))

(defun my/gptel-add-openai-backend (name host key models endpoint)
  "Register a custom OpenAI-compatible backend at runtime.
Use this for LiteLLM proxies, OpenRouter, internal gateways, or any
server that exposes the OpenAI `/v1/chat/completions' shape.

Prompts:
  NAME      — display name, shown in `gptel-menu' (e.g. \"Work-LiteLLM\")
  HOST      — hostname only, no protocol (e.g. \"litellm.acme.com\")
  KEY       — API key.  Defaults to env var `LITELLM_API_KEY' if set
              (just hit RET to use it); otherwise prompted via `read-passwd'
              so it doesn't leak into history.
  MODELS    — comma-separated model names (e.g. \"claude-opus-4-7,gpt-5\")
  ENDPOINT  — path. Most proxies use \"/v1/chat/completions\".

The backend persists for the rest of the daemon's lifetime.  To make it
survive a daemon restart, after registering call:
  M-x customize-save-variable RET gptel--known-backends"
  (interactive
   (let* ((default-key (getenv "LITELLM_API_KEY")))
     (list (read-string "Backend name: " "Work-LiteLLM")
           (read-string "Host (no https://): " "litellm.example.com")
           (if (and default-key (not (string-empty-p default-key)))
               default-key
             (read-passwd "API key (hidden): "))
           (read-string "Models (comma-separated): "
                        "claude-opus-4-7,claude-sonnet-4-6,gpt-5")
           (read-string "Endpoint path: " "/v1/chat/completions"))))
  (require 'gptel)
  (require 'gptel-openai)
  (let ((key-fn (lambda () key)))
    (gptel-make-openai name
      :host host
      :endpoint endpoint
      :protocol "https"
      :stream t
      :key key-fn
      :models (mapcar #'intern
                      (split-string (or models "") "," t " *"))))
  (message "Backend `%s' registered. Switch via SPC a m → Backend." name))

(use-package gptel
  :defer t
  :commands (gptel gptel-send
              my/gptel-feedback-line my/gptel-add-openai-backend
              my/gptel-load-skill my/gptel-load-project-context
              my/gptel-project-chat my/gptel-menu my/gptel-rewrite-region-prompt
              my/kimi-login my/codex-login)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "a"   '(:ignore t :which-key "ai")
        "a a" '(gptel                          :which-key "chat (ephemeral)")
        "a C" '(my/gptel-project-chat          :which-key "chat (project, persistent)")
        "a s" '(gptel-send                     :which-key "send region")
        "a r" '(my/gptel-rewrite-region-prompt :which-key "rewrite region")
        "a l" '(my/gptel-feedback-line         :which-key "feedback on line")
        "a k" '(my/gptel-load-skill            :which-key "load skill (SKILL.md)")
        "a c" '(my/gptel-load-project-context  :which-key "load CLAUDE/AGENTS/MEMORY")
        "a b" '(my/gptel-add-openai-backend    :which-key "add backend (LiteLLM/...)")
        "a L" '(my/kimi-login                  :which-key "kimi OAuth (device flow)")
        "a O" '(my/codex-login                 :which-key "OpenAI/Codex OAuth (PKCE)")
        "a m" '(my/gptel-menu                  :which-key "menu (model/system/tools)"))))
  :config
  ;; --- Backends + model defaults --------------------------------
  ;; Register Claude, but don't make it the startup default unless its
  ;; API key exists.  The default is restored or chosen after the local
  ;; OAuth backends are registered below.
  (gptel-make-anthropic "Claude"
    :stream t
    :key (lambda () (getenv "ANTHROPIC_API_KEY")))
  (setq gptel-default-mode 'markdown-mode
        gptel-track-response t
        gptel-track-media t)

  ;; --- Kimi K2 Coding Plan (OAuth subscription) -----------------
  ;; Subscription traffic goes to `api.kimi.com/coding/v1' (NOT
  ;; `api.moonshot.ai' — that's the pay-per-token Open Platform).
  ;; OAuth flow is implemented above in `my/kimi-login' (pure elisp).
  ;; This backend is registered UNCONDITIONALLY so a fresh-VM rebuild
  ;; gives you Kimi-Coder in `SPC a m → Backend' immediately; the
  ;; credentials check happens at request time with a clear error.
  (defun my/kimi-coder-access-token ()
    "Return the current Kimi access token, refreshing if near expiry.
Signals user-error if no credentials exist — run M-x my/kimi-login
(SPC a L) to OAuth-authenticate first."
    (unless (file-readable-p my/kimi-credentials-file)
      (user-error
       "Kimi credentials missing.  Run M-x my/kimi-login (SPC a L) to authenticate."))
    (let* ((data (with-temp-buffer
                   (insert-file-contents my/kimi-credentials-file)
                   (let ((json-object-type 'alist))
                     (json-read-from-string (buffer-string)))))
           (access     (alist-get 'access_token data))
           (refresh    (alist-get 'refresh_token data))
           (expires-at (or (alist-get 'expires_at data) 0)))
      (if (> expires-at (+ (float-time) my/kimi-refresh-skew-seconds))
          access
        ;; Stale or near-stale — refresh and persist.
        (unless refresh
          (user-error "No refresh_token in credentials — run M-x my/kimi-login"))
        (message "Kimi: refreshing OAuth token…")
        (let ((token (my/kimi--build-token (my/kimi--refresh-token refresh))))
          (my/kimi--save-token token)
          (alist-get 'access_token token)))))
  (gptel-make-openai "Kimi-Coder"
    :host "api.kimi.com"
    :endpoint "/coding/v1/chat/completions"
    :protocol "https"
    :stream t
    :key #'my/kimi-coder-access-token
    ;; api.kimi.com checks User-Agent and rejects requests without an
    ;; agent-style UA.  KimiCLI/1.5 is the value pi-kimi-coder uses.
    :header (lambda ()
              (let ((token (my/kimi-coder-access-token)))
                (unless (and (stringp token) (not (string= token "")))
                  (user-error "Kimi OAuth access token missing — run M-x my/kimi-login"))
                `(("Authorization" . ,(concat "Bearer " token))
                  ("User-Agent" . "KimiCLI/1.5"))))
    :models '(kimi-for-coding kimi-k2.6 kimi-k2-thinking))

  ;; --- Codex (ChatGPT subscription, OAuth) ----------------------
  ;; Auth: `M-x my/codex-login' (SPC a O).  Token in ~/.codex/auth.json.
  ;; Uses a custom `gptel-codex' backend (defined above) that translates
  ;; between gptel's Chat Completions shape and the Responses API shape
  ;; chatgpt.com/backend-api expects.  Non-streaming, no tool-use yet.
  (my/gptel-make-codex "Codex"
    :models '(gpt-5.5 gpt-5.4-mini gpt-5.4 gpt-5.3-codex))

  (my/gptel--restore-or-choose-default)
  (remove-variable-watcher 'gptel-backend #'my/gptel--selection-watcher)
  (remove-variable-watcher 'gptel-model #'my/gptel--selection-watcher)
  (add-variable-watcher 'gptel-backend #'my/gptel--selection-watcher)
  (add-variable-watcher 'gptel-model #'my/gptel--selection-watcher)

  ;; --- Auto-load project agent context on every chat -----------
  ;; New gptel chat buffer opened in a project dir → reads CLAUDE.md /
  ;; AGENTS.md / MEMORY.md / .cursorrules / GEMINI.md from project root.
  ;; Silent in non-project dirs.  Manual reload anytime via `SPC a c'.
  (add-hook 'gptel-mode-hook #'my/gptel-maybe-load-project-context)

  ;; --- Directives: named system prompts ------------------------
  ;; Switch via `gptel-menu' (SPC a m) → System Message.  Pick the
  ;; right hat instead of restating context every chat.
  (setq gptel-directives
        '((default . "You are an expert programmer. Be terse and direct. No filler.")
          (nix     . "You are a nix-darwin / home-manager expert. Answer with idiomatic nix flake patterns, per-module enable flags, nixpkgs option names. No fluff.")
          (elisp   . "You are an emacs-lisp expert. Prefer use-package + general.el patterns. Show minimal working examples. Use built-ins before adding packages.")
          (review  . "You are a senior code reviewer. Identify bugs, security issues, performance problems, missing edge cases. One concrete issue per line, file:line where possible.")
          (explain . "Explain what this code does. Highlight non-obvious behavior, hidden invariants, side effects. Note anything that would surprise a reader.")
          (shell   . "You are a POSIX shell + GNU coreutils expert. One-line solutions when possible. Call out macOS BSD-vs-GNU differences.")))

  ;; --- Tools: function calling (READ-ONLY shipped by default) --
  ;; Per-chat toggle: SPC a m → Tools.  To add file-write or shell-
  ;; exec tools, define them with `gptel-make-tool' AND add explicit
  ;; confirmation prompts (see gptel docs).  Be cautious — these
  ;; run with full user privileges.
  (when (fboundp 'gptel-make-tool)
    (gptel-make-tool
     :name "read_file"
     :function (lambda (path)
                 (with-temp-buffer
                   (insert-file-contents (expand-file-name path))
                   (buffer-string)))
     :description "Read the contents of a file from the local filesystem. Pass an absolute or ~-rooted path."
     :args (list '(:name "path" :type string
                   :description "Filesystem path to read"))
     :category "fs")

    (gptel-make-tool
     :name "list_directory"
     :function (lambda (path)
                 (mapconcat #'identity
                            (directory-files (expand-file-name path) nil "^[^.]")
                            "\n"))
     :description "List non-hidden entries in a directory. One filename per line."
     :args (list '(:name "path" :type string
                   :description "Directory to list"))
     :category "fs")

    (setq gptel-use-tools t)))

;; --- HOW TO ADD A PER-PROJECT SYSTEM PROMPT ------------------
;; Drop a `.dir-locals.el' at your project root:
;;
;;   ((nil . ((gptel--system-message . "Stack: Python 3.12 + uv + duckdb.
;;             Prefer polars for hot paths, pandas for transforms.
;;             Test framework: pytest. Project: kalshi-weather-bot."))))
;;
;; Any gptel chat started from a buffer in that project picks it up
;; automatically.  Saves restating project context every conversation.

;; --- gptel-rewrite formatting policy --------------------------------
(defvar my/gptel-rewrite-whole-buffer-format-modes
  '(go-mode go-ts-mode rust-mode rust-ts-mode nix-mode nix-ts-mode)
  "Major modes for which `gptel--rewrite-accept' formats the WHOLE
buffer after accept (via the LSP's format-buffer).  Other modes get
range-only formatting so user's manual formatting elsewhere is
preserved.  Add modes here where canonical formatting is universal
and you don't keep deliberate custom formatting (Go/gofmt,
Rust/rustfmt, Nix/nixfmt).")

;; --- gptel-rewrite: indent inserted text to match destination ------
;;
;; LLMs routinely return code at column 0 even when the original was
;; inside a method/block — `gptel--rewrite-accept' just `insert's
;; the response verbatim, so it lands flush left.  We run the
;; major-mode's indent function over the freshly inserted region
;; (treesit-indent for *-ts-mode buffers, c-indent-region for c-mode,
;; etc.) so it drops in correctly.
;;
;; Captures (buffer, start, response-length) BEFORE the original
;; accept runs and uses those to compute the inserted region.  For
;; single-overlay accepts (the typical case) this is exact; for
;; multi-overlay accepts later overlays' positions may shift, so
;; the second+ regions are best-effort.
(defun my/gptel--rewrite-indent-around (orig-fn &optional ovs buf)
  "Around `gptel--rewrite-accept': make the inserted region land
indented and canonically formatted.  Three layers, each falls back
gracefully:

  1. Force the tree-sitter parser (and syntax cache) to refresh
     before indenting — without this the indent intermittently uses
     stale node positions and either over-indents or leaves things
     flush-left depending on timing.
  2. `indent-region' over the inserted span via the major-mode's
     `indent-line-function' (treesit-indent for *-ts-mode, etc.).
  3. If eglot is managing the buffer, `eglot-format' the same span
     — gopls/pyright/nil/etc. invoke the canonical formatter
     (gofmt, ruff, nixfmt, …) which fixes anything indent-region
     missed and also tidies spacing/blank-line conventions.

Multi-overlay accepts: positions of overlays after the first may
have shifted by the time we indent.  We trust the first region;
later ones are best-effort."
  (let* ((ov-list (ensure-list ovs))
         (regions
          (mapcar (lambda (ov)
                    (list (overlay-buffer ov)
                          (overlay-start ov)
                          (length (or (overlay-get ov 'gptel-rewrite) ""))))
                  ov-list)))
    (funcall orig-fn ovs buf)
    (dolist (r regions)
      (let ((dbuf  (nth 0 r))
            (start (nth 1 r))
            (rlen  (nth 2 r)))
        (when (and dbuf (buffer-live-p dbuf) start (> rlen 0))
          (with-current-buffer dbuf
            (let ((end (min (+ start rlen) (point-max))))
              ;; --- 1) flush stale parser/syntax state ---
              (ignore-errors (syntax-ppss-flush-cache start))
              (ignore-errors (font-lock-flush start end))
              (when (and (fboundp 'treesit-parser-list)
                         (treesit-parser-list))
                (dolist (p (treesit-parser-list))
                  ;; Forces a parse by walking the root node — cheap,
                  ;; happens entirely in the tree-sitter library.
                  (ignore-errors (treesit-parser-root-node p))))
              ;; --- 2) indent-region (mode's native indenter) ---
              (save-excursion
                (when indent-line-function
                  (ignore-errors (indent-region start end))))
              ;; --- 3) eglot-format: per-mode whole-buffer vs range ---
              ;; For languages where canonical formatting is universal
              ;; (Go/gofmt, Rust/rustfmt, Nix/nixfmt — gofmt-style
              ;; conventions), do whole-buffer format because gopls'
              ;; range-format is finicky on partial syntax and the
              ;; buffer is by convention always canonically formatted
              ;; anyway, so a buffer-format is a no-op outside the
              ;; rewrite region.  For every other language, range-only
              ;; so the user's manual formatting elsewhere is preserved.
              ;;
              ;; If you want the rewrite to look good in a range-only
              ;; mode where it didn't auto-clean, run
              ;; `M-x apheleia-format-buffer' or
              ;; `M-x eglot-format-buffer' on demand.
              (when (and (fboundp 'eglot-managed-p)
                         (eglot-managed-p))
                (save-excursion
                  (if (memq major-mode my/gptel-rewrite-whole-buffer-format-modes)
                      (when (fboundp 'eglot-format-buffer)
                        (ignore-errors (eglot-format-buffer)))
                    (when (fboundp 'eglot-format)
                      (ignore-errors (eglot-format start end)))))))))))))

(with-eval-after-load 'gptel-rewrite
  (advice-add 'gptel--rewrite-accept :around #'my/gptel--rewrite-indent-around))

;; Cosmetic: tell the model to match indent so the overlay preview
;; also looks right (final accept is corrected regardless by the
;; advice above).  This hook is invoked when `gptel--rewrite-message'
;; is nil; if you already have a per-mode rewrite directive that you
;; want to keep, edit that directive to include the same instruction.
(defun my/gptel-rewrite-default-directive ()
  "Default rewrite directive: preserve indentation."
  (concat "Refactor the code I provide.\n"
          "- Output only code, no explanation, no markdown fences.\n"
          "- Preserve the exact indentation of the original snippet — "
          "if the snippet starts with leading tabs/spaces, keep them.\n"
          "- Generate code in full, do not abbreviate."))

(with-eval-after-load 'gptel-rewrite
  (add-hook 'gptel-rewrite-directives-hook
            #'my/gptel-rewrite-default-directive))

;; --- agent-shell: ACP-protocol agentic LLM shell --------------------
;; Complement to gptel (not a replacement).  gptel is "chat with an
;; LLM about code"; agent-shell is "an agent operates on files".
;;
;; The emacs side speaks ACP (Agent Client Protocol) over stdio to a
;; backend CLI.  agent-shell ships per-backend modules — start fn is
;; always `agent-shell-<backend>-start-agent'.  Supported backends in
;; upstream: opencode, claude-code (anthropic), codex (openai), gemini
;; (google), goose, auggie, cline, cursor, droid, github, hermes,
;; kimi, kiro, mistral, pi, qwen.
;;
;; Bindings:
;;   SPC a A  open the default agent (opencode — you already have it
;;            on PATH via nix; nothing to install).
;;   SPC a M-A  pick a different agent interactively via `agent-shell'.
(use-package agent-shell
  :defer t
  :commands (agent-shell
             agent-shell-opencode-start-agent
             agent-shell-anthropic-start-agent
             agent-shell-openai-start-agent
             agent-shell-google-start-agent
             agent-shell-goose-start-agent)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "a A"   '(agent-shell-opencode-start-agent :which-key "agent (opencode)")
        "a M-A" '(agent-shell                      :which-key "agent (pick…)")))))

(provide 'config-llm)
;;; config-llm.el ends here
