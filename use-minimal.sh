#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT="$DIR/init.lisp"
MINIMAL="$DIR/minimal.lisp"
BACKUP="$DIR/init.lisp.bak-$(date +%Y%m%d-%H%M%S)"

if [[ ! -f "$MINIMAL" ]]; then
  echo "error: $MINIMAL not found" >&2
  exit 1
fi

if [[ -f "$INIT" ]]; then
  cp -p "$INIT" "$BACKUP"
  echo "backed up: $BACKUP"
else
  echo "note: no existing $INIT to back up"
fi

cp "$MINIMAL" "$INIT"
echo "copied:   $MINIMAL -> $INIT"
