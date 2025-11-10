;;;; init.lisp --- StumpWM Configuration
;;;;
;;;; Loads swank FIRST for interactive development, then everything else
;;;;

(in-package :stumpwm)

;;;; ===========================================================================
;;;; PRIORITY 1: Load Quicklisp (required for swank)
;;;; ===========================================================================

(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname))))
  (when (probe-file quicklisp-init)
    (handler-case
        (progn
          (load quicklisp-init)
          (message "✓ Quicklisp loaded"))
      (error (e)
        (message (format nil "✗ Quicklisp failed: ~A" e))))))

;;;; ===========================================================================
;;;; PRIORITY 2: Start Slynk Server IMMEDIATELY
;;;; ===========================================================================

(handler-case
    (progn
      (message "Loading Slynk...")

      ;; Load slynk via quicklisp
      (unless (find-package :slynk)
        (if (find-package :quicklisp)
            (funcall (intern "QUICKLOAD" :quicklisp) :slynk)
            (asdf:load-system :slynk)))

      ;; Start the server
      (let ((slynk-package (find-package :slynk)))
        (when slynk-package
          (let ((create-server (intern "CREATE-SERVER" slynk-package)))
            (funcall create-server :port 4005 :dont-close t)
            (message "^B^2✓ Slynk server running on port 4005^n")
            (message "Connect: M-x sly-connect RET localhost RET 4005 RET")))))
  (error (e)
    (message (format nil "^1✗ Slynk failed: ~A^n" e))
    (message "To fix: In a terminal run: sbcl --eval '(ql:quickload :slynk)' --quit")))

;;;; ===========================================================================
;;;; Dynamic Swank/Slynk Port Command
;;;; ===========================================================================

(defcommand swank-dynamic (port) ((:string "Port number: "))
  "Start a Swank server on a custom port"
  (handler-case
      (sb-thread:make-thread
       (lambda ()
         (let ((swank-package (find-package :swank)))
           (if swank-package
               (let ((create-server (intern "CREATE-SERVER" swank-package)))
                 (funcall create-server :port (parse-integer port) :dont-close t)
                 (message (format nil "^2✓ Swank server running on port ~A^n" port))
                 (message (format nil "Connect: M-x sly-connect RET localhost RET ~A RET" port)))
               (message "^1✗ Swank package not loaded^n"))))
       :name (format nil "swank-~A" port))
    (error (e)
      (message (format nil "^1✗ Failed to start Swank on port ~A: ~A^n" port e)))))

;; For when you switch to Slynk (uncomment if needed):
;; (defcommand slynk (port) ((:string "Port number: "))
;;   "Start a Slynk server on a custom port"
;;   (handler-case
;;       (sb-thread:make-thread
;;        (lambda ()
;;          (let ((slynk-package (find-package :slynk)))
;;            (if slynk-package
;;                (let ((create-server (intern "CREATE-SERVER" slynk-package)))
;;                  (funcall create-server :port (parse-integer port) :dont-close t)
;;                  (message (format nil "^2✓ Slynk server running on port ~A^n" port))
;;                  (message (format nil "Connect: M-x sly-connect RET localhost RET ~A RET" port)))
;;                (message "^1✗ Slynk package not loaded^n"))))
;;        :name (format nil "slynk-~A" port))
;;     (error (e)
;;       (message (format nil "^1✗ Failed to start Slynk on port ~A: ~A^n" port e)))))

;;;; ===========================================================================
;;;; PRIORITY 3: Load Contrib Modules
;;;; ===========================================================================

;; Add contrib modules to load path
(init-load-path "~/.stumpwm-contrib/")

;; Load modeline modules
(load-module "cpu")              ; %C = CPU usage
(load-module "mem")              ; %M = Memory usage
(load-module "wifi")             ; %I = Wifi ESSID/signal
(load-module "battery-portable") ; %B = Battery percentage

;; Load utility modules
(load-module "clipboard-history")
(load-module "winner-mode")

;;;; ===========================================================================
;;;; PRIORITY 4: File-Based Eval System (for stumpwm-eval command)
;;;; ===========================================================================

(message "Loading stumpwm-eval module...")
(handler-case
    (progn
      ;; Load the eval module
      (load (merge-pathnames ".stumpwm.d/modules/stumpwm-eval.lisp" (user-homedir-pathname)))
      (message "^2✓ stumpwm-eval module loaded^n")

      ;; Start the eval watcher using funcall to avoid package issues
      (when (fboundp 'start-eval-watcher)
        (funcall (symbol-function 'start-eval-watcher))
        (message "^B^2✓ stumpwm-eval watcher started!^n")
        (message "Test with: stumpwm-eval '(+ 1 2)'")))
  (error (e)
    (message (format nil "^1✗ stumpwm-eval error: ~A^n" e))))

;;;; ===========================================================================
;;;; Helper Functions
;;;; ===========================================================================

(defvar *stumpwm-config-dir*
  (directory-namestring
   (truename (merge-pathnames ".stumpwm.d/" (user-homedir-pathname))))
  "The root directory of StumpWM configuration.")

(defun safe-load (filename)
  "Load FILENAME from config directory, showing errors if it fails."
  (let ((file (merge-pathnames filename *stumpwm-config-dir*)))
    (if (probe-file file)
        (handler-case
            (progn
              (message (format nil "Loading ~A..." filename))
              (load file)
              (message (format nil "✓ ~A" filename)))
          (error (e)
            (message (format nil "^1✗ ~A: ~A^n" filename e))))
        (message (format nil "⚠ Not found: ~A" filename)))))

;;;; ===========================================================================
;;;; Core StumpWM Settings (formerly desktop/core.lisp)
;;;; ===========================================================================

;; NOTE: Prefix key is set in desktop/keys.lisp (M-DEL) to free up C-t for apps

;; Mouse focus policy
(setf *mouse-focus-policy* :click) ; :click, :ignore, or :sloppy

;; Window border width - :thick fills unused space, hiding size hint gaps
(setf *window-border-style* :thick)  ; :thin, :thick, :tight, or :none
(setf *normal-border-width* 0)
(setf *maxsize-border-width* 0)
(setf *transient-border-width* 0)

;; Remove gaps and frame borders
(setf *head-border-width* 0)
(setf *internal-border-width* 0)
(setf *frame-outline-width* 0)

;; Remove mode line padding
(setf *mode-line-pad-x* 0)
(setf *mode-line-pad-y* 0)

;; Disable frame indicator
(setf *frame-indicator-timer* 0)
(setf *frame-indicator-text* "")

;; Message window settings
(setf *message-window-gravity* :top-right)
(setf *message-window-padding* 10)
(setf *timeout-wait* 5) ; seconds to show messages

;; Input window settings
(setf *input-window-gravity* :center)

;; Suppress startup message
(setf *startup-message* nil)

;; Start in a specific group (workspace)
(setf *default-group-name* "main")

;; New window placement
(setf *new-window-preferred-frame* '(:focused))

;; Window gravity (for floating windows)
(setf *window-gravity* :center)

;; Window list format
(setf *window-format* "%m%n%s%c")

;; Window name format in mode line
(setf *window-name-source* :title) ; :title or :class

;; Mode line format
;; %n = group name, %W = window list, %D = Dropbox, %I = wifi, %C = CPU, %M = mem, %B = battery, %d = date/time
;; Note: Formatters are loaded below
(setf *screen-mode-line-format*
      (list "[^B%n^b] %W^>%D | %I | %C | %M | %B | %d"))

;;;; ===========================================================================
;;;; Window Size Hint Fix - Constrain Frames to Emacs
;;;; ===========================================================================

;; Set all backgrounds to black to hide any gaps
(set-win-bg-color "black")
(set-unfocus-color "black")

;; Set root window background to black
(let* ((screen (current-screen))
       (root (screen-root screen))
       (colormap (xlib:screen-default-colormap (screen-number screen)))
       (black (xlib:alloc-color colormap (xlib:make-color :red 0.0 :green 0.0 :blue 0.0))))
  (setf (xlib:window-background root) black)
  (xlib:clear-area root))

;; Constrain frames to match Emacs dimensions (fixes size hint gaps)
(defun constrain-frames-to-emacs ()
  "Resize all frames to match Emacs window dimensions"
  (let ((emacs-win (find-if (lambda (w) (string= (window-class w) "Emacs"))
                            (screen-windows (current-screen)))))
    (when emacs-win
      (let ((target-width (window-width emacs-win))
            (target-height (window-height emacs-win)))
        ;; Resize all frames to match Emacs
        (dolist (group (screen-groups (current-screen)))
          (dolist (frame (stumpwm::group-frames group))
            (setf (frame-width frame) target-width
                  (frame-height frame) target-height)
            (stumpwm::sync-frame-windows group frame)))))))

;; Copy Emacs size hints to all windows (makes all windows align)
(defun copy-emacs-size-hints (window)
  "Copy Emacs's size increment hints to other windows"
  (unless (string= (window-class window) "Emacs")
    (let ((emacs-win (find-if (lambda (w) (string= (window-class w) "Emacs"))
                              (screen-windows (current-screen)))))
      (when emacs-win
        (let* ((emacs-hints (xlib:wm-normal-hints (window-xwin emacs-win)))
               (xwin (window-xwin window))
               (hints (xlib:wm-normal-hints xwin)))
          (when (and emacs-hints hints)
            ;; Copy Emacs's size increment hints to this window
            (setf (xlib:wm-size-hints-width-inc hints)
                  (xlib:wm-size-hints-width-inc emacs-hints)
                  (xlib:wm-size-hints-height-inc hints)
                  (xlib:wm-size-hints-height-inc emacs-hints)
                  (xlib:wm-size-hints-base-width hints)
                  (xlib:wm-size-hints-base-width emacs-hints)
                  (xlib:wm-size-hints-base-height hints)
                  (xlib:wm-size-hints-base-height emacs-hints))
            (setf (xlib:wm-normal-hints xwin) hints)))))))

;; Auto-run hooks
(add-hook *new-window-hook*
          (lambda (window)
            ;; Copy Emacs size hints to non-Emacs windows
            (copy-emacs-size-hints window)
            ;; Constrain frames when Emacs launches
            (when (string= (window-class window) "Emacs")
              (constrain-frames-to-emacs))))

;;;; ===========================================================================
;;;; Load Configuration Files
;;;; ===========================================================================

(message "^B^7Loading StumpWM Configuration...^n")

;; Core utilities and settings
(safe-load "lib/utils.lisp")
(safe-load "desktop/theme.lisp")
(safe-load "desktop/formatters.lisp")

;; Enable mode line on all screens (after formatters are loaded)
(enable-mode-line (current-screen) (current-head) t)

;; Commands and keybindings (M-DEL prefix, M-e/M-f/M-t/M-o launchers)
(safe-load "desktop/keys.lisp")

;; Start clipboard history manager
(handler-case
    (progn
      (clipboard-history:start-clipboard-manager)
      (message "^2✓ Clipboard history started^n"))
  (error (e)
    (message (format nil "^1✗ Clipboard history error: ~A^n" e))))

;;;; ===========================================================================
;;;; Completion Message
;;;; ===========================================================================

(message "^B^2Configuration Complete!^n")
(message "Prefix: M-DEL (Option+Backspace)")
(message "Apps: M-e (Emacs) | M-f (Firefox) | M-t (Kitty)")
(message "Windows: M-o (other) | M-- (hsplit) | M-| (vsplit) | M-0 (only)")
(message "Winner: M-[ (undo) | M-] (redo) | Clipboard: M-DEL C-y")
(message "Help: M-DEL ?")

;;; init.lisp ends here
