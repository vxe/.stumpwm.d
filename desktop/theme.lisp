;;;; desktop/theme.lisp --- Visual Theme Configuration
;;;;
;;;; Colors, fonts, and visual appearance for StumpWM.
;;;;

(in-package :stumpwm-user)

;;;; ===========================================================================
;;;; Color Scheme
;;;; ===========================================================================

;; Base16 inspired color palette
(defparameter *theme-colors*
  '(:bg0     "#1d2021"  ; Dark background
    :bg1     "#282828"  ; Background
    :bg2     "#3c3836"  ; Lighter background
    :fg0     "#fbf1c7"  ; Foreground
    :fg1     "#ebdbb2"  ; Slightly dimmer foreground
    :red     "#fb4934"  ; Red (errors, urgent)
    :green   "#b8bb26"  ; Green (success)
    :yellow  "#fabd2f"  ; Yellow (warnings)
    :blue    "#83a598"  ; Blue (info)
    :purple  "#d3869b"  ; Purple (special)
    :cyan    "#8ec07c"  ; Cyan (links)
    :orange  "#fe8019"  ; Orange (accent)
    :gray    "#928374") ; Gray (comments)
  "Color palette for the desktop theme.")

(defun theme-color (name)
  "Get a color from the theme palette."
  (getf *theme-colors* name))

;;;; ===========================================================================
;;;; Font Configuration
;;;; ===========================================================================

;; Try to load a nice monospace font
;; StumpWM supports X11 font names and some modern font formats
(let ((preferred-fonts
       '("DejaVu Sans Mono-10"
         "Terminus-12"
         "Monospace-10"
         "fixed")))
  (loop for font in preferred-fonts
        do (handler-case
               (progn
                 (set-font font)
                 (message (format nil "Using font: ~A" font))
                 (return))
             (error ()
               (message (format nil "Font ~A not available, trying next..." font))))))

;;;; ===========================================================================
;;;; Window Colors
;;;; ===========================================================================

;; Focused window border
(set-focus-color "black")

;; Unfocused window border
(set-unfocus-color "black")

;; Floating window border
(set-float-focus-color (theme-color :purple))
(set-float-unfocus-color (theme-color :bg2))

;;;; ===========================================================================
;;;; Message Window Colors
;;;; ===========================================================================

(set-fg-color (theme-color :fg1))
(set-bg-color (theme-color :bg1))
(set-border-color "black")

;;;; ===========================================================================
;;;; Mode Line Colors
;;;; ===========================================================================

(setf *mode-line-foreground-color* (theme-color :fg1))
(setf *mode-line-background-color* (theme-color :bg1))
(setf *mode-line-border-color* (theme-color :bg2))

;; Highlight color for current workspace in mode line
(setf *mode-line-highlight-color* (theme-color :blue))

;;;; ===========================================================================
;;;; Frame Indicator (for split frames)
;;;; ===========================================================================

;; Frame indicator settings are in core.lisp
;; (setf *frame-indicator-text* " %s "
;;       *frame-indicator-color* (theme-color :blue))

;;;; ===========================================================================
;;;; Color Formatter for Messages
;;;; ===========================================================================

;; Define color codes for use in messages
;; Usage: (message "^B^2Success!^n") for bold green text

(defparameter *color-map*
  `((0 . ,(theme-color :fg1))    ; Normal text
    (1 . ,(theme-color :red))    ; Red
    (2 . ,(theme-color :green))  ; Green
    (3 . ,(theme-color :yellow)) ; Yellow
    (4 . ,(theme-color :blue))   ; Blue
    (5 . ,(theme-color :purple)) ; Purple
    (6 . ,(theme-color :cyan))   ; Cyan
    (7 . ,(theme-color :orange)) ; Orange
    (8 . ,(theme-color :gray)))  ; Gray
  "Color map for formatted messages.")

;;;; ===========================================================================
;;;; Theme Utility Functions
;;;; ===========================================================================

(defun theme-reload ()
  "Reload the theme configuration."
  (load-config-file "config/theme.lisp")
  (message "Theme reloaded"))

(defun theme-dark ()
  "Switch to dark theme (already the default)."
  (message "Dark theme active"))

(defun theme-light ()
  "Switch to light theme."
  ;; Swap foreground and background colors
  (set-fg-color (theme-color :bg1))
  (set-bg-color (theme-color :fg1))
  (message "Light theme active"))

;;;; ===========================================================================
;;;; ASCII Art / Banner (Optional)
;;;; ===========================================================================

(defparameter *claude-banner*
  "
   ╔═══════════════════════════════════════════╗
   ║  Claude + StumpWM Integration             ║
   ║  Lisp Desktop Environment                 ║
   ╚═══════════════════════════════════════════╝
  "
  "ASCII banner for Claude integration.")

;;; theme.lisp ends here
