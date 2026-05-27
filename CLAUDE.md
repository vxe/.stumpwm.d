# StumpWM Config — Claude Instructions

## Preferred Edit Workflow (cl-mcp)

Use the `cl-mcp` MCP tools for all `.lisp` edits — they are structure-aware and
preserve formatting and comments:

```
mcp__cl-mcp__lisp-check-parens   — verify parens balance
mcp__cl-mcp__lisp-read-file      — read file in collapsed/navigable form
mcp__cl-mcp__lisp-patch-form     — patch text inside a named top-level form
mcp__cl-mcp__lisp-edit-form      — replace/insert/delete a named top-level form
mcp__cl-mcp__repl-eval           — eval in a cl-mcp pool worker SBCL
                                    (NOT the running StumpWM image)
```

**To evaluate in the live StumpWM image**, use the `stumpwm-eval` shell command
(file-based eval watcher) — `repl-eval` runs in a separate SBCL pool worker
and does not see StumpWM's runtime state.

## RFCs

Design RFCs for this config live in `~/Documents/rfcs/` (shared across all
~/Documents projects). The index is `~/Documents/rfcs/index.md`. Add new
RFCs there and register them in the index table.

Relevant RFCs:
- `stumpwm-desktop-overview.md` — architecture
- `stumpwm-boot-stability.md` — no-brick init.lisp pattern (handler-case
  wrapping + boot trace + deferred startup)
- `stumpwm-polybar.md`, `stumpwm-modeline.md`, `stumpwm-volume.md`, etc.

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

## Shell-command Hang Rule (CRITICAL)

**Never combine `(run-shell-command CMD t)` with a CMD that backgrounds a
process via `&`** — this is the canonical way to freeze StumpWM's event
loop forever, and we have already hit it once (2026-05-27, the dropbox
autostart bug).

Why: the `t` argument tells stumpwm to capture stdout (`run-prog-collect-output`).
Stumpwm reads until EOF. The shell forks the daemon into the background,
but the daemon **inherits** the parent shell's stdout fd, which is the
pipe to stumpwm. The daemon never closes stdout. Stumpwm reads → blocks
in `poll()` forever. All keys dead.

Stumpwm's own `user.lisp:163-165` warns about this:
> "Be careful. If the shell command doesn't return, it will hang StumpWM.
>  In such a case, kill the shell command to resume StumpWM."

### Safe patterns for launching daemons

```lisp
;; PREFERRED: detach stdio inside the shell, drop the `t` capture flag.
(run-shell-command
 (format nil "pgrep -x ~A > /dev/null || (~A </dev/null >/dev/null 2>&1 &)"
         process command))

;; ALSO OK: explicit log-file redirect (still no `t`).
(run-shell-command
 "pgrep -x foo > /dev/null || foo >> /tmp/foo.log 2>&1 &")
```

### Forbidden pattern

```lisp
;; NEVER DO THIS — `t` + `&` = guaranteed event-loop hang.
(run-shell-command "pgrep -x foo > /dev/null || foo &" t)
```

### Quick mental check before adding a `run-shell-command`

If the command ends in `&` (or otherwise spawns a long-lived process),
the `collect-output-p` argument **must be NIL** (or omitted). Capture only
from short-lived programs that exit on their own.

## Branching Rule (solo repo)

This repo has a single contributor. Don't waste a round-trip syncing with
`origin/main` before branching — **always branch off the current branch**.
If `main` has new commits this branch doesn't, that's fine; the new PR will
just include those when it merges, or be rebased at merge time.

```bash
# Correct:
git checkout -b vxe/<topic>           # branches off current HEAD

# Don't:
git fetch origin main && git checkout -b vxe/<topic> origin/main
```

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
