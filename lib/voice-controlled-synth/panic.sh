#!/usr/bin/env bash
# panic.sh — free every running synth on scsynth (Value Prop #5 safety net).
#
# Lives OUTSIDE the agent loop. If the agent gets stuck or scsynth is
# producing unwanted sound, run this to silence everything.
#
# Usage:
#   ./panic.sh              # default port 57110
#   ./panic.sh 57111        # custom port
#
# Bind to a stumpwm key (e.g. H-m k) once the wiring is set up — see
# README §"Wiring panic into stumpwm".
set -euo pipefail

PORT="${1:-57110}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PY="$DIR/venv/bin/python"

if [[ ! -x "$VENV_PY" ]]; then
  echo "panic: venv missing at $VENV_PY  (run 'make install' first)" >&2
  exit 2
fi

# python-osc-only path — does not touch supriya, no scsynth state assumptions.
"$VENV_PY" - "$PORT" <<'PY'
import sys
from pythonosc.udp_client import SimpleUDPClient
port = int(sys.argv[1])
c = SimpleUDPClient("127.0.0.1", port)
# /g_freeAll 0  —  free every node in the root group.
c.send_message("/g_freeAll", [0])
# /clearSched   —  drop any scheduled bundles.
c.send_message("/clearSched", [])
print(f"panic sent → 127.0.0.1:{port}", file=sys.stderr)
PY
