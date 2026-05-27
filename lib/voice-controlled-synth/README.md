# voice-controlled-synth

Voice-driven Claude session that **live-codes music in Hy** against a
shared `scsynth` server. Conventional music tooling gives you menus of
preset capabilities; this gives you a musician who writes code on the
spot in response to spoken intent, accumulating state and idioms over
a session.

See `~/Documents/rfcs/voice-controlled-synth.md` for the full RFC.

## Value propositions this prototype demonstrates

1. **Voice as natural-language compiler** — `voice-capture.sh` records,
   transcribes via whisper.cpp, posts to the daemon. The daemon evals
   real Hy code in response, not preset parameters.
2. **Stateful live-coding rapport** — definitions in turn N survive to
   turn N+1. Demonstrated by the unit-test suite and by the overnight
   live SDK session whose log lives at
   `~/.local/share/voice-controlled-synth/eval-log.jsonl`.
3. **Lisp continuity end-to-end** — daemon written in Hy, the SDK is
   told (via `primer-hy.md`) that the model writes Hy too. The repo is
   under stumpwm config.
4. **Friction as research output** — every `eval_hy` call is logged
   to JSONL. `make analyze` summarises; `make analyze-errors` dumps
   each failure verbatim (drop-in material for upstream Hy issues).
5. **Music inside the WM, not beside it** — `make smoke-scsynth-connect`
   shows supriya driving the same scsynth that cl-collider drives from
   stumpwm.

## Quickstart

```bash
make install          # uv venv + install deps
make test             # 11 offline unit tests, no SDK/scsynth needed
make run-stdin        # interactive daemon (one prompt per line, Ctrl-D to exit)
```

Each prompt becomes a turn in one persistent Claude session — state
accumulates across turns.

## Morning verification (what to do when you read this)

These steps verify all five value props are realized. Pick the ones
you care about; nothing depends on running them in order.

### Prop 2: stateful rapport (already proved overnight)

```bash
make analyze
```

Expected: a `# voice-controlled-synth eval log` summary with at least
one session showing 2+ turns. If turn 2's `code` references a name
defined in turn 1, the prop is realized.

### Prop 1: voice → code (needs whisper.cpp running + a daemon)

```bash
# Terminal A: start the daemon on HTTP
make run-http

# Terminal B: confirm whisper.cpp server is up
pgrep -ax whisper-server   # should match the existing stumpwm one on :8080

# Terminal B: capture 4 seconds and route to daemon
./voice-capture.sh                                          # default 4s
VCS_DURATION=6 ./voice-capture.sh                           # longer
```

You should see the transcript on stderr and the daemon's reply (with
tool_uses showing `mcp__vcs__eval_hy` if Claude decided to evaluate
something) as JSON on stdout.

### Prop 4: friction as output

```bash
make analyze                # high-level summary
make analyze-errors         # each failure verbatim — ready to file as a Hy issue
```

### Prop 5: shared scsynth

```bash
# Boots a fresh scsynth -l 4, has supriya connect, plays 0.3s @ amp 0.05, cleans up.
# Don't run while another scsynth is already on :57110 (e.g. cl-collider booted one).
make smoke-scsynth

# If cl-collider has already booted scsynth, point at the existing one:
make smoke-scsynth-connect
```

Then in stumpwm: `H-m m` to boot cl-collider's session (if not already
running), `H-m n` to play a sine — both clients drive the same server.

### Panic

```bash
./panic.sh          # /g_freeAll 0 + /clearSched on :57110
./panic.sh 57111    # custom port
```

## Layout

```
lib/voice-controlled-synth/
├── README.md                         # ← you are here
├── Makefile                          # make help
├── pyproject.toml                    # uv-managed deps
├── primer-hy.md                      # system prompt fragment fed to the model
├── panic.sh                          # outside-the-agent safety net
├── voice-capture.sh                  # whisper → daemon route (prop 1)
├── tests/test_offline.py             # 11 tests; no SDK/scsynth
├── tools/smoke_scsynth.py            # prop 5 morning check
├── tools/analyze_eval_log.py         # prop 4 dataset → summary
└── voice_controlled_synth/
    ├── __init__.py                   # registers .hy importer
    ├── __main__.py                   # `python -m voice_controlled_synth` entry
    ├── daemon.hy                     # ClaudeSDKClient loop + stdin/http modes
    ├── tools.hy                      # eval_hy + state_dump @tool wrappers
    ├── world.hy                      # persistent globals Claude evals against
    └── eval_log.hy                   # JSONL logger
```

## Architecture in one paragraph

The daemon owns a single `ClaudeSDKClient`. Each prompt (from stdin or
HTTP) becomes `client.query(...)`. The model has exactly two tools:
`mcp__vcs__eval_hy(code)` and `mcp__vcs__state_dump()`. The eval tool
runs `hy.eval` against `voice_controlled_synth.world.__dict__` — that
module's `__dict__` IS the persistent globals. Every call appends a
record to `~/.local/share/voice-controlled-synth/eval-log.jsonl`.

Why this shape:
- **Module-as-namespace** gives state persistence for free. No
  bookkeeping; the model writes `(setv x 5)` and Python's import
  machinery keeps it alive.
- **Two tools, not twelve.** Anything the model wants to do — boot
  scsynth, define a synthdef, play a pattern — it writes as Hy. The
  RFC explicitly chose code-generation over a fixed verb set.
- **Hy in / Hy out.** The model's eval calls take Hy strings, and the
  primer tells it the local idioms (`:async`, no `#@`, `(. obj attr)`,
  etc.). Friction goes to the JSONL log.

## Wiring panic into stumpwm (deferred — touches init.lisp)

Not done in the overnight session because edits to `init.lisp` can
brick stumpwm. When you're at a keyboard with time to reload, add:

```lisp
;; ~/.stumpwm.d/init.lisp — somewhere in the H-m music map
(defcommand vcs-panic () ()
  "Free all synths on scsynth via the voice-controlled-synth panic script."
  (run-shell-command "~/.stumpwm.d/lib/voice-controlled-synth/panic.sh"))
(define-key *music-map* (kbd "k") "vcs-panic")
```

## Wiring voice-capture into stumpwm (deferred)

Same constraint. Once ready:

```lisp
(defcommand vcs-voice () ()
  "Record 4s, transcribe, route to voice-controlled-synth daemon."
  (run-shell-command "~/.stumpwm.d/lib/voice-controlled-synth/voice-capture.sh"))
(define-key *music-map* (kbd "v") "vcs-voice")
```

## Status

| Prop | Demonstrated? | Where |
|------|---------------|-------|
| 1 — voice → code | infrastructure ready, run `make run-http` + `./voice-capture.sh` | manual morning check |
| 2 — stateful rapport | yes, at unit-level AND in the overnight JSONL | `make test` + `make analyze` |
| 3 — Lisp continuity | yes — daemon is Hy, primer tells model to write Hy | inspection |
| 4 — friction-as-output | yes — JSONL exists, analyze script works | `make analyze` |
| 5 — music in WM | wiring complete, audio test is morning-only | `make smoke-scsynth-connect` |
