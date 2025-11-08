;; StumpWM Configuration - Simplified

;; Set prefix key to C-t (like screen/tmux)
(set-prefix-key (kbd "C-t"))

;; Remove gaps and padding - SET THESE FIRST
(setf *window-border-style* :none)  ; No window borders
(setf *maxsize-border-width* 0)
(setf *normal-border-width* 0)
(setf *transient-border-width* 0)

;; Remove head gaps (space around screen edges)
(setf *head-border-width* 0)

;; Remove mode line padding
(setf *mode-line-pad-x* 0)
(setf *mode-line-pad-y* 0)

;; Disable frame indicator (removes focus highlighting bars)
(setf *frame-indicator-timer* 0)
(setf *frame-indicator-text* "")

;; Remove frame outline width (the actual bars around frames)
(setf *frame-outline-width* 0)

;; Internal border width (space inside window frames)
(setf *internal-border-width* 0)

;; Set focus/unfocus colors to black (match background)
(set-focus-color "black")
(set-unfocus-color "black")

;; Basic appearance settings
(set-fg-color "white")
(set-bg-color "black")
(set-border-color "black")

;; Mode line (status bar)
(setf *screen-mode-line-format*
      (list "[%n] %W^>%d"))

;; Show mode line on startup
(enable-mode-line (current-screen) (current-head) t)

;; Window management settings
(setf *message-window-gravity* :center)
(setf *input-window-gravity* :center)

;; Define basic commands
(defcommand firefox () ()
  "Run or raise Firefox"
  (run-or-raise "firefox" '(:class "Firefox")))

(defcommand terminal () ()
  "Launch terminal"
  (run-shell-command "gnome-terminal"))

;; Key bindings - use C-t then the key
(define-key *root-map* (kbd "c") "terminal")
(define-key *root-map* (kbd "f") "firefox")

;; Welcome message
(message "StumpWM loaded successfully!")
