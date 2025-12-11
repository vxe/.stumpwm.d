;;;; desktop/keys.lisp --- Commands and Keybindings
;;;;
;;;; All command definitions and their associated keybindings.
;;;; Commands are defined next to their bindings for easier maintenance.
;;;;

(in-package :stumpwm-user)

;;;; ===========================================================================
;;;; Clean Up Ghost Symbols (allows reload with loadrc)
;;;; ===========================================================================

;; Remove any existing command symbols to avoid package conflicts when reloading
;; This allows (loadrc) to work without restarting StumpWM
(dolist (sym '(firefox-unity kitty obs emacs terminal browser file-manager
               swap-window-by-number slynk
               lisp-machine-symbolics lisp-machine-interlisp lisp-machine-mit
               emacs-terminal
               hsplit-and-focus vsplit-and-focus kill-window-and-rebalance
               gswap-next gswap-prev gmove-window-and-follow))
  (let ((symbol (find-symbol (string-upcase (string sym)) :stumpwm-user)))
    (when symbol
      (unintern symbol :stumpwm-user))))

;;;; ===========================================================================
;;;; Prefix Key Configuration
;;;; ===========================================================================

;; Change the prefix key from C-t to M-DEL (Option+Backspace)
;; This frees up C-t for use in applications like Firefox
(stumpwm:set-prefix-key (stumpwm:kbd "M-DEL"))

;;;; ===========================================================================
;;;; Window Management
;;;; ===========================================================================

;; Simple window cycling
;; C-TAB: Cycle through windows (just calls built-in other-window)
;; C-Shift-TAB: Linear scan through all windows

(defcommand cycle-windows-forward () ()
  "Toggle to the last-used window."
  (run-commands "other"))

(defcommand cycle-windows-backward () ()
  "Linear scan: cycle to next window in the window list."
  (run-commands "next"))

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

(defcommand swap-window-by-number (win-num) ((:number "Swap with window: "))
  "Swap the current window with window N."
  (let* ((current-win (current-window))
         (current-frame (stumpwm::window-frame current-win))
         (target-win (find-if (lambda (w) (= (window-number w) win-num))
                              (group-windows (current-group)))))
    (when (and current-win target-win)
      (let ((target-frame (stumpwm::window-frame target-win)))
        ;; Pull target window to current frame
        (stumpwm::pull-window target-win current-frame)
        ;; Pull current window to target frame
        (stumpwm::pull-window current-win target-frame)
        (message (format nil "Swapped window ~A with window ~A"
                        (window-number current-win) win-num))))))

;; Window swapping - swap current window with window N
(define-key *root-map* (kbd "s") "swap-window-by-number")

;; Frame splits - simple bindings (no wrappers needed)
(define-key *root-map* (kbd "2") "vsplit")   ; Vertical split
(define-key *root-map* (kbd "3") "hsplit")   ; Horizontal split
(define-key *root-map* (kbd "0") "only")     ; Maximize current frame (remove all others)

;; Frame splitting
;; (define-key *top-map* (kbd "s-v") "vsplit-and-focus")
;; (define-key *top-map* (kbd "s-s") "hsplit-and-focus")

;; ;; Window management
;; (define-key *top-map* (kbd "s-q") "delete-window")
;; (define-key *top-map* (kbd "s-Q") "kill-window-and-rebalance")
;; (define-key *top-map* (kbd "s-o") "fnext")
;; (define-key *top-map* (kbd "s-TAB") "other-window")

;; ;; Window focus movement
;; (define-key *top-map* (kbd "s-h") "move-focus left")
;; (define-key *top-map* (kbd "s-j") "move-focus down")
;; (define-key *top-map* (kbd "s-k") "move-focus up")
;; (define-key *top-map* (kbd "s-l") "move-focus right")

;; ;; Window movement
;; (define-key *top-map* (kbd "s-S-h") "move-window left")
;; (define-key *top-map* (kbd "s-S-j") "move-window down")
;; (define-key *top-map* (kbd "s-S-k") "move-window up")
;; (define-key *top-map* (kbd "s-S-l") "move-window right")

;; ;; Frame management
;; (define-key *top-map* (kbd "s-r") "remove-split")
;; (define-key *top-map* (kbd "s-R") "only")
;; (define-key *top-map* (kbd "s-=") "balance-frames")

;; ;; Fullscreen
;; (define-key *top-map* (kbd "s-F") "fullscreen")

;;;; ===========================================================================
;;;; Application Launchers
;;;; ===========================================================================

(defcommand terminal () ()
  "Launch a terminal emulator."
  (run-or-raise "alacritty" '(:class "Alacritty"))
  ;; Fallback to other terminals if alacritty not found
  (when (not (window-class-match-p (current-window) "Alacritty"))
    (run-or-raise "xterm" '(:class "XTerm"))))

(defcommand browser () ()
  "Launch a web browser."
  (run-or-raise "firefox" '(:class "firefox_firefox")))

(defcommand firefox-unity () ()
  "Launch Firefox web browser."
  (run-or-raise "firefox" '(:class "firefox_firefox")))

(defcommand emacs () ()
  "Launch or raise Emacs."
  (run-or-raise "emacs" '(:class "Emacs")))

(defcommand kitty () ()
  "Launch or raise Kitty terminal."
  (run-or-raise "kitty" '(:class "kitty")))

(defcommand obs () ()
  "Launch or raise OBS Studio."
  (run-or-raise "obs" '(:class "obs")))

(defcommand file-manager () ()
  "Launch a file manager."
  (run-shell-command "pcmanfm &"))

;; Super key launchers
(define-key *top-map* (kbd "s-RET") "terminal")
(define-key *top-map* (kbd "M-e") "emacs")
(define-key *top-map* (kbd "M-b") "obs")              ; OBS Studio
;; (define-key *top-map* (kbd "s-b") "browser")
(define-key *top-map* (kbd "M-f") "firefox-unity")
(define-key *top-map* (kbd "M-t") "kitty")

;; Window cycling (Control+Tab / Control+Shift+Tab)
(define-key *top-map* (kbd "C-TAB") "cycle-windows-forward")
(define-key *top-map* (kbd "C-ISO_Left_Tab") "cycle-windows-backward")

;; Window/frame operations
(define-key *top-map* (kbd "M-o") "fother")          ; Switch focus to other frame (other window)
(define-key *top-map* (kbd "M-minus") "hsplit")      ; Horizontal split
(define-key *top-map* (kbd "M-bar") "vsplit")        ; Vertical split
(define-key *top-map* (kbd "M-0") "only")            ; Maximize current frame (delete all others)




;;;; ===========================================================================
;;;; Slynk Server Command
;;;; ===========================================================================

(defcommand slynk () ()
  "Start Slynk server on port 4005 for SLY connection"
  (handler-case
      (progn
        (ql:quickload :slynk :silent t)
        (sb-thread:make-thread
         (lambda ()
           (funcall (intern "CREATE-SERVER" :slynk) :port 4005 :dont-close t))
         :name "slynk-server")
        (message "^2Slynk server started on port 4005^n")
        (message "Connect: M-x sly-connect RET localhost RET 4005 RET"))
    (error (e)
      (message (format nil "^1Slynk error: ~A^n" e)))))

;;;; ===========================================================================
;;;; Lisp Machine Layouts
;;;; ===========================================================================

(defcommand lisp-machine-symbolics () ()
  "Create a Symbolics-style Lisp Machine layout: Large top editor, two bottom panes"
  (only)  ; Start clean
  (vsplit)  ; Split vertically (top/bottom)
  (move-focus :down)  ; Focus bottom
  (hsplit)  ; Split bottom horizontally
  (move-focus :up)  ; Back to top
  (resize-frame (current-group) (tile-group-current-frame (current-group)) 0 -200)  ; Make top bigger
  (run-or-raise "emacs" '(:class "Emacs"))
  (message "Symbolics layout ready! Top: Editor, Bottom-left: Docs, Bottom-right: Shell"))

(defcommand lisp-machine-interlisp () ()
  "Create an Interlisp-D style layout: Left editor (2/3), right split for REPL and monitor"
  (only)
  (hsplit)  ; Split horizontally
  (move-focus :right)
  (vsplit)  ; Split right side vertically
  (move-focus :left)
  (resize-frame (current-group) (tile-group-current-frame (current-group)) 600 0)  ; Make left wider
  (run-or-raise "emacs" '(:class "Emacs"))
  (message "Interlisp-D layout ready! Left: Editor, Top-right: REPL, Bottom-right: Monitor"))

(defcommand lisp-machine-mit () ()
  "Create an MIT Lisp Machine layout: Top 70% editor, bottom two listeners"
  (only)
  (vsplit)  ; Split vertically
  (move-focus :down)
  (hsplit)  ; Split bottom horizontally
  (move-focus :up)
  (resize-frame (current-group) (tile-group-current-frame (current-group)) 0 -300)  ; Make top bigger
  (run-or-raise "emacs" '(:class "Emacs"))
  (message "MIT Lisp Machine layout ready! Top: Editor, Bottom: Two listeners"))

(defcommand emacs-terminal () ()
  "Simple layout: Top 2/3 Emacs, bottom 1/3 Kitty terminal"
  (only)
  (vsplit)  ; Split vertically (top/bottom)
  (move-focus :down)  ; Focus bottom frame
  ;; Resize bottom frame up by -400 pixels (making bottom smaller, top bigger)
  (resize 0 -400)
  (run-or-raise "kitty" '(:class "kitty"))
  (move-focus :up)
  (run-or-raise "emacs" '(:class "Emacs"))
  (message "Layout ready: Top 2/3 Emacs, Bottom 1/3 Kitty"))

;; No keybindings - call by name with M-DEL : lisp-machine-symbolics etc.

;;;; ===========================================================================
;;;; Workspace (Group) Management
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

;; Workspace switching - Number keys
;; (define-key *top-map* (kbd "s-1") "gselect 1")
;; (define-key *top-map* (kbd "s-2") "gselect 2")
;; (define-key *top-map* (kbd "s-3") "gselect 3")
;; (define-key *top-map* (kbd "s-4") "gselect 4")
;; (define-key *top-map* (kbd "s-5") "gselect 5")

;; Named workspace selection
;; (define-key *top-map* (kbd "s-m") "gselect main")
;; (define-key *top-map* (kbd "s-d") "gselect dev")
;; (define-key *top-map* (kbd "s-w") "gselect web")
;; (define-key *top-map* (kbd "s-c") "gselect comms")

;; Move window to workspace
;; (define-key *top-map* (kbd "s-S-1") "gmove 1")
;; (define-key *top-map* (kbd "s-S-2") "gmove 2")
;; (define-key *top-map* (kbd "s-S-3") "gmove 3")
;; (define-key *top-map* (kbd "s-S-4") "gmove 4")
;; (define-key *top-map* (kbd "s-S-5") "gmove 5")

;; Workspace navigation
;; (define-key *top-map* (kbd "s-n") "gnext")
;; (define-key *top-map* (kbd "s-p") "gprev")
;; (define-key *top-map* (kbd "s-N") "gnext-with-window")
;; (define-key *top-map* (kbd "s-P") "gprev-with-window")

;;;; ===========================================================================
;;;; System Commands
;;;; ===========================================================================

;; (defcommand lock-screen () ()
;;   "Lock the screen."
;;   (run-shell-command "xlock"))

;; (defcommand suspend () ()
;;   "Suspend the system."
;;   (run-shell-command "systemctl suspend"))

;; (defcommand shutdown-prompt () ()
;;   "Prompt for system shutdown."
;;   (let ((choice (prompt "Really shutdown? (y/n): ")))
;;     (when (string-equal choice "y")
;;       (run-shell-command "systemctl poweroff"))))

;; (defcommand reboot-prompt () ()
;;   "Prompt for system reboot."
;;   (let ((choice (prompt "Really reboot? (y/n): ")))
;;     (when (string-equal choice "y")
;;       (run-shell-command "systemctl reboot"))))

;; System controls
;; (define-key *top-map* (kbd "s-x") "colon")  ; Command prompt
;; (define-key *top-map* (kbd "s-L") "lock-screen")

;;;; ===========================================================================
;;;; Screenshot Commands
;;;; ===========================================================================

;; (defcommand screenshot-full () ()
;;   "Take a full screenshot."
;;   (run-shell-command "scrot ~/Pictures/screenshot_%Y%m%d_%H%M%S.png"))

;; (defcommand screenshot-window () ()
;;   "Take a screenshot of the focused window."
;;   (run-shell-command "scrot -u ~/Pictures/screenshot_%Y%m%d_%H%M%S.png"))

;; (defcommand screenshot-select () ()
;;   "Take a screenshot of a selected area."
;;   (run-shell-command "scrot -s ~/Pictures/screenshot_%Y%m%d_%H%M%S.png"))

;; (define-key *top-map* (kbd "Print") "screenshot-full")
;; (define-key *top-map* (kbd "S-Print") "screenshot-select")
;; (define-key *top-map* (kbd "M-Print") "screenshot-window")

;;;; ===========================================================================
;;;; Info Commands
;;;; ===========================================================================

;; (defcommand show-window-info () ()
;;   "Show detailed information about the current window."
;;   (let ((win (current-window)))
;;     (if win
;;         (message (format nil
;;                         "Window Info:~%Class: ~A~%Title: ~A~%Type: ~A~%Group: ~A"
;;                         (window-class win)
;;                         (window-title win)
;;                         (window-type win)
;;                         (group-name (window-group win))))
;;         (message "No window selected"))))

;; (defcommand show-group-info () ()
;;   "Show information about all groups."
;;   (let* ((screen (current-screen))
;;          (groups (screen-groups screen))
;;          (info (format nil "Groups:~%~{  ~A~^~%~}"
;;                       (mapcar (lambda (g)
;;                                (format nil "~A ~A"
;;                                       (if (eq g (current-group))
;;                                           "*"
;;                                           " ")
;;                                       (group-name g)))

;;                              groups))))
;;     (message info)))

;; (defcommand keybinding-help () ()
;;   "Show keybinding help."
;;   (message "Claude-Integrated StumpWM Keybindings:

;; CLAUDE:
;;   Super+Space          Ask Claude anything
;;   Super+Ctrl+Space     Evaluate selected region with Claude
;;   Super+Ctrl+S         Toggle Swank server

;; APPLICATIONS:
;;   Option+E / Super+E   Emacs
;;   Option+F             Firefox
;;   Option+T             Kitty terminal
;;   Option+O             OBS
;;   Super+Return         Terminal
;;   Super+B              Browser
;;   Super+F              File Manager

;; WINDOWS:
;;   Super+H/J/K/L        Move focus (Vim-style)
;;   Super+Shift+H/J/K/L  Move window
;;   Super+Q              Close window
;;   Super+Tab            Cycle windows
;;   Super+F              Fullscreen

;; FRAMES:
;;   Super+V              Split vertically
;;   Super+S              Split horizontally
;;   Super+=              Balance frames
;;   Super+R              Remove split
;;   Super+Shift+R        Remove all splits

;; WORKSPACES:
;;   Super+1-5            Switch to workspace
;;   Super+Shift+1-5      Move window to workspace
;;   Super+N/P            Next/Previous workspace
;;   Super+M/D/W/C        Jump to main/dev/web/comms

;; SYSTEM:
;;   Super+L              Lock screen
;;   Super+X              Command prompt
;;   Super+?              This help
;;   Super+I              Window info

;; Press Option+Backspace ? for traditional StumpWM help"))

;; (defcommand claude-help () ()
;;   "Show Claude integration help."
;;   (message "Claude Integration:~%~
;;             Super+Space - Ask Claude~%~
;;             Super+Ctrl+S - Start Swank server~%~
;;             Super+? - Show this help"))

;; ;; Help and info
;; (define-key *top-map* (kbd "s-?") "keybinding-help")
;; (define-key *top-map* (kbd "s-i") "show-window-info")

;;;; ===========================================================================
;;;; Reload/Restart Commands
;;;; ===========================================================================

;; (defcommand reload-config () ()
;;   "Reload StumpWM configuration."
;;   (run-commands "reload")
;;   (message "Configuration reloaded"))

;; (defcommand restart-wm () ()
;;   "Restart StumpWM."
;;   (run-commands "restart"))

;;;; ===========================================================================
;;;; Additional Custom Bindings
;;;; ===========================================================================
;;;; NOTE: We do NOT override *root-map* bindings here!
;;;; The prefix key (M-DEL) gives you access to all default StumpWM commands.
;;;; We only add NEW bindings below for quick access.

;;;; ===========================================================================
;;;; Mouse Bindings
;;;; ===========================================================================

;; Click to focus
;; NOTE: Commented out - *mouse-map* not available in all StumpWM builds
;; (define-button-press-map *mouse-map*
;;   (list 1) "move-focus-under-mouse")

;; Super+Click to drag window
;; (define-button-press-map *top-map*
;;   (list "s-1") "drag-window-under-mouse")

;; Super+Right-click to resize
;; (define-button-press-map *top-map*
;;   (list "s-3") "resize-window-under-mouse")

;;;; ===========================================================================
;;;; Clipboard History
;;;; ===========================================================================

;; Show clipboard history menu
(define-key *root-map* (kbd "C-y") "show-clipboard-history")

;;;; ===========================================================================
;;;; Winner Mode - Undo/Redo Frame Layouts
;;;; ===========================================================================

;; Winner mode keybindings (undo/redo frame changes)
(define-key *root-map* (kbd "u") "winner-undo")
(define-key *root-map* (kbd "C-r") "winner-redo")
(define-key *top-map* (kbd "M-bracketleft") "winner-undo")
(define-key *top-map* (kbd "M-bracketright") "winner-redo")

;; NOTE: Winner-mode hook is in init.lisp (don't duplicate it here!)

;;;; ===========================================================================
;;;; Media Keys
;;;; ===========================================================================

;; Volume control
;; Media keys (for keyboards with physical F-keys)
(define-key *top-map* (kbd "XF86AudioRaiseVolume")
  "exec amixer -q set Master 5%+")
(define-key *top-map* (kbd "XF86AudioLowerVolume")
  "exec amixer -q set Master 5%-")
(define-key *top-map* (kbd "XF86AudioMute")
  "exec amixer -q set Master toggle")

;; Alternative bindings for Touch Bar MacBooks (no physical F-keys)
(define-key *top-map* (kbd "M-=")
  "exec amixer -q set Master 5%+")
(define-key *top-map* (kbd "M--")
  "exec amixer -q set Master 5%-")
(define-key *top-map* (kbd "M-0")
  "exec amixer -q set Master toggle")

;; Brightness control
(define-key *top-map* (kbd "XF86MonBrightnessUp")
  "exec xbacklight -inc 10")
(define-key *top-map* (kbd "XF86MonBrightnessDown")
  "exec xbacklight -dec 10")

;;; keys.lisp ends here
