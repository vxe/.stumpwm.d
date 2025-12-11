;;;; Safe File-Based Eval for StumpWM
;;;; Version 2.0 - Fixed crash loop issues
;;;;
;;;; SAFETY IMPROVEMENTS FROM V1:
;;;; - 2 second poll interval (was 0.1s - 20x reduction in overhead)
;;;; - Triple-layered error handling
;;;; - Lock file prevents race conditions
;;;; - All file ops wrapped in ignore-errors
;;;; - Can be stopped/started without restart
;;;; - Detailed error logging to /tmp/stumpwm-eval-errors.log

(in-package :stumpwm-user)

;;;; ===========================================================================
;;;; Configuration
;;;; ===========================================================================

(defparameter *eval-input-file* "/tmp/stumpwm-eval-input"
  "File where external scripts write code to evaluate.")

(defparameter *eval-output-file* "/tmp/stumpwm-eval-output"
  "File where evaluation results are written.")

(defparameter *eval-lock-file* "/tmp/stumpwm-eval.lock"
  "Lock file to prevent race conditions.")

(defparameter *eval-error-log* "/tmp/stumpwm-eval-errors.log"
  "Log file for eval system errors.")

(defparameter *eval-watcher-running* nil
  "Is the eval watcher currently running?")

(defparameter *eval-watcher-timer* nil
  "Timer object for the eval watcher.")

(defparameter *eval-poll-interval* 2
  "How often to check for eval requests (in seconds). Default: 2s")

(defparameter *eval-max-output-length* 10000
  "Maximum length of eval output to prevent memory issues.")

;;;; ===========================================================================
;;;; Error Logging
;;;; ===========================================================================

(defun log-eval-error (context error-msg)
  "Log an error to the eval error log file."
  (ignore-errors
    (with-open-file (stream *eval-error-log*
                           :direction :output
                           :if-exists :append
                           :if-does-not-exist :create)
      (format stream "[~A] ~A: ~A~%"
              (multiple-value-bind (sec min hour day month year)
                  (get-decoded-time)
                (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
                        year month day hour min sec))
              context
              error-msg))))

;;;; ===========================================================================
;;;; Safe File Operations
;;;; ===========================================================================

(defun safe-delete-file (path)
  "Delete a file, suppressing all errors."
  (ignore-errors
    (when (probe-file path)
      (delete-file path))))

(defun safe-read-file (path)
  "Read entire contents of file, returning NIL on any error."
  (ignore-errors
    (when (probe-file path)
      (with-open-file (stream path :direction :input)
        (let ((contents (make-string (file-length stream))))
          (read-sequence contents stream)
          contents)))))

(defun safe-write-file (path content)
  "Write content to file, suppressing all errors."
  (ignore-errors
    (with-open-file (stream path
                           :direction :output
                           :if-exists :supersede
                           :if-does-not-exist :create)
      (write-string content stream))))

;;;; ===========================================================================
;;;; Lock File Management
;;;; ===========================================================================

(defun acquire-lock ()
  "Try to acquire the lock file. Returns T if successful, NIL otherwise."
  (handler-case
      (progn
        ;; If lock file is older than 10 seconds, assume stale and remove
        (when (probe-file *eval-lock-file*)
          (let ((lock-age (- (get-universal-time)
                            (file-write-date *eval-lock-file*))))
            (when (> lock-age 10)
              (safe-delete-file *eval-lock-file*))))

        ;; Try to create lock file
        (if (probe-file *eval-lock-file*)
            nil  ; Lock already held
            (progn
              (safe-write-file *eval-lock-file* (format nil "~A" (get-universal-time)))
              t)))
    (error (e)
      (log-eval-error "acquire-lock" (format nil "~A" e))
      nil)))

(defun release-lock ()
  "Release the lock file."
  (safe-delete-file *eval-lock-file*))

;;;; ===========================================================================
;;;; Core Eval Logic
;;;; ===========================================================================

(defun safe-eval-code (code-string)
  "Safely evaluate a string of Lisp code. Returns (values result error-p error-msg)."
  (handler-case
      (let* ((code (read-from-string code-string))
             (result (eval code)))
        (values result nil nil))
    (reader-error (e)
      (values nil t (format nil "READ-ERROR: ~A" e)))
    (error (e)
      (values nil t (format nil "EVAL-ERROR: ~A" e)))))

(defun truncate-output (string max-length)
  "Truncate string to max-length, adding ellipsis if truncated."
  (if (> (length string) max-length)
      (concatenate 'string
                   (subseq string 0 (- max-length 20))
                   "\n...[truncated]...")
      string))

;;;; ===========================================================================
;;;; Request Processing
;;;; ===========================================================================

(defun process-eval-request ()
  "Check for and process a single eval request. This is called by the timer."
  ;; LAYER 1: Protect the entire function
  (handler-case
      (progn
        ;; Only proceed if input file exists
        (when (probe-file *eval-input-file*)

          ;; Try to acquire lock
          (unless (acquire-lock)
            ;; Someone else is processing, skip this round
            (return-from process-eval-request))

          ;; LAYER 2: Protect the processing logic
          (handler-case
              (let ((code-string (safe-read-file *eval-input-file*)))

                (if (not code-string)
                    ;; Failed to read input
                    (progn
                      (log-eval-error "process-eval-request" "Failed to read input file")
                      (safe-write-file *eval-output-file* "ERROR: Failed to read input")
                      (safe-delete-file *eval-input-file*))

                    ;; LAYER 3: Protect the actual eval
                    (multiple-value-bind (result error-p error-msg)
                        (safe-eval-code code-string)

                      (let ((output (if error-p
                                        error-msg
                                        (format nil "~S" result))))
                        ;; Truncate if too long
                        (setf output (truncate-output output *eval-max-output-length*))

                        ;; Write result
                        (safe-write-file *eval-output-file* output)

                        ;; Delete input to signal completion
                        (safe-delete-file *eval-input-file*)))))

            ;; LAYER 2 error handler
            (error (e)
              (log-eval-error "process-eval-request[inner]" (format nil "~A" e))
              (safe-write-file *eval-output-file*
                             (format nil "ERROR: Internal processing error: ~A" e))
              (safe-delete-file *eval-input-file*)))

          ;; Always release lock
          (release-lock)))

    ;; LAYER 1 error handler - catches EVERYTHING
    (error (e)
      (log-eval-error "process-eval-request[outer]" (format nil "~A" e))
      ;; Try to clean up, but don't fail if we can't
      (ignore-errors (safe-delete-file *eval-input-file*))
      (ignore-errors (release-lock)))))

;;;; ===========================================================================
;;;; Start/Stop Functions
;;;; ===========================================================================

(defun start-eval-watcher ()
  "Start the file-based eval watcher."
  (when *eval-watcher-running*
    (message "Eval watcher already running (poll interval: ~As)" *eval-poll-interval*)
    (return-from start-eval-watcher))

  ;; Clean up any leftover files
  (safe-delete-file *eval-input-file*)
  (safe-delete-file *eval-output-file*)
  (safe-delete-file *eval-lock-file*)

  ;; Clear error log (start fresh)
  (safe-write-file *eval-error-log*
                  (format nil "=== Eval watcher started at ~A ===~%"
                          (multiple-value-bind (sec min hour day month year)
                              (get-decoded-time)
                            (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
                                    year month day hour min sec))))

  ;; Start timer - check every N seconds
  (setf *eval-watcher-timer*
        (run-with-timer 0 *eval-poll-interval* #'process-eval-request))

  (setf *eval-watcher-running* t)
  (message "^2File-based eval watcher started^n (interval: ~As, safe mode enabled)"
           *eval-poll-interval*))

(defun stop-eval-watcher ()
  "Stop the file-based eval watcher."
  (unless *eval-watcher-running*
    (message "Eval watcher not running")
    (return-from stop-eval-watcher))

  ;; Cancel timer
  (when *eval-watcher-timer*
    (cancel-timer *eval-watcher-timer*)
    (setf *eval-watcher-timer* nil))

  ;; Clean up files
  (safe-delete-file *eval-input-file*)
  (safe-delete-file *eval-output-file*)
  (safe-delete-file *eval-lock-file*)

  (setf *eval-watcher-running* nil)
  (message "^3File-based eval watcher stopped^n"))

;;;; ===========================================================================
;;;; Commands
;;;; ===========================================================================

(defcommand eval-watcher-start () ()
  "Start the file-based eval watcher."
  (start-eval-watcher))

(defcommand eval-watcher-stop () ()
  "Stop the file-based eval watcher."
  (stop-eval-watcher))

(defcommand eval-watcher-restart () ()
  "Restart the file-based eval watcher."
  (stop-eval-watcher)
  (sleep 0.5)
  (start-eval-watcher))

(defcommand eval-watcher-status () ()
  "Show detailed eval watcher status."
  (if *eval-watcher-running*
      (message (format nil "^2File-based eval: RUNNING^n~
                           Poll interval: ~As~%~
                           Input:  ~A~%~
                           Output: ~A~%~
                           Lock:   ~A~%~
                           Error log: ~A~%~
                           ~%Commands: eval-watcher-stop, eval-watcher-restart"
                      *eval-poll-interval*
                      *eval-input-file*
                      *eval-output-file*
                      *eval-lock-file*
                      *eval-error-log*))
      (message (format nil "^3File-based eval: STOPPED^n~
                           ~%Start with: eval-watcher-start"))))

(defcommand eval-watcher-show-errors () ()
  "Show recent errors from the eval system."
  (let ((errors (safe-read-file *eval-error-log*)))
    (if errors
        (message (format nil "^3Recent eval errors:^n~%~A"
                        (truncate-output errors 2000)))
        (message "^2No errors logged^n"))))

;;;; ===========================================================================
;;;; Info
;;;; ===========================================================================

(message "^2Safe file-based eval module loaded^n")
(message "Commands: eval-watcher-start, eval-watcher-stop, eval-watcher-status")
(message "Poll interval: ~As (safe mode)" *eval-poll-interval*)

;;; End of stumpwm-eval.lisp
