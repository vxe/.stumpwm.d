#!/usr/bin/env python3
"""analyze_eval_log.py — turn the JSONL eval log into research output.

Reads ~/.local/share/voice-controlled-synth/eval-log.jsonl (or a path
you pass) and prints a summary suitable for:

  - blog post material ("things Claude tried that Hy 1.3 didn't like")
  - upstream Hy bug reports (each failure has code + version + traceback)

This is the load-bearing artifact for Value Proposition #4 — friction
as research output. Every wasted turn becomes a row in the dataset.

Usage:
    ./venv/bin/python tools/analyze_eval_log.py
    ./venv/bin/python tools/analyze_eval_log.py path/to/eval-log.jsonl
    ./venv/bin/python tools/analyze_eval_log.py --session 3c67181b...
    ./venv/bin/python tools/analyze_eval_log.py --errors-only
"""

import argparse
import json
import pathlib
import re
import statistics
import sys
from collections import Counter, defaultdict

DEFAULT_PATH = pathlib.Path.home() / ".local/share/voice-controlled-synth/eval-log.jsonl"


def load(path):
    if not path.exists():
        print(f"analyze: log not found at {path}", file=sys.stderr)
        print("  run the daemon first (make run-stdin) to populate it.", file=sys.stderr)
        sys.exit(1)
    rows = []
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError as e:
            print(f"analyze: skipped bad line: {e}", file=sys.stderr)
    return rows


def extract_error_class(traceback_str):
    """Pull the exception class name from a traceback string."""
    if not traceback_str:
        return None
    # First line is usually "ClassName: message"
    first_line = traceback_str.split("\n", 1)[0]
    m = re.match(r"^([A-Za-z_][A-Za-z0-9_.]*)", first_line)
    return m.group(1) if m else "Unknown"


def summarise(rows):
    total = len(rows)
    if total == 0:
        print("analyze: empty log.")
        return
    ok = sum(1 for r in rows if r.get("ok"))
    rate = ok / total

    print(f"# voice-controlled-synth eval log")
    print(f"  rows: {total}")
    print(f"  ok: {ok}  ({rate:.1%})")
    print(f"  fail: {total - ok}")
    print()

    # Sessions
    by_sess = defaultdict(list)
    for r in rows:
        by_sess[r.get("session_id", "?")].append(r)
    print(f"  sessions: {len(by_sess)}")
    print(f"  longest session: {max(len(v) for v in by_sess.values())} turns")
    print()

    # Versions seen
    hy_versions = Counter(r.get("hy_version") for r in rows)
    py_versions = Counter(r.get("py_version") for r in rows)
    print(f"  hy_versions: {dict(hy_versions)}")
    print(f"  py_versions: {dict(py_versions)}")
    print()

    # Latency
    lats = [r.get("latency_ms") for r in rows if r.get("latency_ms")]
    if lats:
        print(f"  latency_ms  p50={statistics.median(lats):.1f}  "
              f"p95={sorted(lats)[int(len(lats) * 0.95)]:.1f}  "
              f"max={max(lats):.1f}")
        print()

    # Errors by class
    errs = [extract_error_class(r["error"]) for r in rows if not r.get("ok") and r.get("error")]
    if errs:
        print("## error classes (ranked)")
        for cls, n in Counter(errs).most_common():
            print(f"  {n:4d}  {cls}")
        print()

    # Top error messages (first 80 chars of the first line)
    err_msgs = []
    for r in rows:
        if r.get("ok"):
            continue
        if not r.get("error"):
            continue
        first = r["error"].split("\n", 1)[0]
        err_msgs.append(first[:120])
    if err_msgs:
        print("## error first-lines (ranked)")
        for line, n in Counter(err_msgs).most_common(10):
            print(f"  {n:4d}  {line}")
        print()


def dump_errors(rows):
    """Print each failed eval verbatim — drop-in material for Hy issues."""
    for r in rows:
        if r.get("ok"):
            continue
        print("─" * 72)
        print(f"# {r.get('ts')} session={r.get('session_id')} turn={r.get('session_turn')}")
        print(f"# hy={r.get('hy_version')} py={r.get('py_version')} latency_ms={r.get('latency_ms'):.2f}")
        print("## code")
        print(r.get("code"))
        print("## error")
        print(r.get("error"))
        print()


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("path", nargs="?", type=pathlib.Path, default=DEFAULT_PATH)
    ap.add_argument("--session", help="filter to one session_id")
    ap.add_argument("--errors-only", action="store_true",
                    help="print each failure with its code + traceback (issue-report material)")
    args = ap.parse_args()

    rows = load(args.path)
    if args.session:
        rows = [r for r in rows if r.get("session_id") == args.session]
        if not rows:
            print(f"analyze: no rows for session_id={args.session}", file=sys.stderr)
            sys.exit(1)

    if args.errors_only:
        dump_errors(rows)
    else:
        summarise(rows)


if __name__ == "__main__":
    main()
