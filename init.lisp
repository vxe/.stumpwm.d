(in-package :stumpwm-user)

;;;; ===========================================================================
;;;; Keyboard Remapping (belt-and-suspenders: also done in stumpwm-session)
;;;; ===========================================================================

;; Re-run xmodmap on every config load in case something reset it
(run-shell-command "xmodmap ~/.Xmodmap")
;; Key repeat rate
(run-shell-command "xset r rate 150 80")
;; Give xmodmap time to apply, then rescan modifiers
(run-with-timer 1 nil (lambda ()
  (stumpwm::update-modifier-map)
  (stumpwm::sync-keys)))

;;;; ===========================================================================
;;;; Prefix Key
;;;; ===========================================================================

;; PrintScreen (keycode 107) is remapped to Hyper_L on mod3
;; via /usr/local/bin/stumpwm-session before launch
(set-prefix-key (kbd "H-BackSpace"))

;;;; Emergency fallback: F11 resets prefix to C-t (no prefix needed)
(defcommand reset-prefix-to-ct () ()
  "Reset the prefix key back to C-t (emergency fallback)."
  (set-prefix-key (kbd "C-t"))
  (message "Prefix reset to C-t"))

(define-key *top-map* (kbd "F11") "reset-prefix-to-ct")

;;;; ===========================================================================
;;;; Safe File-Based Eval System
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
    (message "Eval watcher already running (poll interval: ~As)" *eval-poll-interval*)
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
  (setf *eval-watcher-running* t)
  (message "^2Eval watcher started^n (interval: ~As)" *eval-poll-interval*))

(defun stop-eval-watcher ()
  (unless *eval-watcher-running*
    (message "Eval watcher not running")
    (return-from stop-eval-watcher))
  (when *eval-watcher-timer*
    (cancel-timer *eval-watcher-timer*)
    (setf *eval-watcher-timer* nil))
  (safe-delete-file *eval-input-file*)
  (safe-delete-file *eval-output-file*)
  (safe-delete-file *eval-lock-file*)
  (setf *eval-watcher-running* nil)
  (message "^3Eval watcher stopped^n"))

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
  "Show eval watcher status."
  (if *eval-watcher-running*
      (message (format nil "^2Eval watcher: RUNNING^n~%Poll interval: ~As~%Input:  ~A~%Output: ~A~%Errors: ~A"
                       *eval-poll-interval* *eval-input-file* *eval-output-file* *eval-error-log*))
      (message "^3Eval watcher: STOPPED^n -- run eval-watcher-start")))

;;;; ===========================================================================
;;;; App Switcher Keys (no prefix needed)
;;;; ===========================================================================

(defcommand raise-emacs () ()
  (run-or-raise "emacs" '(:class "Emacs")))

(defcommand raise-terminal () ()
  (run-or-raise "kitty" '(:class "kitty")))

(defcommand raise-firefox () ()
  (run-or-raise "firefox" '(:class "firefox")))

(defcommand raise-android-studio () ()
  (run-or-raise "android-studio" '(:class "jetbrains-studio")))

(defcommand show-keybindings () ()
  "Show keybinding cheatsheet (stays until next keypress)."
  (let ((*timeout-wait* 600))
    (message "^B^2Keybindings^n

^BPrefix^n      H-BackSpace

^BApps (no prefix needed)^n
  H-e   Emacs       H-t   Terminal
  H-f   Firefox     H-a   Android Studio
  H-SPC Voice (whisper-clip)

^BVolume (no prefix)^n
  XF86AudioRaiseVolume / LowerVolume / Mute

^BEmergency^n
  F11   Reset prefix to C-t
  F12   Load minimal config (if main config broken)

^BPrefix map^n  (H-BackSpace, then...)
  n/p   Next/prev window    s   Split horiz
  S     Split vert          R   Remove split
  f     Focus frame         F   Fullscreen
  ;     Run command         :   Eval lisp
  ?     Show all bindings")))

(defcommand load-minimal-config () ()
  "Load the minimal emergency config (also bound to F12)."
  (load "/home/vxe/.stumpwm.d/minimal.lisp"))

(define-key *top-map* (kbd "F12") "load-minimal-config")

(define-key *top-map* (kbd "H-e") "raise-emacs")
(define-key *top-map* (kbd "H-t") "raise-terminal")
(define-key *top-map* (kbd "H-f") "raise-firefox")
(define-key *top-map* (kbd "H-a") "raise-android-studio")

;;;; Auto-start the eval watcher
(start-eval-watcher)

;;;; Auto-start cl-mcp HTTP server (port 3000)
;;;; Use uiop:symbol-call to avoid read-time package dependency — cl-mcp may
;;;; not be loaded yet when this file is read, causing a READ-ERROR before
;;;; handler-case can catch it.
(run-with-timer 3 nil
  (lambda ()
    (handler-case
        (progn
          (asdf:clear-source-registry)
          (asdf:initialize-source-registry)
          (ql:quickload :cl-mcp :silent t)
          (unless (ignore-errors (uiop:symbol-call :cl-mcp :http-server-running-p))
            (uiop:symbol-call :cl-mcp :start-http-server :port 3000)))
      (error (e)
        (message "^1cl-mcp failed to start: ~A^n" e)))))

;;;; ===========================================================================
;;;; Autostart
;;;; ===========================================================================

;;;; Reserve top 26px for polybar (override-redirect = true means no EWMH strut)
(run-with-timer 1 nil
  (lambda ()
    (stumpwm::resize-head 0 0 26 1920 1054)))

;;;; ===========================================================================
;;;; Volume Control (pamixer)
;;;; ===========================================================================

(defun volume-str ()
  (let ((muted (string= "true"
                 (string-trim '(#\Newline #\Space)
                   (run-shell-command "pamixer --get-mute" t))))
        (vol (string-trim '(#\Newline #\Space)
               (run-shell-command "pamixer --get-volume" t))))
    (if muted "MUTE" (format nil "~A%" vol))))

(defcommand volume-up () ()
  (run-shell-command "pamixer --increase 5")
  (message "^BVol^n ~A" (volume-str)))

(defcommand volume-down () ()
  (run-shell-command "pamixer --decrease 5")
  (message "^BVol^n ~A" (volume-str)))

(defcommand volume-mute-toggle () ()
  (run-shell-command "pamixer --toggle-mute")
  (message "^BVol^n ~A" (volume-str)))

(defun volume-setup-keys ()
  (define-key *top-map* (kbd "XF86AudioRaiseVolume") "volume-up")
  (define-key *top-map* (kbd "XF86AudioLowerVolume") "volume-down")
  (define-key *top-map* (kbd "XF86AudioMute")        "volume-mute-toggle")
  (add-screen-mode-line-formatter #\v
    (lambda (ml)
      (declare (ignore ml))
      (volume-str))))

;;;; ===========================================================================
;;;; Modeline (bottom bar)
;;;; ===========================================================================

(defun modeline-setup ()
  ;; Network formatter %k
  (add-screen-mode-line-formatter #\k
    (lambda (ml)
      (declare (ignore ml))
      (let ((state (string-trim '(#\Newline #\Space)
                     (run-shell-command
                       "nmcli -t -f CONNECTIVITY general 2>/dev/null" t))))
        (cond ((string= state "full")    "^2NET^n")
              ((string= state "limited") "^3NET?^n")
              (t                         "^1NET^n")))))
  ;; Disable first if running so position/color changes take effect on reload
  (when (stumpwm::head-mode-line (current-head))
    (toggle-mode-line (current-screen) (current-head)))
  ;; Apply config
  (setf *mode-line-position*         :bottom
        *mode-line-background-color* "#1a1a2e"
        *mode-line-foreground-color* "#e0e0e0"
        *mode-line-border-color*     "#444466"
        *mode-line-pad-x*            8
        *mode-line-pad-y*            2
        *mode-line-timeout*          10
        *time-modeline-string*       "%s"
        *screen-mode-line-format*    "[^B%n^b] %W^> %v  %k  %d")
  ;; Enable
  (toggle-mode-line (current-screen) (current-head)))

(run-with-timer 4 nil #'modeline-setup)

(volume-setup-keys)

(defun run-if-not-running (process command)
  "Start COMMAND if PROCESS is not already running."
  (let ((result (run-shell-command
                 (format nil "pgrep -x ~A > /dev/null || ~A &" process command) t)))
    result))

;;;; Show keybinding cheatsheet at startup
(run-with-timer 2 nil #'show-keybindings)

(run-if-not-running "dropbox" "/home/vxe/bin/dropbox start")
(run-if-not-running "polybar" "polybar main")

;;;; ===========================================================================
;;;; whisper-clip (voice-to-clipboard)
;;;; ===========================================================================

(load "/home/vxe/.stumpwm.d/lib/whisper-clip/whisper-clip.lisp")

;; Start the whisper.cpp server if not already running
(run-shell-command
 "pgrep -x whisper-server > /dev/null || \
  ~/.stumpwm.d/lib/whisper-clip/start-server.sh >> /tmp/whisper-server.log 2>&1 &")
