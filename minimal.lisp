(in-package :stumpwm)

;;;; Minimal emergency StumpWM config.
;;;; Loaded by F12 when the main init.lisp is broken.

;; Reset prefix to default C-t (does not require xmodmap)
(set-prefix-key (kbd "C-t"))

;; Try to restore Hyper key mapping (fails silently if xmodmap missing)
(ignore-errors (run-shell-command "xmodmap ~/.Xmodmap"))

;; F12 reloads this file (idempotent — safe to spam)
(define-key *top-map* (kbd "F12")
  "eval (load \"/home/vxe/.stumpwm.d/minimal.lisp\")")

;;;; ===========================================================================
;;;; Safe File-Based Eval System (lifted from full config so stumpwm-eval works
;;;; while we debug the broken init.lisp)
;;;; ===========================================================================

(defparameter *eval-input-file* "/tmp/stumpwm-eval-input")
(defparameter *eval-output-file* "/tmp/stumpwm-eval-output")
(defparameter *eval-lock-file* "/tmp/stumpwm-eval.lock")
(defparameter *eval-error-log* "/tmp/stumpwm-eval-errors.log")
(defparameter *eval-watcher-running* nil)
(defparameter *eval-watcher-timer* nil)
(defparameter *eval-poll-interval* 2)
(defparameter *eval-max-output-length* 10000)

(defun log-eval-error (context error-msg)
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
              context error-msg))))

(defun safe-delete-file (path)
  (ignore-errors (when (probe-file path) (delete-file path))))

(defun safe-read-file (path)
  (ignore-errors
    (when (probe-file path)
      (with-open-file (stream path :direction :input)
        (let ((contents (make-string (file-length stream))))
          (read-sequence contents stream)
          contents)))))

(defun safe-write-file (path content)
  (ignore-errors
    (with-open-file (stream path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (write-string content stream))))

(defun acquire-lock ()
  (handler-case
      (progn
        (when (probe-file *eval-lock-file*)
          (let ((lock-age (- (get-universal-time)
                             (file-write-date *eval-lock-file*))))
            (when (> lock-age 10)
              (safe-delete-file *eval-lock-file*))))
        (if (probe-file *eval-lock-file*)
            nil
            (progn
              (safe-write-file *eval-lock-file* (format nil "~A" (get-universal-time)))
              t)))
    (error (e)
      (log-eval-error "acquire-lock" (format nil "~A" e))
      nil)))

(defun release-lock ()
  (safe-delete-file *eval-lock-file*))

(defun safe-eval-code (code-string)
  (handler-case
      (let* ((code (read-from-string code-string))
             (result (eval code)))
        (values result nil nil))
    (reader-error (e)
      (values nil t (format nil "READ-ERROR: ~A" e)))
    (error (e)
      (values nil t (format nil "EVAL-ERROR: ~A" e)))))

(defun truncate-output (string max-length)
  (if (> (length string) max-length)
      (concatenate 'string (subseq string 0 (- max-length 20)) "\n...[truncated]...")
      string))

(defun process-eval-request ()
  (handler-case
      (progn
        (when (probe-file *eval-input-file*)
          (unless (acquire-lock)
            (return-from process-eval-request))
          (handler-case
              (let ((code-string (safe-read-file *eval-input-file*)))
                (if (not code-string)
                    (progn
                      (log-eval-error "process-eval-request" "Failed to read input file")
                      (safe-write-file *eval-output-file* "ERROR: Failed to read input")
                      (safe-delete-file *eval-input-file*))
                    (multiple-value-bind (result error-p error-msg)
                        (safe-eval-code code-string)
                      (let ((output (if error-p
                                        error-msg
                                        (format nil "~S" result))))
                        (setf output (truncate-output output *eval-max-output-length*))
                        (safe-write-file *eval-output-file* output)
                        (safe-delete-file *eval-input-file*)))))
            (error (e)
              (log-eval-error "process-eval-request[inner]" (format nil "~A" e))
              (safe-write-file *eval-output-file*
                               (format nil "ERROR: Internal processing error: ~A" e))
              (safe-delete-file *eval-input-file*)))
          (release-lock)))
    (error (e)
      (log-eval-error "process-eval-request[outer]" (format nil "~A" e))
      (ignore-errors (safe-delete-file *eval-input-file*))
      (ignore-errors (release-lock)))))

(defun start-eval-watcher ()
  (when *eval-watcher-running*
    (return-from start-eval-watcher))
  (safe-delete-file *eval-input-file*)
  (safe-delete-file *eval-output-file*)
  (safe-delete-file *eval-lock-file*)
  (safe-write-file *eval-error-log*
                   (format nil "=== Eval watcher started at ~A ===~%"
                           (multiple-value-bind (sec min hour day month year)
                               (get-decoded-time)
                             (format nil "~4,'0D-~2,'0D-~2,'0D ~2,'0D:~2,'0D:~2,'0D"
                                     year month day hour min sec))))
  (setf *eval-watcher-timer*
        (run-with-timer 0 *eval-poll-interval* #'process-eval-request))
  (setf *eval-watcher-running* t))

(start-eval-watcher)

;; Show cheatsheet — stays until first keypress
(let ((*timeout-wait* 600))
  (message "^B^1Minimal Emergency Config^n  (F12 reloads this)

^BPrefix^n  C-t  (or H-BackSpace if xmodmap active)

^BWindows^n  (prefix, then...)
  n / p      Next / prev window
  k          Close window (graceful)
  K          Kill app (force)
  w          Window list
  o          Other window
  '          Select window by name
  RET        Expose all windows
  0-9        Jump to window by number

^BFrames^n
  s          Split vertical (side by side)
  S          Split horizontal (top/bottom)
  R          Remove current frame
  Q          One frame only
  TAB / o    Next frame
  f          Select frame by number
  F          Show current frame number

^BCommands^n
  ;          Run StumpWM command
  :          Eval Lisp in StumpWM
  !          Run shell command
  h / ?      Help / show all bindings

^BGroups^n
  g          Groups submenu
  G          Visual group list
  F1-F10     Switch to group 1-10

^BRestore full config^n
  :  (load \"/home/vxe/.stumpwm.d/init.lisp\")"))
