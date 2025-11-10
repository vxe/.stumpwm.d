# Claude-Integrated Lisp Desktop Environment

**A unified, extensible Lisp-driven workspace where StumpWM, Emacs, and Claude operate as an integrated system.**

## Vision

This project creates a programmable desktop environment where **Claude AI** functions as a first-class command layer, allowing natural language control of your entire workspace. Think of it as a Lisp Machine brought into the modern era, with Claude as your intelligent partner.

> "Claude is not a chatbot inside your OS — it is your Lisp partner. The desktop is its shared mind."

## Key Features

- **Natural Language Control**: Press `Super+Space` to invoke Claude and control your desktop with natural language
- **Unified Lisp Environment**: StumpWM, Emacs, and Claude share state via Swank/SLY
- **Dynamic Reconfiguration**: Change layouts, windows, modes via Lisp or Claude commands
- **Seamless Integration**: Move between interactive REPL, Claude prompt, and desktop actions
- **Context-Aware**: Claude understands your current workspace, windows, and buffers

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    User Input                        │
│              (Super+Space → Claude)                  │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│              Claude Integration Layer                │
│  • Natural language parsing                          │
│  • Context gathering (windows, buffers, focus)       │
│  • Lisp code generation                              │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│                  Swank/SLY REPL                      │
│         (Shared between StumpWM + Emacs)             │
└────────┬────────────────────────────────┬───────────┘
         │                                │
         ▼                                ▼
┌──────────────────┐            ┌─────────────────────┐
│    StumpWM       │◄──────────►│      Emacs          │
│  (Window Mgr)    │            │  (Text Editor)      │
└──────────────────┘            └─────────────────────┘
```

## Quick Start

### Prerequisites

```bash
# Install StumpWM and dependencies
sudo apt-get install stumpwm sbcl cl-swank

# Install Emacs with SLY
sudo apt-get install emacs
# In Emacs: M-x package-install RET sly RET
```

### Installation

```bash
# Clone or symlink this repository to ~/.stumpwm.d
git clone <repo> ~/.stumpwm.d
cd ~/.stumpwm.d

# Set your Claude API key
export CLAUDE_API_KEY="your-api-key-here"

# Start StumpWM (from your .xinitrc or display manager)
exec stumpwm
```

### First Steps

1. **Start the Swank server**: Press `Super+Ctrl+S` (or run `:swank-start`)
2. **Connect from Emacs**: `M-x sly-connect RET localhost RET 4005`
3. **Invoke Claude**: Press `Super+Space` and type a command like:
   - "Open terminal in workspace 2"
   - "Balance all windows"
   - "Switch to dark theme"

## Example Commands

| Command | Effect |
|---------|--------|
| `Super+Space` → "Open browser in workspace 3" | Spawns or moves browser to workspace 3 |
| `Super+Space` → "Balance all windows" | Runs `(balance-frames)` |
| `Super+Space` → "Show me all keybindings" | Lists configured keybindings |
| `Super+Space` → "Reload config" | Re-evaluates `init.lisp` |
| `Super+Space` → "Tile Emacs and terminal side-by-side" | Creates 2-column layout |

## File Structure

```
.stumpwm.d/
├── init.lisp                      # Main entry point (loads everything)
├── desktop/
│   ├── core.lisp                  # Core settings (gaps, borders, groups)
│   ├── keys.lisp                  # Commands + keybindings together
│   ├── theme.lisp                 # Colors and visual theme
│   └── formatters.lisp            # Modeline formatters
├── modules/
│   ├── stumpwm-eval.lisp          # File-based eval system (CRITICAL)
│   ├── claude-swank.lisp          # Swank/SLY setup
│   ├── claude-integration.lisp    # Claude API integration
│   ├── claude-commands.lisp       # Claude-specific commands
│   └── context-gathering.lisp     # Workspace context extraction
├── lib/
│   ├── utils.lisp                 # Utility functions (loaded FIRST)
│   └── http-client.lisp           # HTTP client for API calls
├── emacs/
│   └── (future Emacs integration)
└── docs/
    └── (documentation)
```

### Critical: init.lisp Load Order

**Load order matters!** Dependencies must load before consumers:

1. **Quicklisp** - Required for installing packages
2. **Swank** - REPL server (port 4005) for Emacs SLY
3. **stumpwm-eval** - File-based eval (critical for debugging)
4. **lib/utils.lisp** - Helper functions (log-*, json-*, etc.)
5. **desktop/core.lisp** - Core settings
6. **desktop/theme.lisp** - Visual configuration
7. **desktop/formatters.lisp** - Modeline formatters
8. **desktop/keys.lisp** - Commands and keybindings LAST

## What's Working Now

✅ **Auto-Loading Services**:
- Swank server (port 4005) - starts automatically
- stumpwm-eval watcher - starts automatically
- All configuration files load in correct order

✅ **Keybindings**:
- M-DEL (Option+Backspace) - Prefix key
- M-e - Launch/raise Emacs
- M-f - Launch/raise Firefox
- M-t - Launch/raise Kitty terminal
- M-o - Launch/raise OBS

✅ **Developer Tools**:
- `stumpwm-eval 'CODE'` - Execute Lisp from shell
- Swank REPL - Connect from Emacs with `M-x sly-connect`
- `loadrc` - Reload config without restart

## Troubleshooting

### Configuration Not Loading After Restart

If your keybindings don't work after restart:

```bash
# 1. Check swank is running
nc -v localhost 4005

# 2. Check stumpwm-eval works
stumpwm-eval '(+ 1 2)'
# Should return: 3

# 3. Check keybindings are loaded
stumpwm-eval '(fboundp (quote kitty))'
# Should return: #<FUNCTION KITTY>

# 4. Check key is bound
stumpwm-eval '(stumpwm::lookup-key stumpwm::*top-map* (stumpwm::kbd "M-t"))'
# Should return: 3 (key object)
```

If any of these fail, check `~/.stumpwm.d/init.lisp` load order.

### Swank Not Starting

```bash
# Install swank via quicklisp
sbcl --eval '(ql:quickload :swank)' --quit

# Restart StumpWM
# In StumpWM: M-DEL ; restart
```

### stumpwm-eval Timeout

```bash
# Check if eval watcher is running
ls -la /tmp/stumpwm-eval*

# If files missing, watcher not running
# In StumpWM: M-DEL ; eval-watcher-start
```

## Milestones

- [x] Setup SLY + StumpWM integration (Swank server)
- [x] stumpwm-eval file-based system (shell debugging)
- [x] Auto-starting services on loadrc
- [x] Option key launchers (M-e, M-f, M-t, M-o)
- [x] Borderless windows, zero gaps
- [ ] Claude integration (API calls)
- [ ] Emacs integration (stumpctl.el + claude-mode)
- [ ] Context-aware prompts (current app/file awareness)

## Configuration

### Setting Claude API Key

Add to your `~/.bashrc` or `~/.profile`:

```bash
export CLAUDE_API_KEY="sk-ant-..."
```

Or configure in `config/core.lisp`:

```lisp
(defparameter *claude-api-key*
  (uiop:getenv "CLAUDE_API_KEY"))
```

### Customizing Keybindings

Edit `config/keybindings.lisp`:

```lisp
;; Change Claude invocation key
(define-key *top-map* (kbd "s-SPC") "claude-ask")

;; Add custom workspace commands
(define-key *top-map* (kbd "s-1") "gselect 1")
```

## Development

### Interactive Development with SLY

1. Start Swank in StumpWM: `Super+Ctrl+S`
2. Connect from Emacs: `M-x sly-connect`
3. Evaluate code directly in your running StumpWM instance
4. Hot-reload modules without restarting X11

### Adding New Commands

Create a new command in `modules/claude-commands.lisp`:

```lisp
(defcommand my-command () ()
  "Documentation here"
  (message "Hello from StumpWM!"))
```

Then teach Claude about it by using it in context.

## Contributing

This is an experimental project exploring the boundaries of Lisp desktop environments and AI integration. Contributions welcome!

## License

GPLv3

## Author

Vijay Edwin

**Version:** 0.1-alpha
**Status:** Early development
