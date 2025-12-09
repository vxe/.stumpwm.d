# /etc - Example Configuration Files

This directory contains example configuration files for external tools integrated with StumpWM.

## Files

### polybar.config.ini
Example Polybar configuration that works with StumpWM.

**Installation:**
```bash
mkdir -p ~/.config/polybar
cp ~/.stumpwm.d/etc/polybar.config.ini ~/.config/polybar/config.ini
```

**Features:**
- System tray support (for nm-applet, dropbox, etc.)
- Date/time display
- CPU usage
- Memory usage
- Battery status
- Dark theme matching StumpWM aesthetic

**Used by:** The Polybar integration in `init.lisp` (lines 282-302)

## Future Files
- `stumpwm-autostart.lisp` - List of applications to launch on startup
- `custom-keybindings.lisp` - User keybinding templates
- `theme-templates/` - Color scheme examples
