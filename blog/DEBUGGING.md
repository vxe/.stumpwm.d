# StumpWM Debugging Guide

## Quick Fix Steps

If you're seeing issues with firefox command or Swank/Slynk connection:

### 1. Reload StumpWM Configuration

Press: **C-t C-r** (Control+t, then Control+r)

This will reload your configuration without restarting X11.

After reloading, you should see debug messages showing:
- Whether the firefox command is defined
- Whether Swank functions are available

### 2. Check Firefox Command

The firefox command is bound to: **C-t f** (Control+t, then f)

If this doesn't work:
1. Make sure Firefox is installed: `which firefox`
2. Check if the command is defined by looking at the startup messages after reload

### 3. Install Swank for Emacs Integration

If you see "Swank module failed to load", install Swank:

```bash
# Start SBCL
sbcl

# In the SBCL REPL:
(ql:quickload :swank)
(quit)
```

Then reload StumpWM config: **C-t C-r**

### 4. Start Swank Server

After Swank is installed:

Press: **Super+Ctrl+S** (Windows key + Control + S)

This toggles the Swank REPL server.

### 5. Connect from Emacs

In Emacs:
1. Install SLY if not already: `M-x package-install RET sly RET`
2. Connect to StumpWM: `M-x sly-connect RET localhost RET 4005 RET`

## Common Issues

### "Command not found: firefox"

**Solution**: The firefox command exists, but Firefox might not be installed.
```bash
sudo apt install firefox
```

### "Swank module failed to load"

**Solution**: Install Swank via Quicklisp (see step 3 above)

### "Connection refused" from Emacs

**Solution**:
1. Make sure Swank server is running: **Super+Ctrl+S**
2. Check the startup messages to see if it started
3. Try starting manually: **C-t ; swank-start**

## Checking What's Loaded

After reload (C-t C-r), look for these messages:
- "Swank module loaded successfully" ✓
- "Claude modules loaded successfully" ✓
- "Firefox command defined: T" ✓
- "Swank functions defined: T" ✓

If you see "NIL" instead of "T", that feature isn't loaded.

## Manual Testing

Press **C-t ;** to open the StumpWM command prompt, then try:

- `firefox` - Should launch Firefox
- `swank-status` - Shows if Swank server is running
- `swank-start` - Manually start Swank server

## Logs

Check the log file for errors:
```bash
cat ~/.stumpwm.d/stumpwm.log
```

## Still Having Issues?

1. Check system logs: `journalctl --user --since "5 minutes ago" | grep stump`
2. Verify StumpWM is running: `pgrep stumpwm`
3. Check for compile errors in the journal

## Note on "Slynk" vs "Swank"

The correct spelling is "Swank" (not "Slynk"). Swank is the Common Lisp backend for the SLY/SLIME Emacs modes.
