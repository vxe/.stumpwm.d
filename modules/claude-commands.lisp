;;;; modules/claude-commands.lisp --- User-Facing Claude Commands
;;;;
;;;; StumpWM commands that users can invoke to interact with Claude.
;;;;

(in-package :stumpwm-user)

;;;; ===========================================================================
;;;; Main Commands
;;;; ===========================================================================

(defcommand claude-ask (prompt) ((:rest "Ask Claude: "))
  "Ask Claude a question or give it a command.
   This is the main entry point for Claude interaction."
  (if (and prompt (> (length prompt) 0))
      (claude-ask prompt :include-context t :execute-code nil)
      (message "No prompt provided")))

(defcommand claude-do (prompt) ((:rest "Command Claude: "))
  "Give Claude a command and automatically execute the code it returns.
   Use this when you want Claude to directly manipulate your desktop."
  (if (and prompt (> (length prompt) 0))
      (claude-ask prompt :include-context t :execute-code t)
      (message "No command provided")))

(defcommand claude-eval-region (code) ((:rest "Code to evaluate: "))
  "Evaluate a Lisp code string.
   This can be used to execute code suggested by Claude."
  (if (and code (> (length code) 0))
      (claude-execute-code code)
      (message "No code provided")))

;;;; ===========================================================================
;;;; Context Commands
;;;; ===========================================================================

(defcommand claude-show-context () ()
  "Show the desktop context that will be sent to Claude."
  (let* ((context (gather-full-context))
         (formatted (format-context-for-claude context)))
    (message formatted)))

(defcommand claude-without-context (prompt) ((:rest "Ask Claude (no context): "))
  "Ask Claude without including desktop context."
  (if (and prompt (> (length prompt) 0))
      (claude-ask prompt :include-context nil :execute-code nil)
      (message "No prompt provided")))

;;;; ===========================================================================
;;;; Specialized Commands
;;;; ===========================================================================

(defcommand claude-layout () ()
  "Ask Claude to suggest an optimal window layout."
  (claude-suggest-layout))

(defcommand claude-keybindings () ()
  "Ask Claude to explain available keybindings."
  (claude-explain-keybindings))

(defcommand claude-troubleshoot () ()
  "Ask Claude to troubleshoot your current window setup."
  (claude-troubleshoot))

;;;; ===========================================================================
;;;; Workspace Commands
;;;; ===========================================================================

(defcommand claude-organize-workspace (workspace-name) ((:string "Workspace: "))
  "Ask Claude to help organize a specific workspace."
  (let ((prompt (format nil "Organize the ~A workspace optimally. What layout would work best?"
                       workspace-name)))
    (claude-ask prompt :include-context t :execute-code nil)))

(defcommand claude-move-window-smart () ()
  "Ask Claude where the current window should be moved."
  (let ((win (current-window)))
    (if win
        (let ((prompt (format nil "Where should I move the ~A window (~A)? Suggest the best workspace."
                             (window-class win)
                             (window-title win))))
          (claude-ask prompt :include-context t :execute-code nil))
        (message "No window focused"))))

;;;; ===========================================================================
;;;; Application Launching
;;;; ===========================================================================

(defcommand claude-launch (app-description) ((:rest "What to launch: "))
  "Ask Claude to launch an application based on description.
   Example: 'launch my web browser' or 'open a terminal'"
  (if (and app-description (> (length app-description) 0))
      (let ((prompt (format nil "Launch this application: ~A. Provide the Lisp code to do it."
                           app-description)))
        (claude-ask prompt :include-context nil :execute-code t))
      (message "No application description provided")))

;;;; ===========================================================================
;;;; History Commands
;;;; ===========================================================================

(defcommand claude-history () ()
  "Show recent Claude conversation history."
  (message (claude-show-history)))

(defcommand claude-clear-history () ()
  "Clear Claude conversation history."
  (claude-clear-history))

(defcommand claude-last-response () ()
  "Show Claude's last response."
  (if *claude-last-response*
      (message (format nil "^2Last response:^n ~A" *claude-last-response*))
      (message "No previous response")))

(defcommand claude-repeat-last () ()
  "Repeat the last Claude query."
  (if *claude-last-request*
      (progn
        (message (format nil "Repeating: ~A" *claude-last-request*))
        (claude-ask *claude-last-request* :include-context t :execute-code nil))
      (message "No previous request")))

;;;; ===========================================================================
;;;; Configuration Commands
;;;; ===========================================================================

(defcommand claude-teach (command-name description code)
    ((:string "Command name: ")
     (:rest "Description: ")
     (:rest "Lisp code: "))
  "Teach Claude about a new custom command.
   This adds the command to a local knowledge base."
  (message "Teaching mode not yet implemented")
  (message (format nil "Would teach: ~A - ~A" command-name description)))

(defcommand claude-config-help () ()
  "Ask Claude about configuration options."
  (claude-ask "What configuration options are available in this StumpWM setup? List the most useful ones."
              :include-context nil))

;;;; ===========================================================================
;;;; Testing & Debugging
;;;; ===========================================================================

(defcommand claude-test () ()
  "Test Claude API connection."
  (claude-test-connection))

(defcommand claude-debug-toggle () ()
  "Toggle debug logging for Claude integration."
  (setf *claude-debug* (not *claude-debug*))
  (message (format nil "Claude debug logging: ~A" (if *claude-debug* "ON" "OFF"))))

(defcommand claude-status () ()
  "Show Claude integration status."
  (let ((api-key-set (if *claude-api-key* "Set" "Not set"))
        (history-count (length *claude-conversation-history*))
        (last-request (if *claude-last-request*
                         (subseq *claude-last-request* 0 (min 50 (length *claude-last-request*)))
                         "None")))
    (message (format nil "Claude Integration Status:~%~
                          API Key: ~A~%~
                          Debug: ~A~%~
                          History: ~A conversations~%~
                          Last: ~A"
                    api-key-set
                    (if *claude-debug* "ON" "OFF")
                    history-count
                    last-request))))

;;;; ===========================================================================
;;;; Quick Actions
;;;; ===========================================================================

(defcommand claude-balance () ()
  "Ask Claude to balance the current frame layout."
  (claude-ask "Balance all frames in the current workspace" :include-context t :execute-code t))

(defcommand claude-cleanup () ()
  "Ask Claude to help clean up the desktop."
  (claude-ask "Clean up my desktop. Close unnecessary windows and organize the rest."
              :include-context t
              :execute-code nil))

(defcommand claude-focus-help () ()
  "Ask Claude which window you should focus on."
  (claude-ask "Which window should I focus on right now based on my current workspace?"
              :include-context t))

;;;; ===========================================================================
;;;; Interactive Tutorials
;;;; ===========================================================================

(defcommand claude-tutorial () ()
  "Start an interactive StumpWM tutorial with Claude."
  (claude-ask "Give me a quick tutorial on the most essential StumpWM commands and keybindings I should know. Be concise."
              :include-context nil))

(defcommand claude-explain-current () ()
  "Ask Claude to explain the current window/desktop state."
  (claude-ask "Explain what I'm looking at right now. What windows are open and how are they arranged?"
              :include-context t))

;;;; ===========================================================================
;;;; Help Command
;;;; ===========================================================================

(defparameter *claude-commands-help*
  "Claude Integration Commands:

BASIC:
  :claude-ask <prompt>          Ask Claude anything
  :claude-do <command>          Execute command via Claude
  :claude-eval-region <code>    Execute Lisp code

SPECIALIZED:
  :claude-layout                Get layout suggestions
  :claude-keybindings           Show keybinding help
  :claude-troubleshoot          Troubleshoot issues
  :claude-move-window-smart     Smart window placement

APPLICATIONS:
  :claude-launch <description>  Launch app by description

HISTORY:
  :claude-history               Show conversation history
  :claude-last-response         Show last response
  :claude-repeat-last           Repeat last query

WORKSPACE:
  :claude-organize-workspace    Organize a workspace
  :claude-focus-help            Get focus suggestions
  :claude-cleanup               Clean up desktop

CONFIGURATION:
  :claude-status                Show status
  :claude-test                  Test API connection
  :claude-debug-toggle          Toggle debug mode

LEARNING:
  :claude-tutorial              Interactive tutorial
  :claude-explain-current       Explain current state

Use Super+Space to invoke :claude-ask quickly!"
  "Help text for Claude commands.")

(defcommand claude-commands-help () ()
  "Show help for Claude commands."
  (message *claude-commands-help*))

;;; claude-commands.lisp ends here
