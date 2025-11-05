# Claude Integration Guide

## Overview

This guide explains how to set up and use Claude AI as a natural language interface for your StumpWM desktop environment.

## Prerequisites

### Required Software

1. **StumpWM** - Window manager
   ```bash
   sudo apt-get install stumpwm sbcl
   ```

2. **curl** - For HTTP requests
   ```bash
   sudo apt-get install curl
   ```

3. **Claude API Key** - Get from Anthropic
   - Sign up at https://console.anthropic.com
   - Generate an API key

### Optional Software

1. **Emacs + SLY** - For development and Emacs integration
   ```bash
   sudo apt-get install emacs
   # In Emacs: M-x package-install RET sly RET
   ```

2. **Quicklisp** - For loading Swank easily
   ```bash
   curl -O https://beta.quicklisp.org/quicklisp.lisp
   sbcl --load quicklisp.lisp
   # Then: (quicklisp-quickstart:install)
   ```

## Installation

### Step 1: Install Configuration

```bash
# Clone or copy this repository to ~/.stumpwm.d
git clone <repo-url> ~/.stumpwm.d
cd ~/.stumpwm.d
```

### Step 2: Set API Key

Add to your `~/.bashrc` or `~/.profile`:

```bash
export CLAUDE_API_KEY="sk-ant-api03-..."
```

Then reload:

```bash
source ~/.bashrc
```

### Step 3: Install Swank (Optional but Recommended)

If you have Quicklisp installed:

```bash
sbcl
```

In the SBCL REPL:

```lisp
(ql:quickload :swank)
(quit)
```

### Step 4: Start StumpWM

Add to your `~/.xinitrc`:

```bash
exec stumpwm
```

Or start from your display manager.

## First Steps

### Test the Installation

1. **Start StumpWM** - You should see a welcome message

2. **Check Status** - Press `Super+X` and type:
   ```
   :claude-status
   ```

3. **Test Connection** - Run:
   ```
   :claude-test
   ```

   If successful, you'll see: "Success! Claude says: Connection successful."

### Your First Query

Press `Super+Space` (or `Super+X` then `:claude-ask`) and type:

```
What windows do I have open?
```

Claude will analyze your desktop state and respond with information about your current windows and workspaces.

## Usage Guide

### Basic Commands

#### Ask Claude Anything

**Keybinding**: `Super+Space`
**Command**: `:claude-ask <prompt>`

Examples:
```
Super+Space → "Show me all my workspaces"
Super+Space → "How do I split a window?"
Super+Space → "What's the current window?"
```

#### Execute Commands

**Command**: `:claude-do <prompt>`

This automatically executes any Lisp code Claude returns.

Examples:
```
:claude-do Move Firefox to workspace 2
:claude-do Balance all windows
:claude-do Create a 3-column layout
```

**Warning**: Only use `:claude-do` when you trust the command. It executes code automatically.

#### Execute Code Manually

**Keybinding**: `Super+Ctrl+Space`
**Command**: `:claude-eval-region <code>`

If Claude suggests code but you used `:claude-ask`, you can copy the code and execute it:

```
:claude-eval-region (stumpwm:hsplit)
```

### Specialized Commands

#### Layout Suggestions

**Command**: `:claude-layout`

Asks Claude to suggest an optimal layout for your current windows.

```
:claude-layout
→ "Based on your Firefox, Emacs, and terminal windows,
   I suggest a 3-column layout with Emacs in the center..."
```

#### Keybinding Help

**Command**: `:claude-keybindings`

Get explanations of available keybindings.

#### Troubleshooting

**Command**: `:claude-troubleshoot`

Ask Claude to analyze your current setup for issues.

### Context Awareness

Claude receives context about your desktop with every query:

- **Current window**: Class, title, size
- **All workspaces**: Names, window counts
- **Focus state**: Which workspace is active
- **Frame layout**: Split configuration

To see what context Claude receives:

```
:claude-show-context
```

To ask Claude WITHOUT context (faster, but less intelligent):

```
:claude-without-context <prompt>
```

## Advanced Usage

### Conversation History

**Show history**:
```
:claude-history
```

**Show last response**:
```
:claude-last-response
```

**Repeat last query**:
```
:claude-repeat-last
```

**Clear history**:
```
:claude-clear-history
```

### Smart Window Management

**Move window intelligently**:
```
:claude-move-window-smart
```

Claude will suggest the best workspace for the current window.

**Organize workspace**:
```
:claude-organize-workspace dev
```

Ask Claude to help organize a specific workspace.

**Clean up desktop**:
```
:claude-cleanup
```

Get suggestions for closing unnecessary windows and organizing.

### Application Launching

**Launch by description**:
```
:claude-launch web browser
:claude-launch terminal emulator
:claude-launch my IDE
```

Claude will figure out the appropriate command.

## Emacs Integration

### Setup

1. **Load the modules** in your Emacs init file:

```elisp
(add-to-list 'load-path "~/.stumpwm.d/emacs")
(require 'stumpctl)
(require 'claude-mode)

;; Enable globally
(global-claude-mode 1)
```

2. **Set API key** (if not already in environment):

```elisp
(setq claude-api-key "sk-ant-api03-...")
```

3. **Connect to StumpWM**:

```elisp
M-x stumpctl-connect
```

### Emacs Commands

#### Ask Claude in Emacs

```
M-x claude-ask RET What does this function do? RET
```

#### Explain Code

1. Select a region of code
2. `M-x claude-explain-code`

#### Improve Code

1. Select a region of code
2. `M-x claude-improve-code`

#### Generate Code

```
M-x claude-generate-code RET
What to generate: A function that sorts a list of numbers
```

#### StumpWM Commands from Emacs

```
M-x claude-stumpwm-command RET
What should StumpWM do: Create a horizontal split
```

Then execute the generated code:

```
M-x claude-execute-in-stumpwm
```

### Keybindings in Emacs

When `claude-mode` is enabled:

- `C-c a` - Ask Claude
- `C-c e` - Explain selected code
- `C-c i` - Improve selected code
- `C-c g` - Generate code
- `C-c s` - StumpWM command
- `C-c x` - Execute in StumpWM

## Interactive Development with SLY

### Starting Swank

**In StumpWM**: Press `Super+Ctrl+S` or run `:swank-start`

You should see:
```
Swank server started on port 4005
Connect from Emacs with: M-x sly-connect RET localhost RET
```

### Connecting from Emacs

```
M-x sly-connect RET localhost RET 4005 RET
```

You'll now have a live REPL running in your StumpWM process!

### What You Can Do

**Test commands before adding to config**:
```lisp
(stumpwm:message "Hello!")
(stumpwm:gselect "dev")
```

**Inspect window objects**:
```lisp
(stumpwm:current-window)
(stumpwm:window-class (stumpwm:current-window))
```

**Hot-reload modules**:
```lisp
(load "~/.stumpwm.d/modules/claude-commands.lisp")
```

**Debug Claude integration**:
```lisp
(setf stumpwm:*claude-debug* t)
(stumpwm:gather-full-context)
```

### Development Workflow

1. Edit `.lisp` file in Emacs
2. `C-c C-c` to evaluate current form
3. Test in StumpWM immediately
4. Repeat until working
5. Reload full config: `:reload-config`

No need to restart X11!

## Examples

### Example 1: Morning Workspace Setup

```
:claude-do Create a dev workspace with terminal, emacs, and browser in 3 columns
```

Claude generates:
```lisp
(progn
  (stumpwm:gselect "dev")
  (stumpwm:run-commands "exec alacritty")
  (stumpwm:hsplit)
  (stumpwm:run-commands "exec emacs")
  (stumpwm:hsplit)
  (stumpwm:run-commands "exec firefox")
  (stumpwm:balance-frames))
```

### Example 2: Focus Management

```
Super+Space → "I need to focus on writing. Which windows should I close?"
```

Claude analyzes your windows and suggests:
```
Based on your current workspace, you have:
- 3 browser windows with YouTube and social media
- Slack
- A terminal and Emacs

I recommend closing the YouTube/social windows and Slack.
To focus: :claude-do Close all browser windows except the one with documentation
```

### Example 3: Learning StumpWM

```
:claude-ask How do I create custom commands in StumpWM?
```

Claude explains:
```
To create custom commands in StumpWM, use the `defcommand` macro...

Example:
(defcommand my-command () ()
  "Documentation here"
  (message "Hello from my command!"))

Then bind it to a key in keybindings.lisp:
(define-key *top-map* (kbd "s-m") "my-command")
```

### Example 4: Code from Emacs

In Emacs, select this buggy code:

```elisp
(defun sort-numbers (nums)
  (sort nums >))
```

Run `M-x claude-improve-code`:

Claude suggests:
```elisp
(defun sort-numbers (nums)
  "Sort NUMS in ascending order, non-destructively."
  (sort (copy-sequence nums) #'<))
```

## Troubleshooting

### "Claude API key not configured"

**Solution**: Set environment variable
```bash
export CLAUDE_API_KEY="sk-ant-..."
```

Restart StumpWM after setting.

### "Failed to get response from Claude"

**Possible causes**:
1. No internet connection
2. Invalid API key
3. API rate limit reached
4. curl not installed

**Debug**:
```
:claude-debug-toggle  # Enable debug logging
:claude-test          # Test connection
```

Check logs: `~/.stumpwm.d/stumpwm.log`

### Swank server won't start

**Solution**: Install Swank via Quicklisp

```bash
sbcl
(ql:quickload :swank)
```

Or set `*swank-auto-start* nil` in `config/core.lisp` if you don't need it.

### Commands are slow

**Possible causes**:
1. Context gathering overhead
2. Large conversation history

**Solutions**:
```lisp
;; In config/core.lisp:
(setf *claude-include-window-titles* nil)  ; Reduce context
(setf *claude-include-system-info* nil)

;; Clear history:
:claude-clear-history
```

### Claude's code doesn't work

**Debug process**:
1. Look at the exact code: `:claude-last-response`
2. Try in REPL first: `Super+Ctrl+S` then connect via SLY
3. Check StumpWM docs: `:help <function-name>`
4. Ask Claude to fix: `:claude-ask The code you gave me doesn't work. Error: ...`

## Tips & Best Practices

### Be Specific

❌ Bad: "Fix my windows"
✅ Good: "Move all browser windows to workspace 'web' and tile them vertically"

### Use Context

Claude knows your desktop state, so leverage it:

```
"Move this window to the workspace with fewest windows"
"What's taking up the most screen space?"
```

### Review Before Executing

For complex operations, use `:claude-ask` first (no auto-exec), review the code, then:

```
:claude-eval-region <paste code here>
```

### Teach Claude

Have a custom workflow? Describe it:

```
:claude-ask I have a command called 'my-dev-setup' that creates 4 workspaces
and launches specific apps. Remember this for future queries.
```

Claude will use this context in the same session.

### Combine with Traditional Commands

You don't need Claude for everything:

- Quick actions: Use keybindings (`Super+H/J/K/L`)
- Complex queries: Use Claude ("Suggest optimal layout")
- One-off tasks: Mix both

## Configuration

### Adjust Claude Behavior

Edit `config/core.lisp`:

```lisp
;; Use a different model
(setf *claude-model* "claude-3-opus-20240229")

;; Increase response length
(setf *claude-max-tokens* 8192)

;; Disable window title context (privacy)
(setf *claude-include-window-titles* nil)

;; Change timeout
(setf *claude-timeout* 60)
```

### Custom System Prompt

Edit `modules/claude-integration.lisp`:

```lisp
(defparameter *claude-system-prompt*
  "You are a concise, expert Lisp programmer controlling StumpWM.
   Always provide working code. Be brief. ...")
```

### Add Custom Commands

In `modules/claude-commands.lisp`:

```lisp
(defcommand my-claude-workflow () ()
  "My custom workflow."
  (claude-ask "Set up my morning workspace: dev, email, web"
              :include-context t
              :execute-code t))
```

Then add keybinding in `config/keybindings.lisp`:

```lisp
(define-key *top-map* (kbd "s-M") "my-claude-workflow")
```

## Security & Privacy

### What Data is Sent to Claude?

When you use Claude, the following is sent:

1. **Your prompt** (always)
2. **Desktop context** (if enabled):
   - Window titles
   - Window class names
   - Workspace names
   - Frame layout

**Not sent**:
- Window contents
- Clipboard
- Keystrokes
- Filesystem contents (unless you explicitly include them)

### Disable Context Sharing

```lisp
;; In config/core.lisp:
(setf *claude-include-window-titles* nil)
(setf *claude-include-group-info* nil)
(setf *claude-include-system-info* nil)
```

Or use:
```
:claude-without-context <prompt>
```

### Review Code Before Execution

**Always review** when using `:claude-do` for:
- System commands (`rm`, `sudo`, etc.)
- Network operations
- File modifications

Claude is trained to be helpful and harmless, but always verify.

## Resources

- **StumpWM Manual**: https://stumpwm.github.io/
- **Claude API Docs**: https://docs.anthropic.com/
- **SLY Manual**: https://joaotavora.github.io/sly/
- **Common Lisp**: http://www.gigamonkeys.com/book/

## Getting Help

1. **Ask Claude**: `:claude-ask How do I...?`
2. **Check logs**: `~/.stumpwm.d/stumpwm.log`
3. **REPL debug**: Connect via SLY and investigate
4. **Community**: StumpWM mailing list, IRC (#stumpwm on Libera.Chat)

## Next Steps

- Read [ARCHITECTURE.md](ARCHITECTURE.md) for technical details
- Explore `config/` to customize behavior
- Write custom commands in `modules/claude-commands.lisp`
- Integrate with your Emacs workflow
- Share your setup and contribute improvements!

---

Happy Lisping! 🚀
