# Polybar Integration: The restart-hard Gotcha

## The Problem

When integrating Polybar with StumpWM, a common approach is to disable StumpWM's built-in mode-line. However, using `enable-mode-line` incorrectly can break the `restart-hard` command with a cryptic error:

```
Error in command restart-hard: The value NIL is not of type (MOD 461168601842738790) when binding SB-INT:INDEX
```

When this happens, `restart-hard` sends you back to the Ubuntu login screen instead of properly restarting StumpWM.

## The Root Cause

The issue stems from this innocent-looking line in your `init.lisp`:

```lisp
;; WRONG - causes restart-hard to crash
(enable-mode-line (current-screen) (current-head) nil)
```

What happens:
1. This creates a mode-line structure with a `nil` format (instead of actually disabling the mode-line)
2. When `restart-hard` runs, it calls `destroy-all-mode-lines`
3. The destruction process tries to access the `nil` format as if it were a string/sequence
4. SBCL throws a type error because `nil` is not a valid index
5. StumpWM crashes and you're kicked to the login screen

## The Solution

**Simply comment out or remove that line entirely:**

```lisp
;; Disable StumpWM mode-line (Polybar will replace it)
;; (enable-mode-line (current-screen) (current-head) nil)  ; Commented out - causes issues with restart-hard
```

You don't need to explicitly disable the mode-line because:
- StumpWM doesn't create a mode-line by default
- You're using Polybar as your status bar
- The line was creating a broken mode-line structure that caused crashes

## Working Polybar Integration

Here's the correct way to integrate Polybar:

```lisp
;;;; ===========================================================================
;;;; Polybar Integration (replaces StumpWM mode-line)
;;;; ===========================================================================

;; NOTE: No need to explicitly disable mode-line - just don't enable it!

;; Float Polybar window so StumpWM doesn't tile it
(defun float-polybar (win)
  "Float Polybar window when it appears."
  (when (string= (window-class win) "Polybar")
    (float-window win (current-group))))

(add-hook *new-window-hook* 'float-polybar)

;; Launch Polybar on startup
(run-shell-command "polybar stumpwm &")

;; Launch system tray applets
(run-shell-command "nm-applet &")
(run-shell-command "blueman-applet &")
```

## Debugging This Issue

If you're already experiencing this problem, here's how to diagnose and fix it:

### 1. Check if you have broken mode-lines in memory

```lisp
;; In stumpwm-eval or via C-t ;
stumpwm::*mode-lines*

;; Check the formats
(mapcar (lambda (ml) (stumpwm::mode-line-format ml)) stumpwm::*mode-lines*)
```

If you see `NIL` values, those are broken mode-lines.

### 2. Test destroy-all-mode-lines

```lisp
;; This should reproduce the error
(handler-case
    (stumpwm::destroy-all-mode-lines)
  (error (e) (format nil "ERROR: ~A" e)))
```

### 3. Clear broken mode-lines (temporary fix)

```bash
stumpwm-eval '(setf stumpwm::*mode-lines* nil)'
```

This clears the broken mode-lines from memory, allowing `restart-hard` to work again temporarily.

### 4. Fix your init.lisp (permanent fix)

Comment out or remove the problematic `enable-mode-line` call, then restart StumpWM.

## Why This Is So Confusing

The error message is completely unhelpful:
- "MOD 461168601842738790" is just SBCL's way of saying "valid array index"
- "SB-INT:INDEX" is an internal SBCL type
- Nothing in the message hints at mode-lines or Polybar

Without diving into the StumpWM source code, you'd never guess that:
1. `restart-hard` calls `destroy-all-mode-lines`
2. `destroy-mode-line` calls `sync-mode-line`
3. Somewhere in that chain, code tries to access a `nil` value as an array index
4. The root cause is a single line trying to "disable" the mode-line

## Verification

After fixing your init.lisp, verify the fix:

```bash
# Restart StumpWM
stumpwm-eval '(restart-hard)'

# OR test the function directly
stumpwm-eval '(handler-case
                  (progn (stumpwm::destroy-all-mode-lines) "SUCCESS")
                (error (e) (format nil "ERROR: ~A" e)))'
```

If you see "SUCCESS" or if `restart-hard` properly restarts StumpWM (without kicking you to login), you're good!

## Lesson Learned

When integrating external status bars like Polybar, Lemonbar, or i3bar with StumpWM:

✅ **DO**: Let StumpWM start without a mode-line (it's the default)
✅ **DO**: Float the external bar's window
✅ **DO**: Launch the external bar via `run-shell-command`

❌ **DON'T**: Call `enable-mode-line` with `nil` format
❌ **DON'T**: Try to "disable" something that's not enabled

## Related Issues

This same issue can occur with:
- Any code that calls `enable-mode-line` with a `nil` or invalid format
- Multiple init.lisp loads that keep creating broken mode-lines
- Manual mode-line creation with improper parameters

## References

- StumpWM source: `usr/stumpwm/mode-line.lisp:485` - `enable-mode-line` function
- StumpWM source: `usr/stumpwm/mode-line.lisp:260` - `destroy-mode-line` function
- StumpWM source: `usr/stumpwm/user.lisp:243` - `restart-hard` command

---

**TL;DR**: Don't use `(enable-mode-line (current-screen) (current-head) nil)` when setting up Polybar. Just don't enable the mode-line at all, and `restart-hard` will work fine.
