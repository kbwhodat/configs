;;; config-llm.el --- LLM tooling (agent-shell + ACP) -*- lexical-binding: t; -*-
;;; Commentary:
;; agent-shell over Agent Client Protocol (ACP) is the sole LLM
;; interaction surface.  Previously this file also wired gptel +
;; custom Kimi/Codex OAuth flows + a hand-rolled OpenAI Responses-API
;; backend; all of that was dropped 2026-05-30 in favour of one
;; agentic tool that covers chat AND tool-using workflows uniformly.
;;
;; ACP wire bridge is `claude-agent-acp', installed as a nix-managed
;; binary via pkgs/by-name/claude-agent-acp/.  agent-shell itself
;; ships per-backend entry-point names — not uniform — so :commands
;; lists each one explicitly.
;;; Code:

;; --- Quick region rewrite via `claude' CLI -------------------------
;; agent-shell is great for tasks but its permission-prompt + diff
;; review flow adds 10-15 s of friction for trivial transforms
;; ("convert to defun", "add nil-guard").  gptel-rewrite was the right
;; tool for those — instant in-place replacement.  Since gptel is
;; dropped, re-implement that one-feature against the `claude' CLI
;; (`--print' mode = stdin → Claude → stdout, same auth, same model
;;  as `claude-agent-acp', no new dependency).
;;
;; Flow:
;;   1. Select region (any major mode)
;;   2. SPC a r → minibuffer prompt "Rewrite:"
;;   3. Type instruction, RET
;;   4. Region replaced in place with claude's response
;;
;; Strips any ```language fences claude wraps around the response
;; (LLMs do that even when told not to) so the buffer stays clean.

(defcustom my/claude-rewrite-system-prompt
  (concat
   "You are rewriting a code/text snippet that will REPLACE the user's selection in their editor.\n"
   "\n"
   "Output rules (STRICT):\n"
   "- Output ONLY the replacement content.\n"
   "- NO markdown code fences (```), NO language tag, NO preamble, NO explanation, NO trailing commentary.\n"
   "- Preserve the EXACT leading indentation of every line you output, matching the indentation level of the snippet you were given.\n"
   "- Preserve the original style of the file (tabs vs spaces, indent width, trailing newline).\n"
   "- If the snippet had a trailing newline, your output should too; if not, no extra newline.\n"
   "- If the user's instruction is unclear, make the most reasonable interpretation.  Do NOT ask for clarification.")
  "System prompt for `my/claude-rewrite-region'.  Tightened to keep
claude from wrapping output in markdown fences or shifting
indentation — the two failure modes that made the response unusable
as a direct buffer replacement."
  :type 'string
  :group 'agent-shell)

(defcustom my/claude-rewrite-context-lines 4
  "How many lines BEFORE and AFTER the selected region to include
as surrounding context in the claude prompt.  Helps claude infer the
language, indentation level, and local conventions without exposing
the whole file.  0 disables context.  ~4 covers most use cases without
blowing up the prompt."
  :type 'integer
  :group 'agent-shell)

(defun my/claude-rewrite--strip-fences (text)
  "Remove ```lang ... ``` wrapping that LLMs add even when told not to.
Only strips if the FIRST line is a fence and the LAST line is a fence —
won't damage prose that happens to contain backticks mid-content."
  (let ((trimmed (string-trim text)))
    (if (and (string-match-p "\\````[a-zA-Z0-9_+-]*\n" trimmed)
             (string-match-p "\n```\\'" trimmed))
        (replace-regexp-in-string
         "\\````[a-zA-Z0-9_+-]*\n\\|\n```\\'" "" trimmed)
      text)))

(defun my/claude-rewrite--surrounding-context (beg end nlines)
  "Return up to NLINES lines before BEG and after END as context strings.
Returns (BEFORE . AFTER) where each side is a string ending in a
newline (or empty if no context available).  Used to give claude
enough surrounding code to infer indentation level + local conventions
without sending the whole file."
  (if (<= nlines 0)
      (cons "" "")
    (cons
     (save-excursion
       (goto-char beg)
       (let ((ctx-start (save-excursion
                          (forward-line (- nlines))
                          (point))))
         (buffer-substring-no-properties ctx-start beg)))
     (save-excursion
       (goto-char end)
       (let ((ctx-end (save-excursion
                        (forward-line (1+ nlines))
                        (point))))
         (buffer-substring-no-properties end ctx-end))))))

(defun my/claude-rewrite--language ()
  "Return a short language tag for the current buffer (e.g. \"python\",
\"elisp\", \"go\").  Falls back to major-mode name minus -mode."
  (let ((mode (symbol-name major-mode)))
    (replace-regexp-in-string "\\(-ts\\)?-mode\\'" "" mode)))

(defun my/claude-rewrite-region (instruction)
  "Replace the active region with claude's rewrite per INSTRUCTION.
Pipes region (with surrounding-line context, language tag, and
indent-style hints) → `claude --print' → response → replaces region.

Synchronous: blocks until claude responds (typically 2-8 s).  After
replacement, runs `indent-region' to normalize indent per the major
mode's rules — belt-and-suspenders against claude getting indent
slightly wrong.

If claude errors or returns empty, the region is left untouched."
  (interactive "sRewrite: ")
  (unless (use-region-p)
    (user-error "No region selected"))
  (unless (executable-find "claude")
    (user-error "`claude' CLI not found on PATH"))
  (when (string-empty-p (string-trim instruction))
    (user-error "Instruction is empty"))
  (let* ((beg (region-beginning))
         (end (region-end))
         (lang (my/claude-rewrite--language))
         (file (or (buffer-file-name) "(unnamed buffer)"))
         (line-start (line-number-at-pos beg))
         (indent-style (if indent-tabs-mode
                           "tabs"
                         (format "%d spaces" (or tab-width 4))))
         (ctx (my/claude-rewrite--surrounding-context
               beg end my/claude-rewrite-context-lines))
         (input (concat
                 ;; File metadata so claude can match conventions
                 (format "File: %s (line %d)\n" file line-start)
                 (format "Language: %s\n" lang)
                 (format "Indent style: %s\n\n" indent-style)
                 ;; Instruction
                 "Instruction: " instruction "\n\n"
                 ;; Surrounding context (claude can SEE indent level from
                 ;; the lines on either side; do NOT modify those lines)
                 (when (> (length (car ctx)) 0)
                   (concat "Lines BEFORE the selection (for context only "
                           "— do not modify or output these):\n"
                           (car ctx) "\n"))
                 ;; The actual snippet to rewrite
                 "Snippet to REPLACE (your output replaces exactly this, "
                 "preserving its leading indentation):\n"
                 (buffer-substring-no-properties beg end)
                 (when (> (length (cdr ctx)) 0)
                   (concat "\n\nLines AFTER the selection (for context "
                           "only — do not modify or output these):\n"
                           (cdr ctx)))))
         (output-buffer (generate-new-buffer " *claude-rewrite*")))
    (message "Asking claude…")
    (unwind-protect
        (let ((exit-code
               (with-temp-buffer
                 (insert input)
                 ;; (list BUF nil): stdout -> BUF, stderr -> DISCARDED.
                 ;; Capturing stderr into the output buffer spliced CLI
                 ;; warnings (e.g. permission-rule complaints) straight
                 ;; into the replacement text (observed 2026-07-22:
                 ;; "Permission deny rule ..." written into a note).
                 (call-process-region
                  (point-min) (point-max) "claude" nil
                  (list output-buffer nil) nil
                  "--print"
                  "--append-system-prompt" my/claude-rewrite-system-prompt))))
          (cond
           ((not (zerop exit-code))
            (message "claude exited %d — region untouched (rerun in a shell to see stderr)"
                     exit-code))
           (t
            (let* ((orig (buffer-substring-no-properties beg end))
                   (reply (my/claude-rewrite--strip-fences
                           (with-current-buffer output-buffer
                             (buffer-string)))))
              ;; Newline hygiene: make the reply's trailing-newline
              ;; shape MATCH the original region exactly.  LLM output
              ;; almost always ends in \n; if the selection didn't, a
              ;; stray blank line appeared on every mid-line rewrite.
              (setq reply (string-trim-right reply "\n+"))
              (when (string-suffix-p "\n" orig)
                (setq reply (concat reply "\n")))
              (cond
               ((string-empty-p (string-trim reply))
                (message "claude returned empty — region untouched"))
               (t
                (let ((insert-beg beg))
                  (delete-region beg end)
                  (goto-char insert-beg)
                  (insert reply)
                  ;; Re-indent only in code buffers.  In markdown/text,
                  ;; `indent-region' has no syntax to work from and just
                  ;; mangles whitespace.
                  (when (derived-mode-p 'prog-mode)
                    (indent-region insert-beg (point)))
                  (message "Rewrote %d → %d chars"
                           (- end beg) (length reply)))))))))
      (when (and output-buffer (buffer-live-p output-buffer))
        (kill-buffer output-buffer)))))

(use-package agent-shell
  :defer t
  ;; Per-backend start fns: claude-code (anthropic), opencode (default),
  ;; gemini (google), codex (openai), goose.  Names verified against
  ;; the installed `agent-shell-*.el' source files.
  :commands (agent-shell
             agent-shell-toggle
             agent-shell-prompt-compose
             agent-shell-send-region
             agent-shell-send-region-to
             agent-shell-send-dwim
             agent-shell-fork
             agent-shell-resume-session
             agent-shell-copy-session-id
             agent-shell-anthropic-start-claude-code
             agent-shell-opencode-start-agent
             agent-shell-google-start-gemini
             agent-shell-openai-start-codex
             agent-shell-goose-start-agent)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        ;; --- start a fresh agent buffer ---
        "a c"   '(agent-shell-anthropic-start-claude-code :which-key "agent: new Claude")
        "a A"   '(agent-shell-opencode-start-agent        :which-key "agent: new opencode")
        "a M-A" '(agent-shell                             :which-key "agent: new (pick…)")
        ;; --- buffer navigation ---
        "a t"   '(agent-shell-toggle                      :which-key "agent: toggle last")
        ;; --- prompting ---
        "a p"   '(agent-shell-prompt-compose              :which-key "agent: compose prompt")
        ;; --- region / selection commands ---
        ;; Select text in any buffer, then:
        ;;   SPC a s  send region (with file:line context) to last agent shell
        ;;   SPC a S  same, but PROMPT which shell (multi-session)
        ;;   SPC a d  DWIM: region | error-at-point | current line
        "a s"   '(agent-shell-send-region                 :which-key "agent: send region")
        "a S"   '(agent-shell-send-region-to              :which-key "agent: send region to…")
        "a d"   '(agent-shell-send-dwim                   :which-key "agent: send dwim")
        ;; --- quick rewrite (sidecar via `claude' CLI, no agent flow) ---
        ;; Select region, SPC a r, type instruction, hit RET → in-place
        ;; replacement.  See `my/claude-rewrite-region' for the impl.
        "a r"   '(my/claude-rewrite-region                :which-key "rewrite region (claude --print)")
        ;; --- session lifecycle ---
        "a f"   '(agent-shell-fork                        :which-key "agent: fork from here")
        "a R"   '(agent-shell-resume-session              :which-key "agent: resume by id")
        "a i"   '(agent-shell-copy-session-id             :which-key "agent: copy session id"))))
  :config
  ;; --- Trim trailing-newline overshoot from active region -----------
  ;; Evil's `V' (visual-line) and Emacs's line-selecting commands place
  ;; `region-end' at column 0 of the line AFTER the highlighted text.
  ;; agent-shell takes that literally — `:line-end' becomes line+1, and
  ;; the numbered preview's `(while (<= current end-line))' loop
  ;; iterates inclusively and dumps the overshoot line's content into
  ;; the prompt.  Net effect: a one-line selection gets sent as two
  ;; lines.  Around-advice on the three user-facing send commands
  ;; shrinks the region by one char when it ends at BOL before letting
  ;; agent-shell extract.  Upstream bug — remove this once fixed.
  (defun my/agent-shell--trim-region-overshoot (orig-fn &rest args)
    "Shrink trailing-newline overshoot before ORIG-FN reads the region."
    (if (and (region-active-p)
             (> (region-end) (region-beginning))
             (save-excursion (goto-char (region-end)) (bolp)))
        (let ((orig-mark (mark))
              (orig-point (point)))
          (unwind-protect
              (progn
                (if (> (point) (mark))
                    (goto-char (1- (point)))
                  (set-mark (1- (mark))))
                (activate-mark)
                (apply orig-fn args))
            ;; Restore the user's original selection so the visual
            ;; highlight isn't subtly altered (most send fns deactivate
            ;; mark via `:deactivate t', but be defensive).
            (set-mark orig-mark)
            (goto-char orig-point)))
      (apply orig-fn args)))
  (dolist (fn '(agent-shell-send-region
                agent-shell-send-region-to
                agent-shell-send-dwim))
    (advice-add fn :around #'my/agent-shell--trim-region-overshoot))

  ;; --- Shell-style line editing inside agent-shell buffers ----------
  ;; agent-shell is a regular buffer (not a minibuffer), so the C-u/C-w
  ;; rebinds in config-completion.el don't apply.  Bind the typical
  ;; bash/readline keys here so typing/editing the prompt feels like
  ;; any other terminal.  Bound in BOTH the mode map (covers emacs
  ;; state / non-evil callers) AND evil insert state explicitly
  ;; (because evil's insert state has its own bindings for C-u and
  ;; C-w that would otherwise shadow ours).
  (defun my/agent-shell-kill-input-backward ()
    "Kill from point backward to the beginning of the current line.
Bash-style C-u — wipes a half-typed prompt back to column 0."
    (interactive)
    (kill-line 0))

  (let ((map agent-shell-mode-map))
    (define-key map (kbd "C-a") #'move-beginning-of-line)
    (define-key map (kbd "C-e") #'move-end-of-line)
    (define-key map (kbd "C-k") #'kill-line)
    (define-key map (kbd "C-u") #'my/agent-shell-kill-input-backward)
    (define-key map (kbd "C-w") #'backward-kill-word))

  (with-eval-after-load 'evil
    (evil-define-key 'insert agent-shell-mode-map
      (kbd "C-a") #'move-beginning-of-line
      (kbd "C-e") #'move-end-of-line
      (kbd "C-k") #'kill-line
      (kbd "C-u") #'my/agent-shell-kill-input-backward
      (kbd "C-w") #'backward-kill-word)
    (evil-define-key 'normal agent-shell-mode-map
      (kbd "C-a") #'move-beginning-of-line
      (kbd "C-e") #'move-end-of-line))

  ;; --- Route agent-shell completion through company popup -----------
  ;; When you type `/' in agent-shell to get slash commands, agent-shell
  ;; calls `completion-at-point' directly.  Without intervention, that
  ;; falls through to emacs's vanilla `*Completions*' buffer ("Click or
  ;; type M-RET on a completion..." ugliness) instead of company's
  ;; nice in-buffer overlay popup.
  ;;
  ;; Two changes scoped to agent-shell buffers only (no impact on
  ;; coding buffers' company config):
  ;;   1. Lower `company-minimum-prefix-length' to 1 — single `/'
  ;;      should trigger the popup.
  ;;   2. Remap `completion-at-point' -> `company-complete' — so when
  ;;      agent-shell explicitly invokes completion, it goes through
  ;;      company's overlay renderer instead of vanilla *Completions*.
  (defun my/agent-shell-prefer-company ()
    "Make completion in this agent-shell buffer use company's overlay.
Specifically:
  - require + enable company here: agent-shell-mode derives from
    neither prog-mode nor text-mode, so the global hooks never load
    company — without this, a fresh daemon going straight into
    agent-shell hits void-function `company-complete' on `/'
  - lower `company-minimum-prefix-length' to 1 (popup on first char)
  - `company-idle-delay' 0.2 — debounces typing.  An earlier version
    used 0.0 (instant) but every keystroke synchronously called
    agent-shell's capf, which queries the agent over ACP — net result
    was per-character lag.  200ms still feels instant for the slash
    trigger but coalesces fast typing into one capf call.
  - disable `completion-auto-help' (no auto *Completions* buffer)
  - rewire `completion-in-region-function' to invoke company,
    catching paths my [remap completion-at-point] doesn't reach
    (e.g. when agent-shell calls `completion-in-region' directly)."
    (require 'company)
    (company-mode 1)
    (setq-local company-minimum-prefix-length 1
                company-idle-delay 0.2
                completion-auto-help nil
                completion-in-region-function
                (lambda (&rest _) (company-complete))))
  (add-hook 'agent-shell-mode-hook #'my/agent-shell-prefer-company)
  (define-key agent-shell-mode-map [remap completion-at-point] #'company-complete))

(provide 'config-llm)
;;; config-llm.el ends here
