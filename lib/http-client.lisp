;;;; lib/http-client.lisp --- HTTP Client for Claude API
;;;;
;;;; A simple HTTP client for making requests to the Claude API.
;;;; Uses external tools (curl) as StumpWM doesn't have built-in HTTP support.
;;;;

(in-package :stumpwm-user)

;;;; ===========================================================================
;;;; HTTP Client Configuration
;;;; ===========================================================================

(defparameter *http-user-agent*
  "StumpWM-Claude-Integration/0.1"
  "User agent string for HTTP requests.")

(defparameter *http-timeout*
  30
  "Default timeout for HTTP requests in seconds.")

;;;; ===========================================================================
;;;; HTTP Request Functions
;;;; ===========================================================================

(defun http-escape-arg (arg)
  "Escape shell argument for safe passing to curl."
  (format nil "'~A'" (substitute #\' #\' arg :test #'char=)))

(defun http-post-json (url api-key json-body &key (timeout *http-timeout*))
  "Make a POST request to URL with JSON-BODY.
   Returns the response body as a string, or NIL on error."
  (let* ((temp-file (format nil "/tmp/stumpwm-http-~A.json" (random 1000000)))
         (response-file (format nil "/tmp/stumpwm-http-response-~A.json" (random 1000000)))
         (curl-command
          (format nil "curl -s -X POST '~A' \\
  -H 'Content-Type: application/json' \\
  -H 'x-api-key: ~A' \\
  -H 'anthropic-version: 2023-06-01' \\
  -H 'User-Agent: ~A' \\
  --max-time ~A \\
  -d @~A \\
  -o ~A"
                  url
                  api-key
                  *http-user-agent*
                  timeout
                  temp-file
                  response-file)))

    (safely
      ;; Write JSON body to temp file
      (write-string-to-file temp-file json-body)

      ;; Execute curl command
      (log-debug (format nil "HTTP POST to ~A" url))
      (run-shell-command curl-command t)

      ;; Give curl a moment to complete
      (sleep 0.5)

      ;; Read response
      (let ((response (when (file-exists-p response-file)
                       (read-file-to-string response-file))))

        ;; Clean up temp files
        (ignore-errors
          (run-shell-command (format nil "rm -f ~A ~A" temp-file response-file) nil))

        response))))

(defun http-get (url &key headers (timeout *http-timeout*))
  "Make a GET request to URL with optional HEADERS.
   Returns the response body as a string, or NIL on error."
  (let* ((response-file (format nil "/tmp/stumpwm-http-response-~A.txt" (random 1000000)))
         (header-args
          (when headers
            (format nil "~{-H '~A: ~A' ~}" headers)))
         (curl-command
          (format nil "curl -s -X GET '~A' ~@[ ~A~] --max-time ~A -o ~A"
                  url
                  header-args
                  timeout
                  response-file)))

    (safely
      (log-debug (format nil "HTTP GET to ~A" url))
      (run-shell-command curl-command t)

      ;; Give curl a moment to complete
      (sleep 0.5)

      ;; Read response
      (let ((response (when (file-exists-p response-file)
                       (read-file-to-string response-file))))

        ;; Clean up
        (ignore-errors
          (run-shell-command (format nil "rm -f ~A" response-file) nil))

        response))))

;;;; ===========================================================================
;;;; Claude API Specific Functions
;;;; ===========================================================================

(defun claude-api-request (prompt &key
                                    (system-prompt nil)
                                    (max-tokens *claude-max-tokens*)
                                    (model *claude-model*)
                                    (temperature 1.0))
  "Make a request to Claude API with PROMPT.
   Returns the response text, or NIL on error."
  (unless *claude-api-key*
    (log-error "Claude API key not set. Set CLAUDE_API_KEY environment variable.")
    (message "^1Error: Claude API key not configured^n")
    (return-from claude-api-request nil))

  (log-info (format nil "Sending request to Claude: ~A" (subseq prompt 0 (min 50 (length prompt)))))

  ;; Build request body
  (let* ((messages
          (list (list :role "user"
                     :content prompt)))
         (request-body
          (json-encode
           (append
            (list :model model
                  :max_tokens max-tokens
                  :temperature temperature
                  :messages messages)
            (when system-prompt
              (list :system system-prompt))))))

    (log-debug (format nil "Request body: ~A" request-body))

    ;; Make API request
    (let ((response-json (http-post-json *claude-api-endpoint*
                                         *claude-api-key*
                                         request-body
                                         :timeout *claude-timeout*)))
      (if response-json
          (claude-parse-response response-json)
          (progn
            (log-error "No response from Claude API")
            nil)))))

(defun claude-parse-response (response-json)
  "Parse Claude API response JSON and extract the text content."
  (safely
    (log-debug (format nil "Parsing response: ~A" (subseq response-json 0 (min 200 (length response-json)))))

    ;; Simple JSON parsing - look for "text" field in content
    ;; This is a basic implementation; a proper JSON parser would be better
    (let* ((content-start (search "\"content\":" response-json))
           (text-start (and content-start
                           (search "\"text\":" response-json :start2 content-start)))
           (text-value-start (and text-start
                                 (+ text-start 8) ; length of "\"text\":"
                                 (position #\" response-json :start (+ text-start 8)))))

      (if text-value-start
          (let* ((text-value-end (position #\" response-json :start (1+ text-value-start)))
                 (text (subseq response-json (1+ text-value-start) text-value-end)))
            ;; Unescape JSON string
            (setf text (substitute #\Newline #\n
                                  (substitute #\Tab #\t text)))
            (log-info (format nil "Received response: ~A" (subseq text 0 (min 100 (length text)))))
            text)
          (progn
            (log-error "Failed to parse Claude response")
            (message "^1Error: Could not parse Claude response^n")
            nil)))))

;;;; ===========================================================================
;;;; Testing Functions
;;;; ===========================================================================

(defun test-http-client ()
  "Test the HTTP client with a simple request."
  (let ((response (http-get "https://httpbin.org/get")))
    (if response
        (message (format nil "HTTP test successful: ~A" (subseq response 0 (min 100 (length response)))))
        (message "HTTP test failed"))))

(defun test-claude-api ()
  "Test the Claude API with a simple request."
  (let ((response (claude-api-request "Say 'Hello from StumpWM!' in exactly those words.")))
    (if response
        (message (format nil "^2Claude says: ~A^n" response))
        (message "^1Claude API test failed^n"))))

;;; http-client.lisp ends here
