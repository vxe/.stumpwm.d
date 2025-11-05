;;;; config/keybindings.lisp --- Keybinding Configuration
;;;;
;;;; All keybindings for the Claude-integrated desktop environment.
;;;;

(in-package :stumpwm)

;;;; ===========================================================================
;;;; Modifier Key Setup
;;;; ===========================================================================

;; Define commonly used modifier combinations
;; s = Super (Windows key)
;; C = Control
;; M = Meta (Alt)
;; S = Shift

;;;; ===========================================================================
;;;; Top-Level Bindings (no prefix key required)
;;;; ===========================================================================

;; Claude Integration - The star of the show!
(define-key *top-map* (kbd "s-SPC") "claude-ask")
(define-key *top-map* (kbd "s-C-SPC") "claude-eval-region")

;; Swank/Development
(define-key *top-map* (kbd "s-C-s") "swank-toggle")

;; Quick application launchers
(define-key *top-map* (kbd "s-RET") "terminal")
(define-key *top-map* (kbd "s-e") "emacs")
(define-key *top-map* (kbd "s-b") "browser")
(define-key *top-map* (kbd "s-f") "file-manager")

;; Window focus movement
(define-key *top-map* (kbd "s-h") "move-focus left")
(define-key *top-map* (kbd "s-j") "move-focus down")
(define-key *top-map* (kbd "s-k") "move-focus up")
(define-key *top-map* (kbd "s-l") "move-focus right")

;; Window movement
(define-key *top-map* (kbd "s-S-h") "move-window left")
(define-key *top-map* (kbd "s-S-j") "move-window down")
(define-key *top-map* (kbd "s-S-k") "move-window up")
(define-key *top-map* (kbd "s-S-l") "move-window right")

;; Frame splitting
(define-key *top-map* (kbd "s-v") "vsplit-and-focus")
(define-key *top-map* (kbd "s-s") "hsplit-and-focus")

;; Window management
(define-key *top-map* (kbd "s-q") "delete-window")
(define-key *top-map* (kbd "s-Q") "kill-window-and-rebalance")
(define-key *top-map* (kbd "s-o") "fnext")
(define-key *top-map* (kbd "s-TAB") "other-window")

;; Workspace (group) switching - Number keys
(define-key *top-map* (kbd "s-1") "gselect 1")
(define-key *top-map* (kbd "s-2") "gselect 2")
(define-key *top-map* (kbd "s-3") "gselect 3")
(define-key *top-map* (kbd "s-4") "gselect 4")
(define-key *top-map* (kbd "s-5") "gselect 5")

;; Named workspace selection
(define-key *top-map* (kbd "s-m") "gselect main")
(define-key *top-map* (kbd "s-d") "gselect dev")
(define-key *top-map* (kbd "s-w") "gselect web")
(define-key *top-map* (kbd "s-c") "gselect comms")

;; Move window to workspace
(define-key *top-map* (kbd "s-S-1") "gmove 1")
(define-key *top-map* (kbd "s-S-2") "gmove 2")
(define-key *top-map* (kbd "s-S-3") "gmove 3")
(define-key *top-map* (kbd "s-S-4") "gmove 4")
(define-key *top-map* (kbd "s-S-5") "gmove 5")

;; Workspace navigation
(define-key *top-map* (kbd "s-n") "gnext")
(define-key *top-map* (kbd "s-p") "gprev")
(define-key *top-map* (kbd "s-N") "gnext-with-window")
(define-key *top-map* (kbd "s-P") "gprev-with-window")

;; Frame management
(define-key *top-map* (kbd "s-r") "remove-split")
(define-key *top-map* (kbd "s-R") "only")
(define-key *top-map* (kbd "s-=") "balance-frames")

;; Fullscreen
(define-key *top-map* (kbd "s-F") "fullscreen")

;; Help and info
(define-key *top-map* (kbd "s-?") "claude-help")
(define-key *top-map* (kbd "s-i") "show-window-info")

;; System controls
(define-key *top-map* (kbd "s-x") "colon")  ; Command prompt
(define-key *top-map* (kbd "s-L") "lock-screen")

;;;; ===========================================================================
;;;; Prefix Key Bindings (C-t prefix)
;;;; ===========================================================================

;; The traditional StumpWM prefix key (C-t) still works for compatibility

;; Help
(define-key *root-map* (kbd "?") "help")
(define-key *root-map* (kbd "h") "help")

;; Window management
(define-key *root-map* (kbd "k") "delete-window")
(define-key *root-map* (kbd "K") "kill-window")
(define-key *root-map* (kbd "TAB") "other")
(define-key *root-map* (kbd "SPC") "pull-hidden-other")

;; Frame splitting (traditional)
(define-key *root-map* (kbd "s") "vsplit")
(define-key *root-map* (kbd "S") "hsplit")
(define-key *root-map* (kbd "r") "remove-split")
(define-key *root-map* (kbd "Q") "only")

;; Frame navigation
(define-key *root-map* (kbd "Left") "move-focus left")
(define-key *root-map* (kbd "Right") "move-focus right")
(define-key *root-map* (kbd "Up") "move-focus up")
(define-key *root-map* (kbd "Down") "move-focus down")

;; Group management
(define-key *root-map* (kbd "g") "grouplist")
(define-key *root-map* (kbd "G") "vgroups")
(define-key *root-map* (kbd "C-g") "gmove-window-and-follow")

;; Applications
(define-key *root-map* (kbd "c") "terminal")
(define-key *root-map* (kbd "e") "emacs")
(define-key *root-map* (kbd "b") "browser")

;; System
(define-key *root-map* (kbd "q") "restart-wm")
(define-key *root-map* (kbd "C-q") "shutdown-prompt")

;; Info
(define-key *root-map* (kbd "i") "show-window-info")
(define-key *root-map* (kbd "I") "show-group-info")

;; Reload
(define-key *root-map* (kbd "C-r") "reload-config")

;; Claude commands
(define-key *root-map* (kbd "a") "claude-ask")
(define-key *root-map* (kbd "A") "claude-context")

;;;; ===========================================================================
;;;; Mouse Bindings
;;;; ===========================================================================

;; Click to focus
(define-button-press-map *mouse-map*
  (list 1) "move-focus-under-mouse")

;; Super+Click to drag window
(define-button-press-map *top-map*
  (list "s-1") "drag-window-under-mouse")

;; Super+Right-click to resize
(define-button-press-map *top-map*
  (list "s-3") "resize-window-under-mouse")

;;;; ===========================================================================
;;;; Screenshot Bindings
;;;; ===========================================================================

(define-key *top-map* (kbd "Print") "screenshot-full")
(define-key *top-map* (kbd "S-Print") "screenshot-select")
(define-key *top-map* (kbd "M-Print") "screenshot-window")

;;;; ===========================================================================
;;;; Media Keys (if available)
;;;; ===========================================================================

;; Volume control
(define-key *top-map* (kbd "XF86AudioRaiseVolume")
  "exec amixer -q set Master 5%+")
(define-key *top-map* (kbd "XF86AudioLowerVolume")
  "exec amixer -q set Master 5%-")
(define-key *top-map* (kbd "XF86AudioMute")
  "exec amixer -q set Master toggle")

;; Brightness control
(define-key *top-map* (kbd "XF86MonBrightnessUp")
  "exec xbacklight -inc 10")
(define-key *top-map* (kbd "XF86MonBrightnessDown")
  "exec xbacklight -dec 10")

;;;; ===========================================================================
;;;; Help Message
;;;; ===========================================================================

(defparameter *keybinding-help*
  "Claude-Integrated StumpWM Keybindings:

CLAUDE:
  Super+Space          Ask Claude anything
  Super+Ctrl+Space     Evaluate selected region with Claude
  Super+Ctrl+S         Toggle Swank server

APPLICATIONS:
  Super+Return         Terminal
  Super+E              Emacs
  Super+B              Browser
  Super+F              File Manager

WINDOWS:
  Super+H/J/K/L        Move focus (Vim-style)
  Super+Shift+H/J/K/L  Move window
  Super+Q              Close window
  Super+Tab            Cycle windows
  Super+F              Fullscreen

FRAMES:
  Super+V              Split vertically
  Super+S              Split horizontally
  Super+=              Balance frames
  Super+R              Remove split
  Super+Shift+R        Remove all splits

WORKSPACES:
  Super+1-5            Switch to workspace
  Super+Shift+1-5      Move window to workspace
  Super+N/P            Next/Previous workspace
  Super+M/D/W/C        Jump to main/dev/web/comms

SYSTEM:
  Super+L              Lock screen
  Super+X              Command prompt
  Super+?              This help
  Super+I              Window info

Press C-t ? for traditional StumpWM help"
  "Quick reference for keybindings.")

(defcommand keybinding-help () ()
  "Show keybinding help."
  (message *keybinding-help*))

;; Override the help command to show our custom help
(define-key *top-map* (kbd "s-?") "keybinding-help")

;;; keybindings.lisp ends here
