#!/usr/bin/env python3
"""smoke_scsynth.py — boot scsynth, connect supriya, play 0.3s tone, cleanup.

The morning-side verification for Value Prop #5: "music inside the WM,
not beside it" — proves that supriya from this venv can drive scsynth
the same way cl-collider does.

Why this is NOT run overnight: it produces audio. Run by hand after
waking up.

Usage:
    ./venv/bin/python tools/smoke_scsynth.py             # default port 57110, -l 4
    ./venv/bin/python tools/smoke_scsynth.py --port 57111 --amp 0.05
"""

import argparse
import asyncio
import shutil
import subprocess
import sys
import time
from pathlib import Path


def parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=57110)
    ap.add_argument("--logins", type=int, default=4,
                    help="scsynth -l max-logins (1=single client, 4=room for cl-collider + supriya)")
    ap.add_argument("--amp", type=float, default=0.05,
                    help="output amplitude for the test tone (default low)")
    ap.add_argument("--duration", type=float, default=0.3,
                    help="test tone duration in seconds")
    ap.add_argument("--connect-only", action="store_true",
                    help="connect to existing scsynth instead of booting one")
    return ap.parse_args()


def main():
    args = parse_args()

    scsynth = shutil.which("scsynth")
    if scsynth is None:
        print("ERROR: scsynth not on PATH. Install with: sudo apt install supercollider-server", file=sys.stderr)
        return 2

    # ── 1. boot or connect ───────────────────────────────────────────
    sc_proc = None
    if not args.connect_only:
        print(f"[smoke] booting scsynth -u {args.port} -l {args.logins} ...", flush=True)
        sc_proc = subprocess.Popen(
            [scsynth, "-u", str(args.port), "-l", str(args.logins)],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        # give scsynth time to bind the port
        time.sleep(0.6)
        if sc_proc.poll() is not None:
            out = sc_proc.stdout.read().decode(errors="replace") if sc_proc.stdout else ""
            print(f"ERROR: scsynth exited immediately. Output:\n{out}", file=sys.stderr)
            return 3
        print(f"[smoke] scsynth pid={sc_proc.pid}")

    try:
        # ── 2. raw OSC /status check ─────────────────────────────────
        from pythonosc.udp_client import SimpleUDPClient
        client = SimpleUDPClient("127.0.0.1", args.port)
        client.send_message("/status", [])
        print(f"[smoke] /status sent to :{args.port}")

        # ── 3. supriya connect ───────────────────────────────────────
        import supriya
        server = supriya.Server()
        if args.connect_only:
            server.connect(port=args.port)
        else:
            server.connect(port=args.port)
        print(f"[smoke] supriya connected: {server}")

        # ── 4. play a brief tone ─────────────────────────────────────
        # Use raw OSC: avoid supriya synthdef compilation overhead for this smoke.
        # /s_new <defName> <nodeID> <addAction> <addTargetID> [name value ...]
        # SuperCollider has a default 'default' synthdef; pass freq + amp.
        node_id = 9999
        client.send_message("/s_new", [
            "default",
            node_id,
            0,        # add to head
            1,        # group 1 (default)
            "freq", 440.0,
            "amp", float(args.amp),
        ])
        print(f"[smoke] /s_new sent (freq=440, amp={args.amp})")
        time.sleep(args.duration)

        # ── 5. cleanup ───────────────────────────────────────────────
        client.send_message("/n_free", [node_id])
        client.send_message("/g_freeAll", [0])
        print("[smoke] freed node + group")

        # supriya disconnect
        try:
            server.disconnect()
        except Exception as e:
            print(f"[smoke] disconnect warning: {e}", file=sys.stderr)

        print("[smoke] OK")
        return 0

    finally:
        if sc_proc is not None:
            print(f"[smoke] killing scsynth pid={sc_proc.pid}")
            sc_proc.terminate()
            try:
                sc_proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                sc_proc.kill()


if __name__ == "__main__":
    sys.exit(main())
