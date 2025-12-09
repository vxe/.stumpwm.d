;;;; infra.lisp --- Infrastructure utilities for StumpWM
;;;;
;;;; This package handles build, release, and external dependency management.
;;;;

(defpackage #:stumpwm-infra
  (:use #:cl #:stumpwm))

(in-package #:stumpwm-infra)

(defun ensure-directory (path)
  "Ensure directory exists, create if needed."
  (ensure-directories-exist (merge-pathnames path (user-homedir-pathname))))

(defun git-clone-if-needed (repo-url target-dir)
  "Clone git repository if target directory doesn't exist.
Returns T if cloned/exists, NIL on error."
  (let ((full-path (merge-pathnames target-dir (user-homedir-pathname))))
    (if (probe-file full-path)
        (progn
          (message (format nil "~A already exists, skipping clone" target-dir))
          t)
        (handler-case
            (progn
              (message (format nil "Cloning ~A to ~A..." repo-url target-dir))
              (run-shell-command (format nil "git clone ~A ~A"
                                        repo-url
                                        (namestring full-path)))
              (message (format nil "^2✓ Cloned ~A^n" target-dir))
              t)
          (error (e)
            (message (format nil "^1✗ Failed to clone ~A: ~A^n" repo-url e))
            nil)))))

(defun load-external-system (system-name lib-path)
  "Load an external ASDF system from a local path.
SYSTEM-NAME: The name of the ASDF system to load (as keyword or string)
LIB-PATH: Path to the directory containing the .asd file (relative to home)"
  (let* ((full-path (merge-pathnames lib-path (user-homedir-pathname)))
         (system-kw (if (keywordp system-name)
                        system-name
                        (intern (string-upcase system-name) :keyword))))
    (handler-case
        (progn
          ;; Add the directory to ASDF's search path
          (pushnew full-path asdf:*central-registry* :test #'equal)

          ;; Try to load the system
          (message (format nil "Loading external system ~A..." system-name))
          (asdf:load-system system-kw)
          (message (format nil "^2✓ Loaded ~A^n" system-name))
          t)
      (error (e)
        (message (format nil "^1✗ Failed to load ~A: ~A^n" system-name e))
        nil))))

(defun install-and-load-external-lib (repo-url system-name lib-path)
  "Complete workflow: clone repo if needed, then load the system.
REPO-URL: Git repository URL
SYSTEM-NAME: ASDF system name (keyword or string)
LIB-PATH: Where to clone (relative to home directory)"
  (when (git-clone-if-needed repo-url lib-path)
    (load-external-system system-name lib-path)))

;;;; ===========================================================================
;;;; Specific External Libraries
;;;; ===========================================================================

(defun install-cl-xembed ()
  "Install and load cl-xembed (required for stumptray)."
  (install-and-load-external-lib
   "https://github.com/laynor/clx-xembed.git"
   "xembed"
   "lib/clx-xembed/"))

(defcommand install-cl-xembed-cmd () ()
  "Install cl-xembed library for stumptray support."
  (if (install-cl-xembed)
      (message "^2✓ cl-xembed installed successfully!^n")
      (message "^1✗ Failed to install cl-xembed^n")))

;;; infra.lisp ends here
