# StumpWM Config — Claude Instructions

## Preferred Edit Workflow (cl-mcp)

Use the `cl-mcp` MCP tools for all `.lisp` edits — they are structure-aware and
preserve formatting and comments:

```
mcp__cl-mcp__lisp-check-parens   — verify parens balance
mcp__cl-mcp__lisp-read-file      — read file in collapsed/navigable form
mcp__cl-mcp__lisp-patch-form     — patch text inside a named top-level form
mcp__cl-mcp__lisp-edit-form      — replace/insert/delete a named top-level form
mcp__cl-mcp__repl-eval           — eval in running StumpWM SBCL image, see result
```

Always set the project root first:
```
mcp__cl-mcp__fs-set-project-root  path=/home/vxe/.stumpwm.d
```

## Safe Edit Protocol

Follow this sequence for every change to `init.lisp` or any `.lisp` file here.

### 1. Backup
```bash
cp ~/.stumpwm.d/init.lisp ~/.stumpwm.d/init.lisp.bak
```

### 2. Edit using cl-mcp tools
Prefer `lisp-patch-form` for small changes inside a known form.
Use `lisp-edit-form` to replace, insert, or delete entire top-level forms.
Always dry-run first (`dry_run: true`) before committing.

### 3. Check parens
```
mcp__cl-mcp__lisp-check-parens  path=/home/vxe/.stumpwm.d/init.lisp
```
If result is not `ok`, restore immediately:
```bash
cp ~/.stumpwm.d/init.lisp.bak ~/.stumpwm.d/init.lisp
```

### 4. Eval-check via stumpwm-eval
```bash
stumpwm-eval '(load "/home/vxe/.stumpwm.d/init.lisp")'
```
Expected output: `T`

Any `EVAL-ERROR:` or `READ-ERROR:` is a real error — restore the backup and fix
before finishing:
```bash
cp ~/.stumpwm.d/init.lisp.bak ~/.stumpwm.d/init.lisp
```

## StumpWM Source

StumpWM source lives at `/home/vxe/Development/stumpwm`.
Consult it to find internal function/variable names before probing with `stumpwm-eval`.
Use `rg` (ripgrep) for fast searches — e.g. `rg -n "defun.*kmap" /home/vxe/Development/stumpwm/`.

Key introspection functions (all in `stumpwm::` package):
- `(stumpwm::kmap-bindings kmap)` — list bindings in a keymap
- `(stumpwm::binding-key b)` / `(stumpwm::binding-command b)` — accessors
- `(stumpwm::print-key key)` — key → string

## Package Rule

**Always use `(in-package :stumpwm-user)`** at the top of `init.lisp` and any
user config files. Never define user functions or commands in the `stumpwm`
package. `stumpwm-user` uses `stumpwm` so all exported WM functions are
accessible without qualification. Internal (unexported) StumpWM functions still
need `stumpwm::` prefix (e.g. `stumpwm::update-modifier-map`).

## Notes

- `start-eval-watcher` is idempotent — reloading init.lisp will not spawn
  duplicate watchers (it early-returns if already running)
- `cl-mcp:start-http-server` is also guarded by `http-server-running-p` — safe
  to reload
- The eval watcher polls `/tmp/stumpwm-eval-input` and writes results to
  `/tmp/stumpwm-eval-output`
- `show-keybindings` is a callable defcommand — invoke it anytime via
  `H-BackSpace ;` → `show-keybindings`
