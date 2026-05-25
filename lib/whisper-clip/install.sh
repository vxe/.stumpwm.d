#!/usr/bin/env bash
# One-time setup for whisper-clip:
#   1. Install system packages (alsa-utils, curl, xclip, build tools)
#   2. Build whisper.cpp (server + CLI binaries)
#   3. Download ggml-tiny.en model
#
# Run once, then reload StumpWM config.

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
MODEL_DIR="${HOME}/.local/share/whisper"

echo "=== whisper-clip install ==="

# ── 1. System packages ────────────────────────────────────────────────────────
echo "→ Installing system packages…"
sudo apt-get install -y \
    build-essential cmake git \
    alsa-utils curl xclip wget

# ── 2. Build whisper.cpp ──────────────────────────────────────────────────────
echo "→ Cloning and building whisper.cpp…"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

git clone --depth 1 https://github.com/ggerganov/whisper.cpp "$TMPDIR/whisper.cpp"
cd "$TMPDIR/whisper.cpp"

cmake -B build \
    -DWHISPER_BUILD_SERVER=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++"
cmake --build build --config Release -j"$(nproc)"

mkdir -p "$BIN_DIR"
install -m755 build/bin/whisper-server "$BIN_DIR/whisper-server"
# CLI binary name varies by whisper.cpp version
for bin in build/bin/whisper-cli build/bin/main; do
    [ -f "$bin" ] && install -m755 "$bin" "$BIN_DIR/whisper-cli" && break
done

echo "  whisper-server → $BIN_DIR/whisper-server"

# ── 3. Download tiny.en model ─────────────────────────────────────────────────
echo "→ Downloading ggml-tiny.en model (~75 MB)…"
mkdir -p "$MODEL_DIR"
wget -q --show-progress \
    -O "$MODEL_DIR/ggml-tiny.en.bin" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin"

echo ""
echo "=== Done! ==="
echo ""
echo "Next steps:"
echo "  1. Reload StumpWM config:  stumpwm-eval '(load \"/home/\$USER/.stumpwm.d/init.lisp\")'"
echo "  2. Press H-r to start recording, H-r again to stop + transcribe."
echo ""
echo "Server log: /tmp/whisper-server.log"
