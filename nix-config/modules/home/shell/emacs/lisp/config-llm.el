;;; config-llm.el --- LLM chat (gptel) -*- lexical-binding: t; -*-
;;; Commentary:
;; Provider API keys come from environment variables set in shell, not here.
;;; Code:

(use-package gptel
  :defer t
  :commands (gptel gptel-send gptel-menu)
  :init
  (with-eval-after-load 'general
    (when (fboundp 'my/leader)
      (my/leader
        "l l" '(gptel      :which-key "chat")
        "l s" '(gptel-send :which-key "send")
        "l m" '(gptel-menu :which-key "menu")))))

(provide 'config-llm)
;;; config-llm.el ends here
