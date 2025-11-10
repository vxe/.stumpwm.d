;;;; desktop/formatters.lisp --- Modeline Formatters
;;;;
;;;; All custom modeline formatters for status bar display
;;;;

(in-package :stumpwm)

;;;; ===========================================================================
;;;; Dropbox Status Formatter
;;;; ===========================================================================

(defvar *dropbox-status-cache* nil
  "Cached Dropbox status to avoid calling dropbox command too frequently.")

(defvar *dropbox-status-timestamp* 0
  "Timestamp of last Dropbox status check.")

(defvar *dropbox-cache-timeout* 5
  "How many seconds to cache Dropbox status (default 5 seconds).")

(defun get-dropbox-status ()
  "Get Dropbox status, using cache if available."
  (let ((now (get-universal-time)))
    (when (or (null *dropbox-status-cache*)
              (> (- now *dropbox-status-timestamp*) *dropbox-cache-timeout*))
      ;; Cache expired or doesn't exist, fetch new status
      (setf *dropbox-status-cache*
            (string-trim '(#\Space #\Newline #\Return)
                        (run-shell-command "dropbox status 2>/dev/null || echo 'Not running'" t)))
      (setf *dropbox-status-timestamp* now))
    *dropbox-status-cache*))

(defun fmt-dropbox (ml)
  "Format Dropbox status for modeline with colors.

   Colors:
   - Green: Up to date
   - Cyan: Syncing/Downloading/Uploading/Indexing
   - Yellow: Starting/Connecting
   - Red: Error/Not running
   - Default: Unknown status"
  (declare (ignore ml))
  (let ((status (get-dropbox-status)))
    (cond
      ;; Up to date - Green
      ((search "Up to date" status)
       "^2^B[DB: ✓]^b^n")

      ;; Syncing/Downloading/Uploading - Cyan
      ((or (search "Syncing" status)
           (search "Downloading" status)
           (search "Uploading" status)
           (search "Indexing" status))
       "^6^B[DB: ↻]^b^n")

      ;; Starting/Connecting - Yellow
      ((or (search "Starting" status)
           (search "Connecting" status))
       "^3^B[DB: ⋯]^b^n")

      ;; Not running or error - Red
      ((or (search "Not running" status)
           (search "isn't running" status)
           (search "Error" status))
       "^1^B[DB: ✗]^b^n")

      ;; Unknown status
      (t
       (format nil "^B[DB: ?]^b")))))

;; Register Dropbox formatter
(add-screen-mode-line-formatter #\D 'fmt-dropbox)

;;; formatters.lisp ends here
