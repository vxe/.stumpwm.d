#!/bin/bash
#
# bootstrap.sh - StumpWM + Claude Desktop Environment Setup
#
# This script sets up the StumpWM configuration on a fresh install.
#
# Usage:
#   git clone <your-repo-url> ~/.stumpwm.d
#   cd ~/.stumpwm.d
#   ./bootstrap.sh
#

set -e  # Exit on error

echo "======================================"
echo "StumpWM Desktop Environment Bootstrap"
echo "======================================"
echo

# Check if StumpWM is installed
if ! command -v stumpwm &> /dev/null; then
    echo "⚠️  StumpWM not found in PATH"
    echo "   Please install StumpWM first:"
    echo "   See: https://github.com/stumpwm/stumpwm"
    echo
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if ~/.config/stumpwm already exists
if [ -e ~/.config/stumpwm ]; then
    if [ -L ~/.config/stumpwm ]; then
        echo "✓ Symlink already exists: ~/.config/stumpwm"
        CURRENT_TARGET=$(readlink -f ~/.config/stumpwm)
        EXPECTED_TARGET=$(readlink -f ~/.stumpwm.d)

        if [ "$CURRENT_TARGET" != "$EXPECTED_TARGET" ]; then
            echo "⚠️  Symlink points to: $CURRENT_TARGET"
            echo "   Expected: $EXPECTED_TARGET"
            read -p "Update symlink? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm ~/.config/stumpwm
                ln -s ~/.stumpwm.d ~/.config/stumpwm
                echo "✓ Symlink updated"
            fi
        fi
    else
        echo "⚠️  ~/.config/stumpwm exists but is not a symlink"
        read -p "Backup and replace with symlink? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            BACKUP="$HOME/.config/stumpwm.backup.$(date +%Y%m%d_%H%M%S)"
            mv ~/.config/stumpwm "$BACKUP"
            ln -s ~/.stumpwm.d ~/.config/stumpwm
            echo "✓ Backed up to: $BACKUP"
            echo "✓ Symlink created"
        else
            echo "Aborted. Please manually handle ~/.config/stumpwm"
            exit 1
        fi
    fi
else
    # Create the symlink
    mkdir -p ~/.config
    ln -s ~/.stumpwm.d ~/.config/stumpwm
    echo "✓ Created symlink: ~/.config/stumpwm -> ~/.stumpwm.d"
fi

# Create the config symlink (config.lisp -> config)
if [ ! -L ~/.stumpwm.d/config ]; then
    ln -s config.lisp ~/.stumpwm.d/config
    echo "✓ Created symlink: config -> config.lisp"
fi

# Check for SBCL
if ! command -v sbcl &> /dev/null; then
    echo
    echo "⚠️  SBCL (Steel Bank Common Lisp) not found"
    echo "   Install with: sudo apt install sbcl"
fi

# Check for Quicklisp
if [ ! -d ~/quicklisp ]; then
    echo
    echo "⚠️  Quicklisp not found at ~/quicklisp"
    echo "   Install with:"
    echo "   curl -O https://beta.quicklisp.org/quicklisp.lisp"
    echo "   sbcl --load quicklisp.lisp --eval '(quicklisp-quickstart:install)' --eval '(ql:add-to-init-file)' --quit"
fi

echo
echo "======================================"
echo "Bootstrap Complete!"
echo "======================================"
echo
echo "Next steps:"
echo "1. Log out of your current session"
echo "2. At the login screen, click the gear icon"
echo "3. Select 'StumpWM' from the session list"
echo "4. Log in"
echo
echo "Key bindings:"
echo "  C-t c     - Open terminal"
echo "  C-t f     - Open Firefox"
echo "  C-t ;     - StumpWM command prompt"
echo "  C-t ?     - Show help"
echo
echo "For Claude integration:"
echo "  export CLAUDE_API_KEY='your-key-here'"
echo "  Add to ~/.bashrc or ~/.zshrc"
echo
