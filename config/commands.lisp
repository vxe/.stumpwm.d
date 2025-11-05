;;;; config/commands.lisp --- Custom StumpWM Commands
;;;;
;;;; User-defined commands for window management and system control.
;;;;

(in-package :stumpwm)

;;;; ===========================================================================
;;;; Window Management Commands
;;;; ===========================================================================

(defcommand hsplit-and-focus () ()
  "Split the current frame horizontally and focus the new frame."
  (hsplit)
  (move-focus :right))

(defcommand vsplit-and-focus () ()
  "Split the current frame vertically and focus the new frame."
  (vsplit)
  (move-focus :down))

(defcommand kill-window-and-rebalance () ()
  "Kill the current window and rebalance frames."
  (delete-window)
  (balance-frames))

;;;; ===========================================================================
;;;; Quick Application Launchers
;;;; ===========================================================================

(defcommand terminal () ()
  "Launch a terminal emulator."
  (run-or-raise "alacritty" '(:class "Alacritty"))
  ;; Fallback to other terminals if alacritty not found
  (when (not (window-class-match-p (current-window) "Alacritty"))
    (run-or-raise "xterm" '(:class "XTerm"))))

(defcommand browser () ()
  "Launch a web browser."
  (run-or-raise "firefox" '(:class "Firefox")))

(defcommand emacs () ()
  "Launch or raise Emacs."
  (run-or-raise "emacs" '(:class "Emacs")))

(defcommand file-manager () ()
  "Launch a file manager."
  (run-shell-command "pcmanfm &"))

;;;; ===========================================================================
;;;; Workspace (Group) Commands
;;;; ===========================================================================

(defcommand gswap-next () ()
  "Swap current group with next group."
  (let ((current (current-group))
        (next (next-group current (sort-groups (current-screen)))))
    (when next
      (switch-to-group next))))

(defcommand gswap-prev () ()
  "Swap current group with previous group."
  (let ((current (current-group))
        (prev (prev-group current (sort-groups (current-screen)))))
    (when prev
      (switch-to-group prev))))

(defcommand gmove-window-and-follow (to-group) ((:group "Move to group: "))
  "Move the current window to another group and follow it."
  (when to-group
    (move-window-to-group (current-window) to-group)
    (switch-to-group to-group)))

;;;; ===========================================================================
;;;; System Commands
;;;; ===========================================================================

(defcommand lock-screen () ()
  "Lock the screen."
  (run-shell-command "xlock"))

(defcommand suspend () ()
  "Suspend the system."
  (run-shell-command "systemctl suspend"))

(defcommand shutdown-prompt () ()
  "Prompt for system shutdown."
  (let ((choice (prompt "Really shutdown? (y/n): ")))
    (when (string-equal choice "y")
      (run-shell-command "systemctl poweroff"))))

(defcommand reboot-prompt () ()
  "Prompt for system reboot."
  (let ((choice (prompt "Really reboot? (y/n): ")))
    (when (string-equal choice "y")
      (run-shell-command "systemctl reboot"))))

;;;; ===========================================================================
;;;; Screenshot Commands
;;;; ===========================================================================

(defcommand screenshot-full () ()
  "Take a full screenshot."
  (run-shell-command "scrot ~/Pictures/screenshot_%Y%m%d_%H%M%S.png"))

(defcommand screenshot-window () ()
  "Take a screenshot of the focused window."
  (run-shell-command "scrot -u ~/Pictures/screenshot_%Y%m%d_%H%M%S.png"))

(defcommand screenshot-select () ()
  "Take a screenshot of a selected area."
  (run-shell-command "scrot -s ~/Pictures/screenshot_%Y%m%d_%H%M%S.png"))

;;;; ===========================================================================
;;;; Info Commands
;;;; ===========================================================================

(defcommand show-window-info () ()
  "Show detailed information about the current window."
  (let ((win (current-window)))
    (if win
        (message (format nil
                        "Window Info:~%Class: ~A~%Title: ~A~%Type: ~A~%Group: ~A"
                        (window-class win)
                        (window-title win)
                        (window-type win)
                        (group-name (window-group win))))
        (message "No window selected"))))

(defcommand show-group-info () ()
  "Show information about all groups."
  (let* ((screen (current-screen))
         (groups (screen-groups screen))
         (info (format nil "Groups:~%~{  ~A~^~%~}"
                      (mapcar (lambda (g)
                               (format nil "~A ~A"
                                      (if (eq g (current-group))
                                          "*"
                                          " ")
                                      (group-name g)))
                             groups))))
    (message info)))

;;;; ===========================================================================
;;;; Reload/Restart Commands
;;;; ===========================================================================

(defcommand reload-config () ()
  "Reload StumpWM configuration."
  (run-commands "reload")
  (message "Configuration reloaded"))

(defcommand restart-wm () ()
  "Restart StumpWM."
  (run-commands "restart"))

;;;; ===========================================================================
;;;; Help Commands
;;;; ===========================================================================

(defcommand show-keybindings () ()
  "Show all keybindings."
  (run-commands "describe-key"))

(defcommand claude-help () ()
  "Show Claude integration help."
  (message "Claude Integration:~%~
            Super+Space - Ask Claude~%~
            Super+Ctrl+S - Start Swank server~%~
            Super+? - Show this help"))

;;; commands.lisp ends here
