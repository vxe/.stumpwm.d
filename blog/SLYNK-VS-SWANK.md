# Slynk vs Swank - What's the Difference?

## TL;DR

- **SLIME** (old) → uses **Swank** backend
- **SLY** (new) → uses **Slynk** backend (note the 'n')
- Both are installed on your system
- StumpWM now auto-detects which one to use

## The Confusion

You were 100% correct to ask about "Slynk"! I initially installed Swank, but you're using **SLY** in Emacs, which needs **Slynk** (with an 'n').

## What Are They?

### SLIME (Superior Lisp Interaction Mode for Emacs)
- The original Common Lisp IDE for Emacs
- Uses **Swank** as its backend server
- Connect with: `M-x slime-connect`

### SLY (Sylvester the Cat's Common Lisp IDE)
- A modern fork of SLIME
- Uses **Slynk** as its backend server (intentionally different name)
- Connect with: `M-x sly-connect`
- More features, better UX

## What's Installed Now

Both backends are installed:
- ✓ **Slynk** (for SLY) - ~1.8MB
- ✓ **Swank** (for SLIME) - ~750KB

## How StumpWM Handles This

The new `repl-server.lisp` module:
1. Tries to load **Slynk first** (preferred)
2. Falls back to **Swank** if Slynk not available
3. Auto-detects which one you have

## Commands

All these work the same way:

**New unified commands:**
- `:repl-start` - Start REPL server (auto-detects Slynk/Swank)
- `:repl-stop` - Stop REPL server
- `:repl-toggle` - Toggle on/off (also: `Super+Ctrl+S`)
- `:repl-status` - Check what's running

**Old commands (still work for backward compat):**
- `:swank-start` → actually starts Slynk if available
- `:swank-toggle` → actually toggles Slynk if available
- `:swank-status` → shows current server status

## Usage

### For SLY (Recommended)

1. **Start server in StumpWM:**
   ```
   Super+Ctrl+S
   ```
   You'll see: "Slynk server started on port 4005"

2. **Connect from Emacs:**
   ```elisp
   M-x sly-connect RET localhost RET 4005 RET
   ```

### For SLIME (Alternative)

1. **Start server in StumpWM:**
   ```
   C-t ; repl-start
   ```
   (If Slynk is installed, it uses that; otherwise Swank)

2. **Connect from Emacs:**
   ```elisp
   M-x slime-connect RET localhost RET 4005 RET
   ```

## Verification

After starting the server, check the message:
- "**Slynk** server started..." → Use `sly-connect`
- "**Swank** server started..." → Use `slime-connect`

Or run: `C-t ; repl-status`

## Troubleshooting

### "Package SLYNK does not exist"
Run: `sbcl --script /tmp/install-repl-backend.lisp`

### "Connection refused"
1. Start server: `Super+Ctrl+S`
2. Check status: `C-t ; repl-status`
3. Verify port: `/tmp/check-swank-port.sh`

### Wrong backend loaded
- The module auto-detects, but prefers Slynk
- Check with: `C-t ; repl-status`
- It will say ":SLYNK" or ":SWANK"

## Why the Name Difference?

SLY wanted to be compatible with SLIME but also independent. By naming the backend "Slynk" (with an 'n'), they could:
- Have both installed simultaneously
- Avoid conflicts
- Make it clear which one you're using

## Recommendation

Use **SLY** (with Slynk):
- More modern
- Better features
- Actively maintained
- Same keybindings as SLIME

Both are installed, so you can use either!
