;;;; Music session integration for StumpWM.
;;;; Loaded from init.lisp. Provides:
;;;;   *music-map*           the H-m prefix keymap
;;;;   music-session-start   boot scsynth + cl-collider into the running image
;;;;   play-note             trigger a short tone in the current session
;;;;   music-repl            floating SBCL REPL preloaded with the music stack
;;;;
;;;; All commands are idempotent — re-invocation must not start a second
;;;; scsynth or duplicate-load packages.

(in-package :stumpwm)

(defparameter *music-scsynth-port* 57110)
(defparameter *music-session-loaded* nil
  "T once cl-collider has been quickloaded into this image.")
(defparameter *music-synthdefs-registered* nil)

(defun music--scsynth-running-p ()
  (zerop
   (sb-ext:process-exit-code
    (sb-ext:run-program "/bin/sh"
                        (list "-c" "pgrep -x scsynth > /dev/null")
                        :wait t))))

(defun music--ensure-scsynth ()
  (unless (music--scsynth-running-p)
    (sb-ext:run-program
     "/bin/sh"
     (list "-c"
           (format nil "scsynth -u ~A >> /tmp/scsynth.log 2>&1 &"
                   *music-scsynth-port*))
     :wait t)
    (sleep 0.6)))

(defun music--sc-symbol (name)
  "Look up an external symbol in the :SC package. Errors if not found."
  (let* ((pkg (find-package :sc))
         (sym (and pkg (find-symbol (string name) pkg))))
    (unless sym
      (error "cl-collider :SC package symbol ~A not found" name))
    sym))

(defun music--register-synthdefs ()
  "Define music-blip once. Must run after cl-collider is loaded and scsynth is up."
  (unless *music-synthdefs-registered*
    (eval `(,(music--sc-symbol "DEFSYNTH") music-blip ((freq 440))
            (let* ((sig (,(music--sc-symbol "SIN-OSC.AR") freq 0 0.2))
                   (env (,(music--sc-symbol "ENV-GEN.KR")
                         (,(music--sc-symbol "ENV") '(0 1 1 0) '(0.05 0.4 0.05))
                         :act :free)))
              (,(music--sc-symbol "OUT.AR") 0 (* sig env)))))
    (setf *music-synthdefs-registered* t)))

(defun music--load-cl-collider ()
  (unless *music-session-loaded*
    (ql:quickload :cl-collider :silent t)
    (setf *music-session-loaded* t))
  (let* ((*s-sym*              (music--sc-symbol "*S*"))
         (make-external-server (music--sc-symbol "MAKE-EXTERNAL-SERVER"))
         (server-boot          (music--sc-symbol "SERVER-BOOT"))
         (boot-p               (music--sc-symbol "BOOT-P")))
    ;; Bind *s* once; if already bound to a booted server, leave it alone.
    (unless (and (boundp *s-sym*)
                 (symbol-value *s-sym*)
                 (handler-case (funcall boot-p (symbol-value *s-sym*))
                   (error () nil)))
      (let ((srv (funcall make-external-server "localhost"
                          :port *music-scsynth-port*
                          :just-connect-p t)))
        (set *s-sym* srv)
        (funcall server-boot srv)))))

(defcommand music-session-start () ()
  "Boot scsynth (if not already) and load cl-collider into the running image."
  (handler-case
      (progn
        (music--ensure-scsynth)
        (music--load-cl-collider)
        (music--register-synthdefs)
        (message "^2Music session ready^n  (scsynth :~A, cl-collider loaded)"
                 *music-scsynth-port*))
    (error (e)
      (message "^1music-session-start failed:^n ~A" e))))

(defcommand play-note (&optional (freq "440")) ((:string "Freq: "))
  "Trigger a short sine at FREQ Hz. Requires music-session-start first."
  (unless *music-session-loaded*
    (message "^1play-note:^n session not started — run H-m m first")
    (return-from play-note))
  (handler-case
      (let ((synth-fn (music--sc-symbol "SYNTH"))
            (hz       (or (parse-integer freq :junk-allowed t) 440)))
        (funcall synth-fn 'music-blip :freq hz)
        (message "^2♪^n ~AHz" hz))
    (error (e)
      (message "^1play-note failed:^n ~A" e))))

(defun music--find-window-by-class (class-name)
  (find-if (lambda (w) (string= (window-class w) class-name))
           (group-windows (current-group))))

(defun music--center-popup (class-name width height)
  "Wait briefly for a window of CLASS-NAME to appear and resize/center it."
  (run-with-timer
   1.0 nil
   (lambda ()
     (let* ((win (music--find-window-by-class class-name))
            (screen-w 1920)   ; XXX: hardcoded; matches stumpwm-polybar resize-head
            (screen-h 1054))
       (when win
         (let ((x (max 0 (floor (- screen-w width) 2)))
               (y (max 0 (floor (- screen-h height) 2))))
           (stumpwm::float-window-move-resize
            win :x x :y y :width width :height height)))))))

(defcommand music-repl () ()
  "Open a floating kitty SBCL REPL with cl-collider + cl-patterns preloaded."
  (run-shell-command
   "kitty --class MusicREPL \\
      -e sbcl \\
        --eval '(load \"/home/vxe/.quicklisp/setup.lisp\")' \\
        --eval '(ql:quickload :cl-collider :silent t)' \\
        --eval '(ql:quickload :cl-patterns :silent t)' \\
        --eval '(in-package :sc)'")
  (music--center-popup "MusicREPL" 1360 800))

;;;; Float rule for the music REPL popup
(define-frame-preference nil
  (:float t t :class "MusicREPL"))

;;;; Key map: H-m as a sparse keymap
(defvar *music-map* (make-sparse-keymap))
(define-key *music-map* (kbd "m") "music-session-start")
(define-key *music-map* (kbd "n") "play-note")
(define-key *music-map* (kbd "r") "music-repl")
(define-key *top-map*   (kbd "H-m") '*music-map*)
