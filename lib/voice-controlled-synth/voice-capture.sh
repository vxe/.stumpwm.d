#!/usr/bin/env bash
# voice-capture.sh — record → whisper → POST to daemon (Value Prop #1).
#
# Standalone analog of whisper-clip, but routes the transcript to the
# voice-controlled-synth daemon's /say endpoint instead of typing it
# into the focused window. Does NOT modify whisper-clip or init.lisp;
# the user can bind this to any stumpwm key they like later.
#
# Defaults (override via env):
#   VCS_DURATION   recording length in seconds          (default: 4)
#   VCS_MIC        alsa device                           (default: hw:0,7 — matches whisper-clip)
#   VCS_DAEMON     base URL of the daemon                (default: http://127.0.0.1:8765)
#   VCS_WHISPER    whisper.cpp inference endpoint        (default: http://127.0.0.1:8080/inference)
#
# Usage:
#   ./voice-capture.sh             # record 4s, transcribe, send
#   VCS_DURATION=6 ./voice-capture.sh
#
# Exit codes:
#   0  success (transcript posted; daemon reply on stdout)
#   1  curl/arecord/jq error
#   2  daemon not reachable
#   3  whisper server not reachable
set -euo pipefail

DUR="${VCS_DURATION:-${1:-4}}"
MIC="${VCS_MIC:-hw:0,7}"
DAEMON="${VCS_DAEMON:-http://127.0.0.1:8765}"
WHISPER="${VCS_WHISPER:-http://127.0.0.1:8080/inference}"

WAV=$(mktemp --suffix=.wav)
trap "rm -f $WAV" EXIT

# Pre-flight: daemon health
if ! curl -sf --max-time 2 "$DAEMON/healthz" > /dev/null; then
  echo "voice-capture: daemon not reachable at $DAEMON/healthz" >&2
  echo "  start it first:  make run-http" >&2
  exit 2
fi

# Pre-flight: whisper server
if ! curl -sf --max-time 2 -o /dev/null "$WHISPER" 2>/dev/null; then
  # /inference returns 405 to GET, which curl -f rejects — try anyway.
  :  # don't hard-fail; we'll catch it on the real POST
fi

echo "voice-capture: recording ${DUR}s from $MIC ..." >&2
if ! arecord -q -D "$MIC" -f S16_LE -r 16000 -c 2 -t wav -d "$DUR" "$WAV"; then
  echo "voice-capture: arecord failed (mic=$MIC). Try a different device:" >&2
  echo "  arecord -l   # list devices" >&2
  exit 1
fi

echo "voice-capture: transcribing ..." >&2
TEXT=$(curl -sf --max-time 30 -X POST "$WHISPER" \
            -F "file=@$WAV" \
            -F "response_format=text" \
            | sed 's/[[:space:]]*$//')

if [[ -z "$TEXT" ]]; then
  echo "voice-capture: (nothing heard)" >&2
  exit 0
fi

echo "voice-capture: heard: $TEXT" >&2
echo "voice-capture: posting to daemon ..." >&2

PAYLOAD=$(jq -nc --arg text "$TEXT" '{text:$text}')

curl -sf --max-time 180 \
     -X POST "$DAEMON/say" \
     -H "Content-Type: application/json" \
     -d "$PAYLOAD" \
     | jq .
