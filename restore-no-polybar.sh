#!/usr/bin/env bash
# Manual TTY recovery: swap init.lisp back to the no-polybar snapshot.
# Run this from a TTY (Ctrl-Alt-F3) if a fresh boot hangs the WM, then
# restart the X session from GDM.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT="$DIR/init.lisp"
FALLBACK="$DIR/init.lisp.no-polybar"
BACKUP="$DIR/init.lisp.bak-$(date +%Y%m%d-%H%M%S)"

if [[ ! -f "$FALLBACK" ]]; then
  echo "error: $FALLBACK not found — no fallback to restore from" >&2
  exit 1
fi

cp -p "$INIT" "$BACKUP"
echo "backed up: $BACKUP"

cp "$FALLBACK" "$INIT"
echo "restored:  $FALLBACK -> $INIT"
echo
echo "Next: restart X (logout + log back in via GDM), or 'pkill stumpwm'."
