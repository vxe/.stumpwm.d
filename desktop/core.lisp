;;;; desktop/core.lisp --- Core StumpWM Configuration
;;;;
;;;; Basic window manager settings and behavior configuration.
;;;;

(in-package :stumpwm)

;;;; ===========================================================================
;;;; Basic Settings
;;;; ===========================================================================

;; Set the prefix key (default is C-t, we'll keep it)
(set-prefix-key (kbd "C-t"))

;; Mouse focus policy
(setf *mouse-focus-policy* :click) ; :click, :ignore, or :sloppy

;; Window border width
(setf *window-border-style* :none)  ; :thin, :thick, :tight, or :none
(setf *normal-border-width* 0)
(setf *maxsize-border-width* 0)
(setf *transient-border-width* 0)

;; Remove gaps and frame borders
(setf *head-border-width* 0)
(setf *internal-border-width* 0)
(setf *frame-outline-width* 0)

;; Remove mode line padding
(setf *mode-line-pad-x* 0)
(setf *mode-line-pad-y* 0)

;; Disable frame indicator
(setf *frame-indicator-timer* 0)
(setf *frame-indicator-text* "")

;; Message window settings
(setf *message-window-gravity* :top-right)
(setf *message-window-padding* 10)
(setf *timeout-wait* 5) ; seconds to show messages

;; Input window settings
(setf *input-window-gravity* :center)

;;;; ===========================================================================
;;;; Startup Behavior
;;;; ===========================================================================

;; Suppress startup message
(setf *startup-message* nil)

;; Start in a specific group (workspace)
(setf *default-group-name* "main")

;;;; ===========================================================================
;;;; Window Placement
;;;; ===========================================================================

;; New window placement
(setf *new-window-preferred-frame* '(:focused))

;; Window gravity (for floating windows)
(setf *window-gravity* :center)

;;;; ===========================================================================
;;;; Groups (Workspaces)
;;;; ===========================================================================

;; Define default groups/workspaces
(when *initializing*
  ;; Clear default groups
  (grename "main")

  ;; Create additional workspaces
  (gnewbg "dev")    ; Development workspace
  (gnewbg "web")    ; Web browsing
  (gnewbg "comms")  ; Communication apps
  (gnewbg "media")  ; Media/entertainment
  (gnewbg "misc"))  ; Miscellaneous

;;;; ===========================================================================
;;;; Mode Line (Status Bar)
;;;; ===========================================================================

;; Mode line format
(setf *screen-mode-line-format*
      (list "[^B%n^b] %W^>%d | %C"))

;; Mode line colors are set in theme.lisp

;; Enable mode line on all screens
(enable-mode-line (current-screen) (current-head) t)

;;;; ===========================================================================
;;;; Window Formatting
;;;; ===========================================================================

;; Window list format
(setf *window-format* "%m%n%s%c")

;; Window name format in mode line
(setf *window-name-source* :title) ; :title or :class

;;;; ===========================================================================
;;;; Claude Integration Settings
;;;; ===========================================================================

;; Claude API configuration
(defparameter *claude-api-key*
  (or (uiop:getenv "CLAUDE_API_KEY")
      (uiop:getenv "ANTHROPIC_API_KEY")
      nil)
  "Claude API key from environment variable.")

(defparameter *claude-api-endpoint*
  "https://api.anthropic.com/v1/messages"
  "Claude API endpoint URL.")

(defparameter *claude-model*
  "claude-3-5-sonnet-20241022"
  "Claude model to use for desktop integration.")

(defparameter *claude-max-tokens*
  4096
  "Maximum tokens for Claude responses.")

(defparameter *claude-timeout*
  30
  "Timeout in seconds for Claude API requests.")

;; Context gathering settings
(defparameter *claude-include-window-titles* t
  "Include window titles in Claude context.")

(defparameter *claude-include-group-info* t
  "Include current workspace/group info in Claude context.")

(defparameter *claude-include-system-info* nil
  "Include system information in Claude context.")

;;;; ===========================================================================
;;;; Swank/SLY Settings
;;;; ===========================================================================

(defparameter *swank-port* 4005
  "Port for Swank REPL server.")

(defparameter *swank-auto-start* nil
  "Automatically start Swank server on startup.")

;;;; ===========================================================================
;;;; Debug Settings
;;;; ===========================================================================

(defparameter *claude-debug* t
  "Enable debug logging for Claude integration.")

(when *claude-debug*
  (setf *debug-level* 5))

;;;; ===========================================================================
;;;; Helper Functions
;;;; ===========================================================================

(defun reload-config ()
  "Reload the entire StumpWM configuration."
  (run-commands "reload"))

;;; core.lisp ends here
