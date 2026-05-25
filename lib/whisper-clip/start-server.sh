#!/usr/bin/env bash
# Start the whisper.cpp HTTP server (keeps model warm in RAM).
# Logs to /tmp/whisper-server.log; runs in background.
# Called by StumpWM init — safe to call multiple times (pgrep guard).

WHISPER_BIN="${HOME}/.local/bin/whisper-server"
MODEL="${HOME}/.local/share/whisper/ggml-tiny.en.bin"

if ! command -v "$WHISPER_BIN" &>/dev/null; then
    echo "whisper-server not found at $WHISPER_BIN — run install.sh first" >&2
    exit 1
fi

if [ ! -f "$MODEL" ]; then
    echo "Model not found at $MODEL — run install.sh first" >&2
    exit 1
fi

exec "$WHISPER_BIN" \
    --model   "$MODEL" \
    --host    127.0.0.1 \
    --port    8080 \
    --language en \
    --threads "$(nproc)" \
    --inference-path /inference
