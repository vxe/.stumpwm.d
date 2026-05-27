(load "/home/vxe/.quicklisp/setup.lisp")
(ql:quickload :croatoan :silent t)

(defpackage :dropbox-tui
  (:use :cl :croatoan))
(in-package :dropbox-tui)

(defun shell-line (cmd)
  "Run CMD and return its first non-empty output line, trimmed."
  (let* ((raw (with-output-to-string (out)
                (uiop:run-program cmd :output out :ignore-error-status t)))
         (newline (position #\Newline raw)))
    (string-trim '(#\Space #\Tab #\Return)
                 (if newline (subseq raw 0 newline) raw))))

(defun draw-centered (win y text &key bold reverse)
  (let* ((w (width win))
         (x (max 0 (floor (- w (length text)) 2)))
         (attrs (append (when bold    '(:bold))
                        (when reverse '(:reverse)))))
    (add-string win text :y y :x x :attributes attrs)))

(defun draw-hotkeys (scr y &optional pressed)
  "Draw the hotkey line. PRESSED is a character to highlight."
  (let* ((keys '(#\q #\r #\s #\a))
         (labels '("quit" "refresh" "stop" "start"))
         (segments (loop for k in keys for l in labels
                         collect (format nil "[~A] ~A" k l)))
         (line (format nil "~{~A~^   ~}" segments))
         (w (width scr))
         (x (max 0 (floor (- w (length line)) 2))))
    (add-string scr line :y y :x x)
    (when pressed
      (let ((segment-x x))
        (dolist (k keys)
          (let ((seg-len (+ 4 (length (elt labels (position k keys))))))
            (when (char= k pressed)
              (add-string scr (format nil "[~A]" k) :y y :x segment-x
                          :attributes '(:reverse :bold)))
            (incf segment-x (+ seg-len 3))))))))

(defun draw (scr &optional pressed)
  (let* ((status  (shell-line "/home/vxe/bin/dropbox status"))
         (running (shell-line "/home/vxe/bin/dropbox running"))
         (version (shell-line "/home/vxe/bin/dropbox version"))
         (h  (height scr))
         (cy (floor h 2)))
    (clear scr)
    (box scr)
    (draw-centered scr (- cy 4) "Dropbox" :bold t)
    (draw-centered scr (- cy 1) (format nil "Status:  ~A" status))
    (draw-centered scr cy       (format nil "Running: ~A"
                                        (if (zerop (length running)) "yes" running)))
    (draw-centered scr (+ cy 1) (format nil "Version: ~A" version))
    (draw-hotkeys scr (+ cy 4) pressed)
    (refresh scr)))

(defun show ()
  (with-screen (scr :input-echoing nil
                    :input-blocking 2000
                    :cursor-visible nil
                    :enable-colors t)
    (draw scr)
    (loop
      (let* ((ev  (get-event scr))
             (key (and ev (event-key ev))))
        (cond
          ((null key) (draw scr))            ; timeout → refresh
          ((or (eq key #\q) (eq key :q)) (return))
          ((or (eq key #\r) (eq key :r))
           (draw scr #\r) (sleep 0.15) (draw scr))
          ((or (eq key #\s) (eq key :s))
           (draw scr #\s) (sleep 0.15)
           (uiop:run-program "/home/vxe/bin/dropbox stop"
                             :ignore-error-status t)
           (draw scr))
          ((or (eq key #\a) (eq key :a))
           (draw scr #\a) (sleep 0.15)
           (uiop:run-program "/home/vxe/bin/dropbox start"
                             :ignore-error-status t)
           (draw scr)))))))

(show)
