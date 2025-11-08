;;;; init.lisp --- StumpWM + Claude Integration Entry Point
;;;;
;;;; This is the main configuration file for the Claude-integrated
;;;; Lisp desktop environment. It loads all modules and sets up
;;;; the unified workspace.
;;;;
;;;; Author: Vijay Edwin
;;;; Version: 0.1-alpha

(in-package :stumpwm)

;;;; ===========================================================================
;;;; Configuration Loading Order
;;;; ===========================================================================

(defvar *stumpwm-config-dir*
  (directory-namestring
   (truename (merge-pathnames (user-homedir-pathname) ".stumpwm.d/")))
  "The root directory of StumpWM configuration.")

(defun load-config-file (filename)
  "Load a configuration file from the config directory."
  (let ((file (merge-pathnames filename *stumpwm-config-dir*)))
    (if (probe-file file)
        (progn
          (message (format nil "Loading ~A..." filename))
          (load file))
        (message (format nil "Warning: ~A not found" filename)))))

(defun load-module-file (filename)
  "Load a module file from the modules directory."
  (load-config-file (format nil "modules/~A" filename)))

(defun load-lib-file (filename)
  "Load a library file from the lib directory."
  (load-config-file (format nil "lib/~A" filename)))

;;;; ===========================================================================
;;;; Startup Message
;;;; ===========================================================================

(message "^B^7Welcome to Claude-Integrated StumpWM^n")
(message "Initializing Lisp Desktop Environment...")

;;;; ===========================================================================
;;;; Core Configuration
;;;; ===========================================================================

;; Load core settings first
(load-config-file "desktop/core.lisp")

;;;; ===========================================================================
;;;; Library Loading
;;;; ===========================================================================

;; Load utility libraries (order matters - utils first, then higher-level)
(load-lib-file "utils.lisp")
(load-lib-file "http-client.lisp")

;;;; ===========================================================================
;;;; Module Loading
;;;; ===========================================================================

;; Load Swank/SLY integration for interactive development
(load-module-file "claude-swank.lisp")

;; Load Claude integration modules
(load-module-file "context-gathering.lisp")
(load-module-file "claude-integration.lisp")
(load-module-file "claude-commands.lisp")

;;;; ===========================================================================
;;;; User Interface Configuration
;;;; ===========================================================================

;; Load theme and visual configuration
(load-config-file "desktop/theme.lisp")

;; Load custom commands
(load-config-file "desktop/commands.lisp")

;; Load keybindings last (so all commands are defined)
(load-config-file "desktop/keybindings.lisp")

;;;; ===========================================================================
;;;; Post-Initialization
;;;; ===========================================================================

;; Start Swank server for SLY integration (optional, can be started manually)
(when (and (fboundp 'start-swank-server)
           (not (swank-server-running-p)))
  (message "Starting Swank server for SLY integration...")
  (start-swank-server))

;;;; ===========================================================================
;;;; Completion Message
;;;; ===========================================================================

(message "^B^2Claude-Integrated StumpWM Loaded Successfully!^n")
(message "Press ^B^3Super+Space^n to invoke Claude")
(message "Press ^B^3Super+Ctrl+S^n to start Swank REPL server")
(message "Use ^B^3Super+?^n to see all keybindings")

;;;; ===========================================================================
;;;; Optional: Load user-specific overrides
;;;; ===========================================================================

;; Load local configuration if it exists (not in version control)
(let ((local-config (merge-pathnames "local-config.lisp" *stumpwm-config-dir*)))
  (when (probe-file local-config)
    (message "Loading local configuration...")
    (load local-config)))

;;; init.lisp ends here
