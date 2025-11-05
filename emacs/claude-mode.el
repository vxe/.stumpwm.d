;;; claude-mode.el --- Claude AI integration for Emacs + StumpWM  -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Vijay Edwin

;; Author: Vijay Edwin
;; Version: 0.1
;; Package-Requires: ((emacs "26.1") (request "0.3.0"))
;; Keywords: ai, claude, assistant, window-manager
;; URL: https://github.com/yourusername/stumpwm-claude

;;; Commentary:

;; This package integrates Claude AI into Emacs, allowing you to:
;; - Ask Claude questions about code or system state
;; - Generate code and execute it in StumpWM
;; - Get intelligent suggestions for window management
;; - Interact with Claude through a dedicated buffer

;;; Code:

(require 'json)
(require 'url)
(require 'stumpctl nil t)

;;;; Configuration

(defgroup claude-mode nil
  "Claude AI integration for Emacs."
  :group 'tools
  :prefix "claude-")

(defcustom claude-api-key (getenv "CLAUDE_API_KEY")
  "API key for Claude AI."
  :type 'string
  :group 'claude-mode)

(defcustom claude-api-endpoint "https://api.anthropic.com/v1/messages"
  "API endpoint for Claude."
  :type 'string
  :group 'claude-mode)

(defcustom claude-model "claude-3-5-sonnet-20241022"
  "Claude model to use."
  :type 'string
  :group 'claude-mode)

(defcustom claude-max-tokens 4096
  "Maximum tokens for Claude responses."
  :type 'integer
  :group 'claude-mode)

(defcustom claude-timeout 30
  "Timeout for Claude API requests in seconds."
  :type 'integer
  :group 'claude-mode)

;;;; State

(defvar claude--conversation-history nil
  "History of conversation with Claude.")

(defvar claude--last-response nil
  "Last response from Claude.")

(defvar claude--buffer-name "*Claude*"
  "Name of the Claude interaction buffer.")

;;;; API Functions

(defun claude--make-request (prompt system-prompt callback)
  "Make a request to Claude API with PROMPT and SYSTEM-PROMPT.
Call CALLBACK with the response text."
  (unless claude-api-key
    (error "Claude API key not set. Set CLAUDE_API_KEY environment variable"))

  (let* ((url-request-method "POST")
         (url-request-extra-headers
          `(("Content-Type" . "application/json")
            ("x-api-key" . ,claude-api-key)
            ("anthropic-version" . "2023-06-01")))
         (url-request-data
          (json-encode
           `(("model" . ,claude-model)
             ("max_tokens" . ,claude-max-tokens)
             ("system" . ,system-prompt)
             ("messages" . [((("role" . "user")
                             ("content" . ,prompt)))])))))

    (url-retrieve
     claude-api-endpoint
     (lambda (status)
       (if (plist-get status :error)
           (error "Claude API request failed: %s" (plist-get status :error))
         (goto-char (point-min))
         (re-search-forward "\n\n")
         (let* ((response (json-read))
                (content (aref (cdr (assoc 'content response)) 0))
                (text (cdr (assoc 'text content))))
           (funcall callback text))))
     nil
     t ; silent
     t))) ; inhibit-cookies

(defun claude-ask-sync (prompt &optional system-prompt)
  "Ask Claude PROMPT synchronously and return response.
Optional SYSTEM-PROMPT provides context."
  (let ((result nil)
        (done nil))
    (claude--make-request
     prompt
     (or system-prompt "You are a helpful AI assistant.")
     (lambda (response)
       (setq result response
             done t)))
    ;; Wait for response
    (while (not done)
      (sleep-for 0.1))
    result))

;;;; Buffer Management

(defun claude--get-buffer ()
  "Get or create the Claude buffer."
  (get-buffer-create claude--buffer-name))

(defun claude--insert-message (sender message)
  "Insert MESSAGE from SENDER into Claude buffer."
  (with-current-buffer (claude--get-buffer)
    (goto-char (point-max))
    (insert (propertize (format "\n%s:\n" sender)
                       'face 'bold))
    (insert message)
    (insert "\n")
    (goto-char (point-max))))

(defun claude--show-buffer ()
  "Show the Claude buffer."
  (display-buffer (claude--get-buffer)))

;;;; Interactive Commands

;;;###autoload
(defun claude-ask (prompt)
  "Ask Claude a question with PROMPT."
  (interactive "sAsk Claude: ")
  (claude--show-buffer)
  (claude--insert-message "You" prompt)
  (claude--insert-message "Claude" "Thinking...")

  (claude--make-request
   prompt
   "You are a helpful AI assistant integrated into Emacs and StumpWM. Be concise and practical."
   (lambda (response)
     ;; Remove "Thinking..." message
     (with-current-buffer (claude--get-buffer)
       (goto-char (point-max))
       (forward-line -1)
       (delete-region (point) (point-max)))
     ;; Insert actual response
     (claude--insert-message "Claude" response)
     (setq claude--last-response response)
     (message "Claude responded"))))

;;;###autoload
(defun claude-ask-about-region (start end)
  "Ask Claude about the region from START to END."
  (interactive "r")
  (let* ((text (buffer-substring-no-properties start end))
         (prompt (read-string "Ask about this code: "
                            "What does this code do? ")))
    (claude-ask (format "%s\n\n```\n%s\n```" prompt text))))

;;;###autoload
(defun claude-explain-code (start end)
  "Ask Claude to explain code in region from START to END."
  (interactive "r")
  (let ((code (buffer-substring-no-properties start end)))
    (claude-ask (format "Explain this code concisely:\n\n```\n%s\n```" code))))

;;;###autoload
(defun claude-improve-code (start end)
  "Ask Claude to suggest improvements for code in region."
  (interactive "r")
  (let ((code (buffer-substring-no-properties start end)))
    (claude-ask (format "Suggest improvements for this code:\n\n```\n%s\n```" code))))

;;;###autoload
(defun claude-generate-code (description)
  "Ask Claude to generate code based on DESCRIPTION."
  (interactive "sWhat code to generate: ")
  (claude-ask (format "Generate %s code:\n%s\n\nProvide clean, working code."
                     (symbol-name major-mode)
                     description)))

;;;; StumpWM Integration

;;;###autoload
(defun claude-stumpwm-ask (prompt)
  "Ask Claude about StumpWM with PROMPT."
  (interactive "sAsk Claude about StumpWM: ")
  (let ((system-prompt
         "You are an AI assistant for StumpWM, a tiling window manager in Common Lisp.
Provide Lisp code when appropriate. Be concise."))
    (claude--show-buffer)
    (claude--insert-message "You" prompt)
    (claude--insert-message "Claude" "Thinking...")

    (claude--make-request
     prompt
     system-prompt
     (lambda (response)
       (with-current-buffer (claude--get-buffer)
         (goto-char (point-max))
         (forward-line -1)
         (delete-region (point) (point-max)))
       (claude--insert-message "Claude" response)
       (setq claude--last-response response)))))

;;;###autoload
(defun claude-stumpwm-command (command-description)
  "Ask Claude to generate StumpWM command for COMMAND-DESCRIPTION."
  (interactive "sWhat should StumpWM do: ")
  (claude-stumpwm-ask
   (format "Generate StumpWM Lisp code to: %s\n\nProvide only the code in ```lisp blocks."
          command-description)))

;;;###autoload
(defun claude-execute-in-stumpwm ()
  "Execute the last Claude response in StumpWM (if it contains Lisp code)."
  (interactive)
  (unless (featurep 'stumpctl)
    (error "stumpctl.el not loaded"))
  (unless claude--last-response
    (error "No response from Claude yet"))

  ;; Extract Lisp code from response
  (let ((code (if (string-match "```lisp\n\\(\\(?:.\\|\n\\)*?\\)\n```"
                               claude--last-response)
                  (match-string 1 claude--last-response)
                nil)))
    (if code
        (progn
          (message "Executing in StumpWM: %s" (substring code 0 (min 50 (length code))))
          (stumpctl-eval code))
      (message "No Lisp code found in last response"))))

;;;; Buffer Mode

(defvar claude-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c a") 'claude-ask)
    (define-key map (kbd "C-c e") 'claude-explain-code)
    (define-key map (kbd "C-c i") 'claude-improve-code)
    (define-key map (kbd "C-c g") 'claude-generate-code)
    (define-key map (kbd "C-c s") 'claude-stumpwm-ask)
    (define-key map (kbd "C-c x") 'claude-execute-in-stumpwm)
    map)
  "Keymap for `claude-mode'.")

;;;###autoload
(define-minor-mode claude-mode
  "Minor mode for Claude AI integration."
  :lighter " Claude"
  :keymap claude-mode-map
  :group 'claude-mode
  (if claude-mode
      (message "Claude mode enabled (C-c a to ask)")
    (message "Claude mode disabled")))

;;;; Utility Commands

;;;###autoload
(defun claude-clear-buffer ()
  "Clear the Claude conversation buffer."
  (interactive)
  (with-current-buffer (claude--get-buffer)
    (erase-buffer)
    (insert "Claude AI Assistant\n")
    (insert "===================\n\n")
    (insert "Use C-c a to ask questions\n")
    (insert "Use C-c s for StumpWM commands\n\n")))

;;;###autoload
(defun claude-show-buffer ()
  "Show the Claude conversation buffer."
  (interactive)
  (claude--show-buffer))

;;;###autoload
(defun claude-test ()
  "Test Claude API connection."
  (interactive)
  (claude-ask "Reply with exactly: 'Connection successful.'"))

;;;; Quick Setup

;;;###autoload
(defun claude-setup ()
  "Quick setup for Claude integration in Emacs + StumpWM."
  (interactive)
  (when (y-or-n-p "Enable claude-mode globally? ")
    (global-claude-mode 1))
  (when (and (featurep 'stumpctl)
             (y-or-n-p "Connect to StumpWM via SLY? "))
    (stumpctl-connect))
  (claude-show-buffer)
  (claude-clear-buffer)
  (message "Claude integration ready!"))

;;;###autoload
(define-globalized-minor-mode global-claude-mode
  claude-mode
  (lambda () (claude-mode 1)))

(provide 'claude-mode)
;;; claude-mode.el ends here
