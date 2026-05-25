(in-package :stumpwm)

;;;; ===========================================================================
;;;; whisper-clip — voice-to-clipboard
;;;;
;;;; H-r  → toggle recording on/off
;;;;
;;;; On first press:  starts `arecord` capturing 16kHz mono WAV
;;;; On second press: kills `arecord`, POSTs WAV to whisper.cpp server
;;;;                  (localhost:8080), copies transcription to clipboard,
;;;;                  notifies via StumpWM message bar.
;;;;
;;;; Requires:
;;;;   - whisper.cpp server running on localhost:8080  (see start-server.sh)
;;;;   - arecord  (alsa-utils)
;;;;   - curl
;;;;   - xclip or xsel
;;;; ===========================================================================

;;; ── Config ──────────────────────────────────────────────────────────────────

(defparameter *wc-wav-file*   "/tmp/whisper-clip.wav"
  "Temporary WAV file written during each recording.")

(defparameter *wc-server-url* "http://127.0.0.1:8080/inference"
  "whisper.cpp HTTP server endpoint.")

;;; ── State ───────────────────────────────────────────────────────────────────

(defparameter *wc-recording*   nil "T while recording is active.")
(defparameter *wc-rec-process* nil "sb-ext:process handle for arecord.")

;;; ── Helpers ─────────────────────────────────────────────────────────────────

(defun wc-notify (msg)
  "Display MSG in the StumpWM message bar."
  (message msg))

(defun wc-copy-to-clipboard (text)
  "Write TEXT to the X11 clipboard. Tries xclip, falls back to xsel."
  (dolist (cmd '(("xclip" "-selection" "clipboard")
                 ("xsel"  "--clipboard" "--input")))
    (ignore-errors
      (let ((proc (sb-ext:run-program
                   (car cmd) (cdr cmd)
                   :input :stream :wait nil :search t)))
        (write-string text (sb-ext:process-input proc))
        (close (sb-ext:process-input proc))
        (sb-ext:process-wait proc)
        (when (zerop (sb-ext:process-exit-code proc))
          (return t))))))

(defun wc-type-text (text)
  "Type TEXT as keystrokes into the focused window via xdotool."
  (ignore-errors
    (sb-ext:run-program "xdotool"
                        (list "type" "--clearmodifiers" "--delay" "1" text)
                        :wait t :search t)))

(defun wc-transcribe (wav-path)
  "POST WAV-PATH to the whisper.cpp server. Returns trimmed text or NIL."
  (handler-case
      (let ((result (with-output-to-string (out)
                      (sb-ext:run-program
                       "curl"
                       (list "-s" "--max-time" "30"
                             "-X" "POST" *wc-server-url*
                             "-F" (format nil "file=@~A" wav-path)
                             "-F" "response_format=text")
                       :output out :error nil :wait t :search t))))
        (let ((text (string-trim '(#\Space #\Newline #\Return #\Tab) result)))
          (if (string= text "") nil text)))
    (error (e)
      (wc-notify (format nil "^1whisper-clip error:^n ~A" e))
      nil)))

;;; ── Recording ───────────────────────────────────────────────────────────────

(defun wc-start ()
  "Start capturing audio with arecord."
  (when (probe-file *wc-wav-file*)
    (delete-file *wc-wav-file*))
  (setf *wc-rec-process*
        (sb-ext:run-program
         "arecord"
         (list "-q"                  ; quiet
               "-D" "hw:0,7"        ; DMIC16kHz — built-in digital mic
               "-f" "S16_LE"        ; 16-bit signed little-endian
               "-r" "16000"         ; 16 kHz (Whisper's native rate, device native)
               "-c" "2"             ; stereo (device requires 2ch)
               "-t" "wav"
               *wc-wav-file*)
         :wait nil :search t))
  (setf *wc-recording* t)
  (wc-notify "^2● REC^n  (H-r to stop)"))

(defun wc-stop-and-transcribe ()
  "Stop arecord, transcribe in a background thread, copy result to clipboard."
  (setf *wc-recording* nil)
  ;; SIGINT flushes and finalises the WAV header cleanly
  (when *wc-rec-process*
    (ignore-errors (sb-ext:process-kill *wc-rec-process* 2))
    (sb-ext:process-wait *wc-rec-process*)
    (setf *wc-rec-process* nil))
  ;; Transcribe off the main thread — keeps StumpWM responsive
  (sb-thread:make-thread
   (lambda ()
     (wc-notify "^3…transcribing^n")
     (let ((text (wc-transcribe *wc-wav-file*)))
       (if text
           (progn
             (wc-copy-to-clipboard text)
             (wc-type-text text)
             (wc-notify
              (format nil "^2Typed:^n ~A"
                      (if (> (length text) 80)
                          (concatenate 'string (subseq text 0 80) "…")
                          text))))
           (wc-notify "^3whisper-clip:^n (nothing heard)"))))
   :name "whisper-clip"))

;;; ── StumpWM command & keybinding ────────────────────────────────────────────

(defcommand whisper-clip-toggle () ()
  "Toggle voice-to-clipboard recording.
First press starts recording; second press stops, transcribes, and copies."
  (if *wc-recording*
      (wc-stop-and-transcribe)
      (wc-start)))

(define-key *top-map* (kbd "H-space") "whisper-clip-toggle")
