# StumpWM Quick Start Guide

## Your Setup is Now Working! 🎉

Everything is configured and ready to use.

## Basic Commands

### Launch Applications

- **Firefox**: `C-t f` (Ctrl+t, then f)
- **Terminal**: `Super+Return` or `C-t c`
- **Emacs**: `Super+e` or `C-t e`
- **Browser**: `Super+b`

### Window Management

- **Move focus**: `Super+h/j/k/l` (Vim-style)
- **Move window**: `Super+Shift+h/j/k/l`
- **Close window**: `Super+q`
- **Split vertical**: `Super+v`
- **Split horizontal**: `Super+s`

### Workspaces

- **Switch workspace**: `Super+1` through `Super+5`
- **Move window to workspace**: `Super+Shift+1` through `Super+Shift+5`

### Help

- **Show all keybindings**: `Super+?`
- **Command prompt**: `C-t ;`

## Connect Emacs to StumpWM (for live coding)

### Step 1: Start REPL Server
Press: `Super+Ctrl+S`

You should see: "Slynk server started on port 4005"

### Step 2: Connect from Emacs
```elisp
M-x sly-connect RET localhost RET 4005 RET
```

### Step 3: Test It
In the SLY REPL buffer:
```lisp
STUMPWM> (message "Hello from Emacs!")
STUMPWM> (current-window)
```

## Reload Config

Anytime you edit your config:
- Press: `C-t C-r`
- Or: `C-t ; loadrc`

## Files You Can Edit

- `~/.stumpwm.d/desktop/commands.lisp` - Add custom commands
- `~/.stumpwm.d/desktop/keybindings.lisp` - Change keybindings
- `~/.stumpwm.d/desktop/theme.lisp` - Customize appearance
- `~/.stumpwm.d/desktop/core.lisp` - Core settings

## Documentation

- `README-CONFIG-FIX.md` - What was fixed and why
- `SLYNK-VS-SWANK.md` - Slynk vs Swank explained
- `SWANK-SETUP.md` - Detailed REPL setup guide
- `DEBUGGING.md` - Troubleshooting guide

## Common Issues

### Firefox won't launch
1. Check if installed: `which firefox`
2. Install if needed: `sudo apt install firefox`
3. Try: `C-t f`

### Can't connect Emacs
1. Make sure server is running: `C-t ; repl-status`
2. Start it: `Super+Ctrl+S`
3. Use `sly-connect` (not `slime-connect`)

### Config changes don't take effect
1. Reload: `C-t C-r`
2. Check for errors: `cat ~/.stumpwm.d/stumpwm.log`

## Next Steps

1. ✓ Firefox works
2. ✓ All keybindings work
3. ✓ Slynk installed
4. → Connect Emacs to try live coding
5. → Customize your keybindings
6. → Explore the modules

Enjoy your fully working StumpWM! 🚀
