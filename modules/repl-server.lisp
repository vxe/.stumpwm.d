;;;; modules/repl-server.lisp --- Slynk/Swank REPL Integration
;;;;
;;;; Provides REPL server for interactive development with Emacs.
;;;; Supports both Slynk (for SLY) and Swank (for SLIME).
;;;; Slynk is preferred as it's more modern.
;;;;

(in-package :stumpwm)

;;;; ===========================================================================
;;;; REPL Server State
;;;; ===========================================================================

(defparameter *repl-server-running* nil
  "Flag indicating if REPL server (Slynk or Swank) is running.")

(defparameter *repl-server-type* nil
  "Type of REPL server running: :slynk or :swank")

;;;; ===========================================================================
;;;; Server Detection and Loading
;;;; ===========================================================================

(defun slynk-available-p ()
  "Check if Slynk package is available."
  (find-package :slynk))

(defun swank-available-p ()
  "Check if Swank package is available."
  (find-package :swank))

(defun load-repl-backend ()
  "Try to load Slynk first, then Swank as fallback."
  (cond
    ((slynk-available-p)
     (log-info "Slynk package already loaded")
     :slynk)
    ((swank-available-p)
     (log-info "Swank package already loaded")
     :swank)
    (t
     ;; Try to load via Quicklisp
     (handler-case
         (progn
           (log-info "Attempting to load Slynk via Quicklisp...")
           (if (find-package :quicklisp)
               (progn
                 (funcall (intern "QUICKLOAD" :quicklisp) :slynk :silent t)
                 (if (slynk-available-p)
                     (progn
                       (log-info "Slynk loaded successfully")
                       :slynk)
                     (progn
                       (log-info "Slynk load failed, trying Swank...")
                       (funcall (intern "QUICKLOAD" :quicklisp) :swank :silent t)
                       (if (swank-available-p)
                           (progn
                             (log-info "Swank loaded successfully")
                             :swank)
                           nil))))
               (progn
                 (log-warning "Quicklisp not available")
                 nil)))
       (error (e)
         (log-error (format nil "Failed to load REPL backend: ~A" e))
         nil)))))

;;;; ===========================================================================
;;;; Slynk Server Functions
;;;; ===========================================================================

(defun start-slynk-server (&optional (port *swank-port*))
  "Start Slynk REPL server for SLY."
  (let ((slynk-package (find-package :slynk)))
    (when slynk-package
      (let ((create-server (intern "CREATE-SERVER" slynk-package)))
        (funcall create-server :port port :dont-close t)
        (setf *repl-server-running* t)
        (setf *repl-server-type* :slynk)
        (log-info (format nil "Slynk server started on port ~A" port))
        (message (format nil "^2Slynk server started on port ~A^n" port))
        (message "Connect from Emacs: M-x sly-connect RET localhost RET")
        t))))

(defun stop-slynk-server ()
  "Stop Slynk REPL server."
  (let ((slynk-package (find-package :slynk)))
    (when slynk-package
      (let ((stop-server (intern "STOP-SERVER" slynk-package)))
        (handler-case
            (progn
              (funcall stop-server *swank-port*)
              (setf *repl-server-running* nil)
              (setf *repl-server-type* nil)
              (log-info "Slynk server stopped")
              (message "Slynk server stopped")
              t)
          (error (e)
            (log-warning (format nil "Error stopping Slynk: ~A" e))
            nil))))))

;;;; ===========================================================================
;;;; Swank Server Functions
;;;; ===========================================================================

(defun start-swank-server (&optional (port *swank-port*))
  "Start Swank REPL server for SLIME."
  (let ((swank-package (find-package :swank)))
    (when swank-package
      (let ((create-server (intern "CREATE-SERVER" swank-package)))
        (funcall create-server :port port :dont-close t)
        (setf *repl-server-running* t)
        (setf *repl-server-type* :swank)
        (log-info (format nil "Swank server started on port ~A" port))
        (message (format nil "^2Swank server started on port ~A^n" port))
        (message "Connect from Emacs: M-x slime-connect RET localhost RET")
        t))))

(defun stop-swank-server ()
  "Stop Swank REPL server."
  (let ((swank-package (find-package :swank)))
    (when swank-package
      (let ((stop-server (intern "STOP-SERVER" swank-package)))
        (handler-case
            (progn
              (funcall stop-server *swank-port*)
              (setf *repl-server-running* nil)
              (setf *repl-server-type* nil)
              (log-info "Swank server stopped")
              (message "Swank server stopped")
              t)
          (error (e)
            (log-warning (format nil "Error stopping Swank: ~A" e))
            nil))))))

;;;; ===========================================================================
;;;; Unified Server Management
;;;; ===========================================================================

(defun repl-server-running-p ()
  "Check if any REPL server is running."
  *repl-server-running*)

(defun start-repl-server (&optional (port *swank-port*))
  "Start REPL server (prefers Slynk, falls back to Swank)."
  (when (repl-server-running-p)
    (message "REPL server already running")
    (return-from start-repl-server t))

  (let ((backend (load-repl-backend)))
    (case backend
      (:slynk (start-slynk-server port))
      (:swank (start-swank-server port))
      (t
       (message "^1ERROR: No REPL backend available!^n")
       (message "Install with: sbcl --script /tmp/install-repl-backend.lisp")
       nil))))

(defun stop-repl-server ()
  "Stop the running REPL server."
  (unless (repl-server-running-p)
    (message "No REPL server running")
    (return-from stop-repl-server nil))

  (case *repl-server-type*
    (:slynk (stop-slynk-server))
    (:swank (stop-swank-server))
    (t (progn
         (setf *repl-server-running* nil)
         (setf *repl-server-type* nil)
         nil))))

(defun restart-repl-server ()
  "Restart the REPL server."
  (stop-repl-server)
  (sleep 1)
  (start-repl-server))

;;;; ===========================================================================
;;;; Commands
;;;; ===========================================================================

(defcommand repl-start () ()
  "Start the REPL server (Slynk or Swank)."
  (start-repl-server))

(defcommand repl-stop () ()
  "Stop the REPL server."
  (stop-repl-server))

(defcommand repl-restart () ()
  "Restart the REPL server."
  (restart-repl-server))

(defcommand repl-toggle () ()
  "Toggle the REPL server on/off."
  (if (repl-server-running-p)
      (stop-repl-server)
      (start-repl-server)))

(defcommand repl-status () ()
  "Show REPL server status."
  (if (repl-server-running-p)
      (message (format nil "^2REPL server (~A) running on port ~A^n"
                      *repl-server-type* *swank-port*))
      (message "REPL server not running (use Super+Ctrl+S to start)")))

;; Backward compatibility aliases
(defcommand swank-start () ()
  "Start REPL server (backward compat)."
  (start-repl-server))

(defcommand swank-stop () ()
  "Stop REPL server (backward compat)."
  (stop-repl-server))

(defcommand swank-toggle () ()
  "Toggle REPL server (backward compat)."
  (if (repl-server-running-p)
      (stop-repl-server)
      (start-repl-server)))

(defcommand swank-status () ()
  "Show REPL server status (backward compat)."
  (repl-status))

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
;;;; Automatic Loading
;;;; ===========================================================================

;; Try to load Quicklisp on module load
(when (not (find-package :quicklisp))
  (load-quicklisp))

;; Auto-start if configured
(when (and (boundp '*swank-auto-start*)
           *swank-auto-start*
           (not *repl-server-running*))
  (log-info "Auto-starting REPL server")
  (start-repl-server))

;;; repl-server.lisp ends here
