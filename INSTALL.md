# Installation Guide

## Quick Start (5 minutes)

### 1. Prerequisites

```bash
# Install StumpWM and dependencies
sudo apt-get update
sudo apt-get install -y stumpwm sbcl curl

# Or on Fedora/RHEL:
# sudo dnf install -y stumpwm sbcl curl

# Or on Arch:
# sudo pacman -S stumpwm sbcl curl
```

### 2. Get Claude API Key

1. Visit https://console.anthropic.com
2. Sign up or log in
3. Create a new API key
4. Copy the key (starts with `sk-ant-api03-...`)

### 3. Install Configuration

```bash
# If you already have a ~/.stumpwm.d, back it up first
[ -d ~/.stumpwm.d ] && mv ~/.stumpwm.d ~/.stumpwm.d.backup

# Clone this repository
git clone <repo-url> ~/.stumpwm.d
cd ~/.stumpwm.d
```

### 4. Set API Key

```bash
# Add to your shell profile
echo 'export CLAUDE_API_KEY="sk-ant-api03-YOUR-KEY-HERE"' >> ~/.bashrc
source ~/.bashrc

# Verify it's set
echo $CLAUDE_API_KEY
```

### 5. Start StumpWM

**Option A: From login screen**

Add to `~/.xinitrc`:

```bash
#!/bin/sh
export CLAUDE_API_KEY="sk-ant-api03-YOUR-KEY-HERE"
exec stumpwm
```

Make it executable:

```bash
chmod +x ~/.xinitrc
```

**Option B: From existing session**

```bash
stumpwm
```

### 6. Test It!

Once StumpWM starts:

1. Press `Super+X` (or `C-t :`)
2. Type: `:claude-test`
3. Press Enter

You should see: "Success! Claude says: Connection successful."

If so, you're ready! Press `Super+Space` to start using Claude.

---

## Optional: Full Setup (15 minutes)

For the best experience, install these optional components:

### Emacs + SLY Integration

#### Install Emacs

```bash
sudo apt-get install -y emacs
```

#### Install SLY

1. Start Emacs: `emacs`
2. Press: `M-x package-install RET sly RET`
3. Wait for installation to complete

#### Load StumpWM Integration

Add to your `~/.emacs` or `~/.emacs.d/init.el`:

```elisp
;; Load StumpWM control module
(add-to-list 'load-path "~/.stumpwm.d/emacs")
(require 'stumpctl)
(require 'claude-mode)

;; Enable Claude mode globally
(global-claude-mode 1)

;; Optional: Set API key if not in environment
;; (setq claude-api-key "sk-ant-api03-...")
```

Restart Emacs.

#### Test Emacs Integration

1. In StumpWM: `Super+Ctrl+S` (starts Swank server)
2. In Emacs: `M-x stumpctl-connect`
3. You should see: "Connected to StumpWM!"
4. Test: `M-x stumpctl-message RET Hello from Emacs! RET`

You should see a message in StumpWM.

### Quicklisp (for development)

Quicklisp makes it easy to install Lisp libraries like Swank.

```bash
# Download Quicklisp
cd ~
curl -O https://beta.quicklisp.org/quicklisp.lisp

# Install
sbcl --load quicklisp.lisp <<EOF
(quicklisp-quickstart:install)
(ql:add-to-init-file)
(quit)
EOF
```

Now start SBCL and install Swank:

```bash
sbcl
```

```lisp
(ql:quickload :swank)
(quit)
```

Done! Now the Swank server will work in StumpWM.

---

## Verification Checklist

After installation, verify everything works:

- [ ] StumpWM starts without errors
- [ ] Welcome message appears on startup
- [ ] `:claude-test` returns success
- [ ] `Super+Space` opens Claude prompt
- [ ] `:claude-status` shows "API Key: Set"
- [ ] (Optional) Swank server starts: `Super+Ctrl+S`
- [ ] (Optional) Emacs connects: `M-x stumpctl-connect`

---

## Troubleshooting

### "Claude API key not configured"

**Problem**: API key not set or not visible to StumpWM

**Solution**:

```bash
# Check if it's set
echo $CLAUDE_API_KEY

# If empty, add to ~/.bashrc and restart shell
echo 'export CLAUDE_API_KEY="sk-ant-..."' >> ~/.bashrc
source ~/.bashrc

# Then restart StumpWM
```

### "Swank server failed to start"

**Problem**: Swank not installed

**Solution**: Install via Quicklisp (see above), or disable:

Edit `~/.stumpwm.d/config/core.lisp`:

```lisp
(setf *swank-auto-start* nil)
```

### "curl: command not found"

**Problem**: curl not installed

**Solution**:

```bash
sudo apt-get install curl
```

### StumpWM won't start

**Problem**: Syntax error in configuration

**Solution**:

```bash
# Start StumpWM with error output
startx ~/.xinitrc -- :1 2>&1 | tee /tmp/stumpwm-errors.txt

# Check for errors
cat /tmp/stumpwm-errors.txt
```

Or temporarily use default config:

```bash
mv ~/.stumpwm.d ~/.stumpwm.d.disabled
```

### "No window manager found"

**Problem**: X11 not finding StumpWM

**Solution**: Ensure `~/.xinitrc` has:

```bash
exec stumpwm
```

Not just `stumpwm` (without `exec`).

---

## Uninstallation

To remove this configuration:

```bash
# Restore original config if you backed it up
rm -rf ~/.stumpwm.d
mv ~/.stumpwm.d.backup ~/.stumpwm.d

# Or use default StumpWM config
rm -rf ~/.stumpwm.d
```

To keep your configuration but disable Claude:

Edit `~/.stumpwm.d/init.lisp` and comment out:

```lisp
;; (load-module-file "claude-integration.lisp")
;; (load-module-file "claude-commands.lisp")
```

---

## Next Steps

1. **Read the guide**: [CLAUDE_INTEGRATION.md](docs/CLAUDE_INTEGRATION.md)
2. **Learn the architecture**: [ARCHITECTURE.md](docs/ARCHITECTURE.md)
3. **Customize**: Edit files in `config/` and `modules/`
4. **Share your setup**: Contribute improvements!

---

## Support

- **Documentation**: See `docs/` directory
- **Issues**: GitHub issues (if this is a public repo)
- **StumpWM help**: https://stumpwm.github.io/
- **Claude API help**: https://docs.anthropic.com/

Welcome to the future of Lisp desktop computing! 🚀
