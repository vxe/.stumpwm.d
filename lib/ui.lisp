;;;; ui.lisp --- Custom UI Widgets for StumpWM
;;;;
;;;; This file contains custom UI widgets and components we've built for StumpWM.
;;;; All custom UI elements, menus, popups, and interactive widgets should live here.
;;;;
;;;; Currently includes:
;;;;   - stump-completing-read: Centered posframe-like menus with filtering
;;;;   - Audio sink selection
;;;;   - Bluetooth device selection
;;;;   - WiFi network selection
;;;;   - Stumplight launcher (Apple Spotlight-like)
;;;;

(defpackage #:stumpwm-ui
  (:use #:cl #:stumpwm))

(in-package #:stumpwm-ui)

;;;; ===========================================================================
;;;; Core Posframe Menu Function
;;;; ===========================================================================

(defun stump-completing-read (prompt choices)
  "Display a centered menu with filtering support (posframe-like).
PROMPT is the prompt string.
CHOICES is a list of strings to choose from.

Keybindings:
  Up/Down or C-p/C-n - Navigate options
  Type letters       - Filter options
  Backspace          - Delete filter characters
  RET                - Select current item
  ESC or C-g         - Cancel

Returns a list with the selected choice, or NIL if cancelled."
  (let* ((*message-window-gravity* :center)
         (*suppress-echo-timeout* t)
         (screen (current-screen))
         (selected 0)
         (filter "")
         (done nil)
         (result nil)
         ;; Pre-compute key constants
         (key-down (kbd "Down"))
         (key-up (kbd "Up"))
         (key-c-n (kbd "C-n"))
         (key-c-p (kbd "C-p"))
         (key-ret (kbd "RET"))
         (key-backspace (kbd "BackSpace"))
         (key-del (kbd "DEL"))
         (key-esc (kbd "ESC"))
         (key-c-g (kbd "C-g")))
    (labels ((filtered-choices ()
               (if (string= filter "")
                   choices
                   (remove-if-not
                    (lambda (item)
                      (search filter item :test #'char-equal))
                    choices)))
             (display-menu ()
               (let* ((items (filtered-choices))
                      (display-items (cons (format nil "~A~A" prompt
                                                  (if (string= filter "") ""
                                                      (format nil " [~A]" filter)))
                                          items)))
                 (when (>= selected (length items))
                   (setf selected (max 0 (1- (length items)))))
                 (stumpwm::echo-string-list screen display-items (1+ selected)))))
      (unwind-protect
           (loop until done do
             (display-menu)
             (let ((key (stumpwm::read-key)))
               (cond
                 ;; Down arrow or C-n
                 ((or (equalp key key-down)
                      (equalp key key-c-n))
                  (setf selected (mod (1+ selected) (max 1 (length (filtered-choices))))))

                 ;; Up arrow or C-p
                 ((or (equalp key key-up)
                      (equalp key key-c-p))
                  (setf selected (mod (1- selected) (max 1 (length (filtered-choices))))))

                 ;; Return - select current
                 ((equalp key key-ret)
                  (let ((items (filtered-choices)))
                    (when items
                      (setf result (list (nth selected items))
                            done t))))

                 ;; Backspace - delete from filter
                 ((or (equalp key key-backspace)
                      (equalp key key-del))
                  (when (> (length filter) 0)
                    (setf filter (subseq filter 0 (1- (length filter)))
                          selected 0)))

                 ;; Escape or C-g - abort
                 ((or (equalp key key-esc)
                      (equalp key key-c-g))
                  (setf done t))

                 ;; Printable character - add to filter
                 ((and (characterp (stumpwm::key-key key))
                       (graphic-char-p (stumpwm::key-key key)))
                  (setf filter (concatenate 'string filter (string (stumpwm::key-key key)))
                        selected 0)))))
        (stumpwm::unmap-all-message-windows)))
    result))

;;;; ===========================================================================
;;;; Audio Sink Selection
;;;; ===========================================================================

(defun get-audio-sinks ()
  "Get list of audio sinks from PulseAudio/PipeWire."
  (let* ((output (run-shell-command "pactl list sinks short" t))
         (lines (when output (split-string output (string #\Newline)))))
    (remove-if (lambda (s) (string= s ""))
               (mapcar (lambda (line)
                        (let* ((parts (split-string line (string #\Tab)))
                               (id (first parts))
                               (name (second parts)))
                          (when (and id name)
                            (format nil "~A: ~A" id name))))
                      lines))))

(defcommand select-audio-sink () ()
  "Select audio output sink with posframe-like centered menu."
  (let* ((sinks (get-audio-sinks))
         (selection-list (stump-completing-read "Audio Sink: " sinks))
         (selection (first selection-list)))
    (when selection
      (let ((sink-id (first (split-string selection ":"))))
        (run-shell-command (format nil "pactl set-default-sink ~A" sink-id))
        (message (format nil "^2✓ Audio sink set to: ~A^n" selection))))))

;;;; ===========================================================================
;;;; Bluetooth Device Selection
;;;; ===========================================================================

(defun get-bluetooth-devices ()
  "Get list of paired Bluetooth devices."
  (let* ((output (run-shell-command "bluetoothctl devices" t))
         (lines (when output (split-string output (string #\Newline)))))
    (remove-if (lambda (s) (string= s ""))
               (mapcar (lambda (line)
                        (when (search "Device" line)
                          (let ((parts (split-string (subseq line 7) " " :limit 2)))
                            (when (>= (length parts) 2)
                              (format nil "~A: ~A" (first parts) (second parts))))))
                      lines))))

(defcommand select-bluetooth () ()
  "Connect to Bluetooth device with posframe-like menu."
  (let* ((devices (get-bluetooth-devices))
         (selection-list (stump-completing-read "Bluetooth: " devices))
         (selection (first selection-list)))
    (when selection
      (let ((mac (first (split-string selection ":"))))
        (message "Connecting...")
        (run-shell-command (format nil "bluetoothctl connect ~A" mac))
        (sleep 1)
        (message (format nil "^2✓ Connected to: ~A^n" selection))))))

;;;; ===========================================================================
;;;; WiFi Network Selection
;;;; ===========================================================================

(defun get-wifi-networks ()
  "Get list of available WiFi networks."
  (let* ((output (run-shell-command "nmcli -t -f SSID,SIGNAL dev wifi list" t))
         (lines (when output (split-string output (string #\Newline)))))
    (remove-if (lambda (s) (string= s ""))
               (mapcar (lambda (line)
                        (let ((parts (split-string line ":")))
                          (when (>= (length parts) 2)
                            (format nil "~A (~A%)" (first parts) (second parts)))))
                      lines))))

(defcommand select-wifi () ()
  "Select WiFi network with posframe-like menu."
  (let* ((networks (get-wifi-networks))
         (selection-list (stump-completing-read "WiFi Network: " networks))
         (selection (first selection-list)))
    (when selection
      (let ((ssid (first (split-string selection " "))))
        (message (format nil "Connecting to ~A..." ssid))
        (run-shell-command (format nil "nmcli dev wifi connect '~A'" ssid))))))

;;;; ===========================================================================
;;;; Stumplight Launcher (Apple Spotlight-like)
;;;; ===========================================================================

(defvar *app-cache* nil "Cached list of (name . exec) pairs")

(defun parse-desktop-file (filepath)
  "Parse a .desktop file and return (name . exec-command) or NIL"
  (when (probe-file filepath)
    (with-open-file (stream filepath :direction :input)
      (let ((name nil) (exec nil) (nodisplay nil))
        (loop for line = (read-line stream nil nil) while line do
          (cond
            ((and (>= (length line) 16)
                  (string= "NoDisplay=true" line :start2 0 :end2 (min 14 (length line))))
             (setf nodisplay t))
            ((and (not name) (>= (length line) 5) (string= "Name=" line :end2 5))
             (setf name (string-trim " " (subseq line 5))))
            ((and (not exec) (>= (length line) 5) (string= "Exec=" line :end2 5))
             (setf exec (string-trim " " (subseq line 5))))))
        (when (and name exec (not nodisplay))
          (cons name exec))))))

(defun build-app-cache ()
  "Parse all .desktop files and cache results"
  (let ((desktop-dirs (list "/usr/share/applications/"
                           (merge-pathnames ".local/share/applications/" (user-homedir-pathname))))
        (apps nil))
    (dolist (dir desktop-dirs)
      (when (probe-file dir)
        (dolist (file (directory (merge-pathnames "*.desktop" dir)))
          (let ((app (parse-desktop-file file)))
            (when app (push app apps))))))
    (setf *app-cache* (nreverse apps))
    *app-cache*))

(defun stumplight-filter-apps (query)
  "Filter apps by query string (case-insensitive substring match)"
  (if (string= query "") *app-cache*
      (remove-if-not (lambda (app)
                      (search query (car app) :test #'char-equal))
                    *app-cache*)))

(defcommand stumplight () ()
  "Launch Apple Spotlight-like app launcher"
  (unless *app-cache* (build-app-cache))
  (stumpwm::unmap-all-message-windows)
  (let* ((*message-window-gravity* :center)
         (*suppress-echo-timeout* t)
         (screen (current-screen))
         (selected 0) (query "") (done nil)
         ;; Pre-compute key constants
         (key-down (kbd "Down"))
         (key-up (kbd "Up"))
         (key-c-n (kbd "C-n"))
         (key-c-p (kbd "C-p"))
         (key-ret (kbd "RET"))
         (key-backspace (kbd "BackSpace"))
         (key-del (kbd "DEL"))
         (key-esc (kbd "ESC"))
         (key-c-g (kbd "C-g")))
    (labels ((filtered-apps ()
               (let ((matches (stumplight-filter-apps query)))
                 (subseq matches 0 (min 10 (length matches)))))
             (display-spotlight ()
               (let* ((apps (filtered-apps))
                      (app-names (mapcar #'car apps))
                      (display-items (cons (format nil "Launch: ~A" query) app-names)))
                 (when (>= selected (length apps))
                   (setf selected (max 0 (1- (length apps)))))
                 (stumpwm::echo-string-list screen display-items (1+ selected)))))
      (unwind-protect
           (loop until done do
             (display-spotlight)
             (let ((key (stumpwm::read-key)))
               (cond
                 ((or (equalp key key-down) (equalp key key-c-n))
                  (when (> (length (filtered-apps)) 0)
                    (setf selected (mod (1+ selected) (length (filtered-apps))))))
                 ((or (equalp key key-up) (equalp key key-c-p))
                  (when (> (length (filtered-apps)) 0)
                    (setf selected (mod (1- selected) (length (filtered-apps))))))
                 ((equalp key key-ret)
                  (let ((apps (filtered-apps)))
                    (when (and apps (< selected (length apps)))
                      (run-shell-command (cdr (nth selected apps)))
                      (setf done t))))
                 ((or (equalp key key-backspace) (equalp key key-del))
                  (when (> (length query) 0)
                    (setf query (subseq query 0 (1- (length query))) selected 0)))
                 ((or (equalp key key-esc) (equalp key key-c-g))
                  (setf done t))
                 (t
                  (let ((ch (xlib:keysym->character stumpwm::*display* (stumpwm::key-keysym key))))
                    (when (and ch (graphic-char-p ch))
                      (setf query (concatenate 'string query (string ch)) selected 0)))))))
        (stumpwm::unmap-all-message-windows)))))

;;; ui.lisp ends here
