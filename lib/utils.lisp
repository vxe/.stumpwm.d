;;;; lib/utils.lisp --- Utility Functions
;;;;
;;;; General-purpose utility functions for the StumpWM configuration.
;;;;

(in-package :stumpwm)

;;;; ===========================================================================
;;;; String Utilities
;;;; ===========================================================================

(defun string-trim-whitespace (str)
  "Remove leading and trailing whitespace from a string."
  (string-trim '(#\Space #\Tab #\Newline #\Return) str))

(defun string-split (delimiter string)
  "Split STRING by DELIMITER and return a list of substrings."
  (let ((result '())
        (start 0))
    (loop for pos = (position delimiter string :start start)
          while pos
          do (push (subseq string start pos) result)
             (setf start (1+ pos))
          finally (push (subseq string start) result))
    (nreverse result)))

(defun string-join (separator strings)
  "Join STRINGS with SEPARATOR."
  (format nil (format nil "~~{~~A~~^~A~~}" separator) strings))

(defun string-contains-p (substring string)
  "Check if STRING contains SUBSTRING."
  (search substring string :test #'char-equal))

(defun string-starts-with-p (prefix string)
  "Check if STRING starts with PREFIX."
  (and (>= (length string) (length prefix))
       (string= string prefix :end1 (length prefix))))

(defun string-ends-with-p (suffix string)
  "Check if STRING ends with SUFFIX."
  (and (>= (length string) (length suffix))
       (string= string suffix :start1 (- (length string) (length suffix)))))

;;;; ===========================================================================
;;;; List Utilities
;;;; ===========================================================================

(defun plist-get (plist key &optional default)
  "Get value for KEY from PLIST, or DEFAULT if not found."
  (or (getf plist key) default))

(defun alist-get (alist key &optional default)
  "Get value for KEY from ALIST, or DEFAULT if not found."
  (let ((pair (assoc key alist)))
    (if pair
        (cdr pair)
        default)))

;;;; ===========================================================================
;;;; File Utilities
;;;; ===========================================================================

(defun file-exists-p (path)
  "Check if a file exists at PATH."
  (probe-file path))

(defun read-file-to-string (path)
  "Read entire file at PATH into a string."
  (when (file-exists-p path)
    (with-open-file (stream path :direction :input)
      (let ((contents (make-string (file-length stream))))
        (read-sequence contents stream)
        contents))))

(defun write-string-to-file (path contents)
  "Write CONTENTS string to file at PATH."
  (with-open-file (stream path
                         :direction :output
                         :if-exists :supersede
                         :if-does-not-exist :create)
    (write-sequence contents stream)))

(defun append-string-to-file (path contents)
  "Append CONTENTS string to file at PATH."
  (with-open-file (stream path
                         :direction :output
                         :if-exists :append
                         :if-does-not-exist :create)
    (write-sequence contents stream)))

;;;; ===========================================================================
;;;; Process Utilities
;;;; ===========================================================================

(defun run-shell-command-sync (command)
  "Run a shell command synchronously and return output as string."
  (let ((stream (run-shell-command command t)))
    (when stream
      (let ((output (make-string-output-stream)))
        (loop for line = (read-line stream nil nil)
              while line
              do (format output "~A~%" line))
        (get-output-stream-string output)))))

(defun program-exists-p (program-name)
  "Check if a program exists in PATH."
  (not (null (run-shell-command-sync (format nil "which ~A" program-name)))))

;;;; ===========================================================================
;;;; Time Utilities
;;;; ===========================================================================

(defun current-timestamp ()
  "Get current Unix timestamp."
  (get-universal-time))

(defun format-timestamp (&optional (timestamp (current-timestamp)))
  "Format a timestamp as a human-readable string."
  (multiple-value-bind (sec min hr day mon yr)
      (decode-universal-time timestamp)
    (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
            yr mon day hr min sec)))

;;;; ===========================================================================
;;;; Window Utilities
;;;; ===========================================================================

(defun window-class-match-p (window class-name)
  "Check if WINDOW matches CLASS-NAME."
  (when window
    (string-equal (window-class window) class-name)))

(defun get-all-windows ()
  "Get a list of all windows across all groups."
  (let ((windows '()))
    (dolist (group (screen-groups (current-screen)))
      (dolist (window (group-windows group))
        (push window windows)))
    (nreverse windows)))

(defun find-window-by-class (class-name)
  "Find the first window matching CLASS-NAME."
  (find-if (lambda (w) (window-class-match-p w class-name))
           (get-all-windows)))

(defun find-windows-by-class (class-name)
  "Find all windows matching CLASS-NAME."
  (remove-if-not (lambda (w) (window-class-match-p w class-name))
                 (get-all-windows)))

;;;; ===========================================================================
;;;; Group Utilities
;;;; ===========================================================================

(defun get-group-by-name (name)
  "Get group by NAME."
  (find-if (lambda (g) (string-equal (group-name g) name))
           (screen-groups (current-screen))))

(defun group-window-count (group)
  "Get the number of windows in GROUP."
  (length (group-windows group)))

;;;; ===========================================================================
;;;; JSON Utilities (Simple implementation)
;;;; ===========================================================================

(defun json-escape-string (string)
  "Escape special characters in STRING for JSON."
  (with-output-to-string (out)
    (loop for char across string
          do (case char
               (#\" (write-string "\\\"" out))
               (#\\ (write-string "\\\\" out))
               (#\Newline (write-string "\\n" out))
               (#\Return (write-string "\\r" out))
               (#\Tab (write-string "\\t" out))
               (t (write-char char out))))))

(defun json-encode-string (string)
  "Encode STRING as a JSON string with quotes."
  (format nil "\"~A\"" (json-escape-string string)))

(defun json-encode-number (number)
  "Encode NUMBER as a JSON number."
  (format nil "~A" number))

(defun json-encode-boolean (value)
  "Encode boolean VALUE as JSON."
  (if value "true" "false"))

(defun json-encode-list (list)
  "Encode LIST as a JSON array."
  (format nil "[~{~A~^, ~}]"
          (mapcar #'json-encode list)))

(defun json-encode-plist (plist)
  "Encode property list PLIST as a JSON object."
  (with-output-to-string (out)
    (write-char #\{ out)
    (loop for (key value) on plist by #'cddr
          for first = t then nil
          unless first do (write-string ", " out)
          do (format out "~A: ~A"
                    (json-encode-string (string-downcase (symbol-name key)))
                    (json-encode value)))
    (write-char #\} out)))

(defun json-encode (value)
  "Encode VALUE as JSON. Supports strings, numbers, booleans, lists, and plists."
  (cond
    ((null value) "null")
    ((stringp value) (json-encode-string value))
    ((numberp value) (json-encode-number value))
    ((eq value t) "true")
    ((and (symbolp value) (not (keywordp value)))
     (json-encode-string (symbol-name value)))
    ((and (listp value) (keywordp (car value)))
     (json-encode-plist value))
    ((listp value) (json-encode-list value))
    (t (json-encode-string (format nil "~A" value)))))

;;;; ===========================================================================
;;;; Logging Utilities
;;;; ===========================================================================

(defparameter *log-file*
  (merge-pathnames "stumpwm.log" *stumpwm-config-dir*)
  "Path to log file.")

(defun log-message (level message)
  "Log MESSAGE with LEVEL to both the log file and StumpWM messages."
  (let ((timestamp (format-timestamp))
        (formatted (format nil "[~A] ~A: ~A" timestamp level message)))
    ;; Log to file
    (ignore-errors
      (append-string-to-file *log-file* (format nil "~A~%" formatted)))
    ;; Show in StumpWM if debug enabled
    (when *claude-debug*
      (message formatted))))

(defun log-debug (message)
  "Log a debug message."
  (log-message "DEBUG" message))

(defun log-info (message)
  "Log an info message."
  (log-message "INFO" message))

(defun log-warning (message)
  "Log a warning message."
  (log-message "WARNING" message))

(defun log-error (message)
  "Log an error message."
  (log-message "ERROR" message))

;;;; ===========================================================================
;;;; Error Handling Utilities
;;;; ===========================================================================

(defmacro safely (&body body)
  "Execute BODY and catch any errors, logging them."
  `(handler-case
       (progn ,@body)
     (error (e)
       (log-error (format nil "Error: ~A" e))
       (message (format nil "^1Error: ~A^n" e))
       nil)))

;;; utils.lisp ends here
