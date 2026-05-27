;;;; Smoke test for cl-collider against a running scsynth.
;;;; Run with:  sbcl --script test-cl-collider.lisp
;;;; Expects scsynth to be listening on UDP 57110.
;;;; Exit code 0 = success, non-zero = some assertion failed.

(load "/home/vxe/.quicklisp/setup.lisp")
(ql:quickload :cl-collider :silent t)

(defpackage :cl-collider-test (:use :cl :sc))
(in-package :cl-collider-test)

(defun die (fmt &rest args)
  (format *error-output* "FAIL: ~A~%" (apply #'format nil fmt args))
  (sb-ext:exit :code 1))

(handler-case
    (progn
      (setf sc::*s* (sc:make-external-server "localhost"
                                             :port 57110
                                             :just-connect-p t))
      (sc:server-boot sc::*s*)
      (format t "OK  connected: ~A~%" sc::*s*))
  (error (e) (die "server-boot: ~A" e)))

(unless (sc:boot-p sc::*s*)
  (die "boot-p false after server-boot"))
(format t "OK  boot-p true~%")

(handler-case
    (progn
      (sc:defsynth blip ((freq 440))
        (let* ((sig (sc:sin-osc.ar freq 0 0.2))
               (env (sc:env-gen.kr (sc:env '(0 1 1 0) '(0.05 0.4 0.05))
                                   :act :free)))
          (sc:out.ar 0 (* sig env))))
      (format t "OK  defsynth blip~%"))
  (error (e) (die "defsynth: ~A" e)))

(handler-case
    (let ((node (sc:synth 'blip)))
      (format t "OK  triggered blip → node ~A~%" node)
      (sleep 1.0))
  (error (e) (die "synth: ~A" e)))

(format t "OK  all assertions held~%")
(sb-ext:exit :code 0)
