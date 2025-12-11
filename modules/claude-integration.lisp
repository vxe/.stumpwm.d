;;;; modules/claude-integration.lisp --- Claude API Integration
;;;;
;;;; Core integration between StumpWM and Claude AI.
;;;; Handles API communication, context injection, and response execution.
;;;;

(in-package :stumpwm-user)

;;;; ===========================================================================
;;;; System Prompt
;;;; ===========================================================================

(defparameter *claude-system-prompt*
  "You are an AI assistant integrated into StumpWM, a tiling window manager written in Common Lisp.

Your role is to help the user control their desktop environment through natural language commands.
You can:
- Execute Lisp code to manipulate windows, groups (workspaces), and frames
- Launch applications
- Change layouts and window arrangements
- Query system state
- Provide information about keybindings and commands

When responding to commands:
1. If the user wants to DO something, provide executable Common Lisp code wrapped in ```lisp blocks
2. If the user wants to KNOW something, provide a clear text explanation
3. Be concise - the user is working, not chatting
4. Use StumpWM functions like: run-commands, message, gselect, gmove, move-window-to-group, etc.

Common StumpWM commands:
- (stumpwm:message \"text\") - show a message
- (stumpwm:run-commands \"exec firefox\") - run shell command
- (stumpwm:gselect \"group-name\") - switch workspace
- (stumpwm:move-window-to-group (stumpwm:current-window) \"group-name\") - move window
- (stumpwm:vsplit) / (stumpwm:hsplit) - split frame
- (stumpwm:balance-frames) - balance all frames

You will receive context about the current desktop state before each query."
  "System prompt for Claude that explains its role and capabilities.")

;;;; ===========================================================================
;;;; Request Management
;;;; ===========================================================================

(defparameter *claude-last-request* nil
  "The last request sent to Claude.")

(defparameter *claude-last-response* nil
  "The last response received from Claude.")

(defparameter *claude-conversation-history* nil
  "History of recent Claude conversations.")

(defun claude-add-to-history (prompt response)
  "Add a prompt/response pair to conversation history."
  (push (list :timestamp (current-timestamp)
              :prompt prompt
              :response response)
        *claude-conversation-history*)
  ;; Keep only last 10 conversations
  (when (> (length *claude-conversation-history*) 10)
    (setf *claude-conversation-history*
          (subseq *claude-conversation-history* 0 10))))

;;;; ===========================================================================
;;;; Core Claude Interaction
;;;; ===========================================================================

(defun claude-ask (user-prompt &key
                               (include-context t)
                               (execute-code nil))
  "Ask Claude a question or give it a command.
   USER-PROMPT: The user's natural language input
   INCLUDE-CONTEXT: Whether to include desktop context
   EXECUTE-CODE: Whether to automatically execute returned Lisp code

   Returns Claude's response as a string."

  (unless *claude-api-key*
    (message "^1Error: Claude API key not configured^n")
    (message "Set CLAUDE_API_KEY environment variable")
    (return-from claude-ask nil))

  ;; Gather context
  (let* ((context (when include-context
                   (gather-full-context)))
         (context-string (when context
                          (format-context-for-claude context)))
         ;; Build full prompt
         (full-prompt
          (if context-string
              (format nil "~A~%~%User request: ~A"
                     context-string
                     user-prompt)
              user-prompt)))

    (log-info (format nil "Claude request: ~A" user-prompt))

    ;; Show working message
    (message "^3Asking Claude...^n")

    ;; Make API request
    (let ((response (claude-api-request full-prompt
                                       :system-prompt *claude-system-prompt*)))

      ;; Store in history
      (setf *claude-last-request* user-prompt)
      (setf *claude-last-response* response)
      (claude-add-to-history user-prompt response)

      ;; Process response
      (if response
          (progn
            (log-info (format nil "Claude response: ~A" (subseq response 0 (min 100 (length response)))))

            ;; Check if response contains executable code
            (let ((code (extract-lisp-code response)))
              (if (and code execute-code)
                  (progn
                    (message "^2Executing Claude's suggestion...^n")
                    (claude-execute-code code))
                  (message (format nil "^2Claude: ~A^n" response))))

            response)
          (progn
            (message "^1Failed to get response from Claude^n")
            nil)))))

;;;; ===========================================================================
;;;; Code Extraction and Execution
;;;; ===========================================================================

(defun extract-lisp-code (text)
  "Extract Lisp code from Claude's response.
   Looks for code blocks marked with ```lisp ... ```"
  (let ((start-marker "```lisp")
        (end-marker "```"))
    (let ((start (search start-marker text)))
      (when start
        (let* ((code-start (+ start (length start-marker)))
               (code-end (search end-marker text :start2 code-start)))
          (when code-end
            (string-trim-whitespace
             (subseq text code-start code-end))))))))

(defun claude-execute-code (code-string)
  "Execute Lisp code string returned by Claude.
   Returns the result or error message."
  (log-info (format nil "Executing code: ~A" code-string))

  (handler-case
      (let* ((code-form (read-from-string code-string))
             (result (eval code-form)))
        (log-info (format nil "Execution result: ~A" result))
        (message (format nil "^2Done. Result: ~A^n" result))
        result)
    (error (e)
      (let ((error-msg (format nil "Error executing code: ~A" e)))
        (log-error error-msg)
        (message (format nil "^1~A^n" error-msg))
        nil))))

;;;; ===========================================================================
;;;; Specialized Claude Queries
;;;; ===========================================================================

(defun claude-suggest-layout ()
  "Ask Claude to suggest an optimal window layout based on current windows."
  (claude-ask "Suggest an optimal layout for my current windows. Provide Lisp code to arrange them."
              :include-context t
              :execute-code nil))

(defun claude-explain-keybindings ()
  "Ask Claude to explain available keybindings."
  (claude-ask "List the most useful keybindings for window management in this StumpWM setup."
              :include-context nil
              :execute-code nil))

(defun claude-troubleshoot ()
  "Ask Claude to help troubleshoot issues with current window configuration."
  (claude-ask "Are there any issues with my current window setup? Any suggestions?"
              :include-context t
              :execute-code nil))

;;;; ===========================================================================
;;;; History Management
;;;; ===========================================================================

(defun claude-show-history ()
  "Show recent Claude conversation history."
  (if *claude-conversation-history*
      (with-output-to-string (out)
        (format out "Recent Claude Conversations:~%~%")
        (dolist (conv (reverse *claude-conversation-history*))
          (format out "[~A]~%" (format-timestamp (getf conv :timestamp)))
          (format out "You: ~A~%" (getf conv :prompt))
          (format out "Claude: ~A~%~%" (getf conv :response))))
      "No conversation history yet."))

(defun claude-clear-history ()
  "Clear Claude conversation history."
  (setf *claude-conversation-history* nil)
  (message "Claude history cleared"))

;;;; ===========================================================================
;;;; Utility Functions
;;;; ===========================================================================

(defun claude-test-connection ()
  "Test connection to Claude API."
  (message "^3Testing Claude API connection...^n")
  (let ((response (claude-api-request "Reply with exactly: 'Connection successful.'"
                                     :system-prompt "You are a test assistant. Follow instructions exactly.")))
    (if response
        (progn
          (message (format nil "^2Success! Claude says: ~A^n" response))
          t)
        (progn
          (message "^1Connection test failed^n")
          nil))))

;;; claude-integration.lisp ends here
