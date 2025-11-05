;;;; modules/claude-swank.lisp --- Swank/SLY Integration
;;;;
;;;; Provides REPL server for interactive development with Emacs SLY.
;;;; This allows live coding and debugging of StumpWM while it's running.
;;;;

(in-package :stumpwm)

;;;; ===========================================================================
;;;; Swank Server State
;;;; ===========================================================================

(defparameter *swank-server-process* nil
  "The Swank server process, if running.")

(defparameter *swank-server-running* nil
  "Flag indicating if Swank server is running.")

;;;; ===========================================================================
;;;; Swank Server Management
;;;; ===========================================================================

(defun swank-server-running-p ()
  "Check if Swank server is currently running."
  *swank-server-running*)

(defun start-swank-server (&optional (port *swank-port*))
  "Start a Swank REPL server on PORT for SLY connection from Emacs.
   This requires the Swank package to be loaded (usually via Quicklisp)."

  ;; Check if already running
  (when (swank-server-running-p)
    (message "Swank server already running")
    (return-from start-swank-server t))

  (handler-case
      (progn
        ;; Try to load Swank if not already loaded
        (unless (find-package :swank)
          (log-info "Attempting to load Swank...")

          ;; Try Quicklisp first
          (if (find-package :quicklisp)
              (funcall (intern "QUICKLOAD" :quicklisp) :swank)
              ;; Try direct ASDF load
              (asdf:load-system :swank)))

        ;; If we got here, Swank is loaded
        (let ((swank-package (find-package :swank)))
          (when swank-package
            (let ((create-server (intern "CREATE-SERVER" swank-package)))
              (funcall create-server :port port :dont-close t)
              (setf *swank-server-running* t)
              (log-info (format nil "Swank server started on port ~A" port))
              (message (format nil "^2Swank server started on port ~A^n" port))
              (message "Connect from Emacs with: M-x sly-connect RET localhost RET")
              t))))

    (error (e)
      (log-error (format nil "Failed to start Swank server: ~A" e))
      (message (format nil "^1Error starting Swank server: ~A^n" e))
      (message "Install Swank with: (ql:quickload :swank) in a Lisp REPL")
      nil)))

(defun stop-swank-server ()
  "Stop the Swank REPL server."
  (handler-case
      (let ((swank-package (find-package :swank)))
        (if (and swank-package (swank-server-running-p))
            (let ((stop-server (intern "STOP-SERVER" swank-package)))
              (funcall stop-server *swank-port*)
              (setf *swank-server-running* nil)
              (log-info "Swank server stopped")
              (message "Swank server stopped")
              t)
            (progn
              (message "Swank server not running")
              nil)))
    (error (e)
      (log-error (format nil "Error stopping Swank server: ~A" e))
      (message (format nil "^1Error stopping Swank: ~A^n" e))
      nil)))

(defun restart-swank-server ()
  "Restart the Swank REPL server."
  (stop-swank-server)
  (sleep 1)
  (start-swank-server))

;;;; ===========================================================================
;;;; Commands
;;;; ===========================================================================

(defcommand swank-start () ()
  "Start the Swank REPL server for SLY connection."
  (start-swank-server))

(defcommand swank-stop () ()
  "Stop the Swank REPL server."
  (stop-swank-server))

(defcommand swank-restart () ()
  "Restart the Swank REPL server."
  (restart-swank-server))

(defcommand swank-toggle () ()
  "Toggle the Swank REPL server on/off."
  (if (swank-server-running-p)
      (stop-swank-server)
      (start-swank-server)))

(defcommand swank-status () ()
  "Show Swank server status."
  (if (swank-server-running-p)
      (message (format nil "^2Swank server running on port ~A^n" *swank-port*))
      (message "Swank server not running (use Super+Ctrl+S to start)")))

;;;; ===========================================================================
;;;; Integration with Claude
;;;; ===========================================================================

(defun swank-eval-string (code-string)
  "Evaluate CODE-STRING in the Swank server context.
   This allows Claude to execute arbitrary Lisp code."
  (handler-case
      (let ((result (eval (read-from-string code-string))))
        (format nil "~A" result))
    (error (e)
      (format nil "Error: ~A" e))))

(defcommand eval-lisp (code-string) ((:rest "Lisp expression: "))
  "Evaluate a Lisp expression interactively."
  (if code-string
      (let ((result (swank-eval-string code-string)))
        (message (format nil "Result: ~A" result)))
      (message "No expression provided")))

;;;; ===========================================================================
;;;; Quicklisp Integration (Optional)
;;;; ===========================================================================

(defun load-quicklisp ()
  "Attempt to load Quicklisp if available."
  (let ((quicklisp-init
         (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
    (when (probe-file quicklisp-init)
      (handler-case
          (progn
            (load quicklisp-init)
            (log-info "Quicklisp loaded successfully")
            t)
        (error (e)
          (log-warning (format nil "Failed to load Quicklisp: ~A" e))
          nil)))))

;;;; ===========================================================================
;;;; Automatic Loading (Optional)
;;;; ===========================================================================

;; Try to load Quicklisp on module load
(when (not (find-package :quicklisp))
  (load-quicklisp))

;; Auto-start Swank if configured
(when (and *swank-auto-start* (not *swank-server-running*))
  (log-info "Auto-starting Swank server")
  (start-swank-server))

;;;; ===========================================================================
;;;; Help and Documentation
;;;; ===========================================================================

(defparameter *swank-help*
  "Swank/SLY Integration Help:

STARTING THE SERVER:
  1. In StumpWM, press: Super+Ctrl+S
  2. Or run command: :swank-start

CONNECTING FROM EMACS:
  1. Make sure SLY is installed: M-x package-install RET sly RET
  2. Connect: M-x sly-connect RET localhost RET 4005 RET
  3. You'll be in a REPL running inside StumpWM!

WHAT YOU CAN DO:
  - Test commands before adding them to config
  - Inspect window objects interactively
  - Debug Claude integration code
  - Hot-reload modules without restarting X11
  - Evaluate any Lisp code in StumpWM context

EXAMPLE SESSION:
  ;; In SLY REPL:
  (stumpwm:message \"Hello from Emacs!\")
  (stumpwm:current-window)
  (stumpwm:group-windows (stumpwm:current-group))

TROUBLESHOOTING:
  - Swank not found: Install with (ql:quickload :swank)
  - Connection refused: Check firewall on port 4005
  - Server already running: Use :swank-restart

COMMANDS:
  :swank-start     Start the server
  :swank-stop      Stop the server
  :swank-restart   Restart the server
  :swank-toggle    Toggle on/off
  :swank-status    Check status
"
  "Help text for Swank integration.")

(defcommand swank-help () ()
  "Show help for Swank/SLY integration."
  (message *swank-help*))

;;; claude-swank.lisp ends here
