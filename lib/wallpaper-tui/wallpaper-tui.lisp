(load "/home/vxe/.quicklisp/setup.lisp")
(ql:quickload :croatoan :silent t)

(defpackage :wallpaper-tui
  (:use :cl :croatoan))
(in-package :wallpaper-tui)

(defparameter *wall-dir* (merge-pathnames "Pictures/wallpapers/" (user-homedir-pathname)))
(defparameter *state-file* (merge-pathnames ".config/polybar/current-wallpaper"
                                            (user-homedir-pathname)))

(defun list-wallpapers ()
  (sort
   (loop for path in (directory (merge-pathnames "*.*" *wall-dir*))
         for ext = (string-downcase (or (pathname-type path) ""))
         when (member ext '("jpg" "jpeg" "png" "webp" "bmp" "tiff") :test #'string=)
         collect (file-namestring path))
   #'string<))

(defun apply-wallpaper (name)
  (let ((full (namestring (merge-pathnames name *wall-dir*))))
    (uiop:run-program (list "feh" "--bg-fill" full)
                      :ignore-error-status t)
    (with-open-file (s *state-file* :direction :output
                                    :if-exists :supersede
                                    :if-does-not-exist :create)
      (write-string name s))))

(defun read-saved-wallpaper ()
  (when (probe-file *state-file*)
    (with-open-file (s *state-file*) (read-line s nil nil))))

(defun draw-list (scr items selected original)
  (clear scr)
  (box scr)
  (let* ((h (height scr))
         (start-y 2)
         (visible (- h 5)))
    (add-string scr "Wallpaper Selector" :y 0 :x 2 :attributes '(:bold))
    (if (null items)
      (add-string scr (format nil "  No wallpapers in ~A" *wall-dir*)
                  :y 2 :x 2 :attributes '(:dim))
      (loop for item in items
            for i from 0
            while (< i visible)
            do (let ((current-p (= i selected))
                     (orig-p    (string= item original)))
                 (add-string scr
                             (format nil "~A ~A~A"
                                     (if current-p "▶" " ")
                                     item
                                     (if orig-p "  (current)" ""))
                             :y (+ start-y i) :x 2
                             :attributes (cond (current-p '(:reverse :bold))
                                               (orig-p    '(:dim))
                                               (t         nil))))))
    (add-string scr "↑/↓ preview   [enter] apply   [esc/q] revert"
                :y (- h 2) :x 2 :attributes '(:dim))
    (refresh scr)))

(defun show ()
  (let* ((items    (list-wallpapers))
         (original (or (read-saved-wallpaper) (first items)))
         (selected (or (position original items :test #'string=) 0)))
    (with-screen (scr :input-echoing nil
                      :input-blocking t
                      :cursor-visible nil
                      :enable-colors t)
      (when items (apply-wallpaper (nth selected items)))
      (loop
        (draw-list scr items selected original)
        (let* ((ev  (get-event scr))
               (raw (event-key ev))
               (key (if (typep raw 'croatoan:key)
                        (croatoan:key-name raw)
                        raw)))
          (cond
            ((or (eql key #\q) (eq key :escape))
             (when original (apply-wallpaper original))
             (return))
            ((or (eql key #\Newline) (eq key :enter) (eq key :newline))
             (when items (apply-wallpaper (nth selected items)))
             (return))
            ((or (eq key :up) (eql key #\k))
             (when items (setf selected (mod (1- selected) (length items))))
             (when items (apply-wallpaper (nth selected items))))
            ((or (eq key :down) (eql key #\j))
             (when items (setf selected (mod (1+ selected) (length items))))
             (when items (apply-wallpaper (nth selected items))))))))))

(show)
