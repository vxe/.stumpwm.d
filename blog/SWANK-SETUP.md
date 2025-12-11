# Swank/SLY Setup for StumpWM

## What is Swank?
Swank is a REPL server that lets you connect Emacs to your running StumpWM instance. This gives you:
- Live coding: Edit StumpWM functions in Emacs and test immediately
- Debugging: Inspect running window manager state
- Interactive development: No need to restart X11 to test changes

Note: It's "Swank" not "Slynk" - Swank is the Common Lisp backend for SLY/SLIME.

## Installation

### 1. Install Swank via Quicklisp

```bash
sbcl
```

In the SBCL REPL:
```lisp
(ql:quickload :swank)
(quit)
```

### 2. Reload StumpWM Config

Press: `C-t C-r` or `C-t ; loadrc`

You should see: "✓ Swank module loaded"

## Starting the Swank Server

### Method 1: Keybinding (easiest)
Press: `Super+Ctrl+S` (Windows key + Control + S)

This toggles the server on/off.

### Method 2: Command prompt
1. Press: `C-t ;`
2. Type: `swank-start`
3. Press Enter

### Method 3: Auto-start on boot
Edit `~/.stumpwm.d/desktop/core.lisp`:
```lisp
(defparameter *swank-auto-start* t)  ; Change nil to t
```

Then restart StumpWM or reload config.

## Connecting from Emacs

### Install SLY (if needed)
```elisp
M-x package-install RET sly RET
```

### Connect to StumpWM
```elisp
M-x sly-connect RET localhost RET 4005 RET
```

You should see a REPL buffer connected to StumpWM!

## What You Can Do

### Test commands before adding to config
```lisp
STUMPWM> (message "Hello from Emacs!")
STUMPWM> (current-window)
STUMPWM> (window-title (current-window))
```

### Inspect workspace state
```lisp
STUMPWM> (group-windows (current-group))
STUMPWM> (screen-groups (current-screen))
```

### Define new commands on the fly
```lisp
STUMPWM> (defcommand test () ()
           (message "This is a test command!"))
STUMPWM> (test)
```

### Reload modules without restarting
Edit a file in Emacs, then:
```elisp
C-c C-c  ; Compile current defun
```

The change takes effect immediately in StumpWM!

## Troubleshooting

### "Connection refused"
- Make sure Swank server is running: `C-t ; swank-status`
- Start it if not: `Super+Ctrl+S`

### "Package SWANK does not exist"
- Install Swank: `(ql:quickload :swank)` in SBCL
- Reload StumpWM config: `C-t C-r`

### "Port 4005 already in use"
- Server is already running, just connect from Emacs
- Or restart it: `C-t ; swank-restart`

## Commands

- `:swank-start` - Start the server
- `:swank-stop` - Stop the server
- `:swank-restart` - Restart the server
- `:swank-toggle` - Toggle on/off
- `:swank-status` - Check if running

## Default Settings

- Port: 4005
- Auto-start: disabled (change in `desktop/core.lisp`)
- Keybinding: `Super+Ctrl+S`

## Next Steps

Once connected, try:
1. Inspect your current window: `(current-window)`
2. List all windows: `(get-all-windows)`
3. Send a message: `(message "Testing!")`
4. Create a custom command and test it live
5. Edit StumpWM config files in Emacs and hot-reload changes

Happy hacking!
