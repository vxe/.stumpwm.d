"""Offline tests — no Claude SDK calls, no scsynth required.

The intent is to verify the eval-loop infrastructure independently
of the live agent. The two-turn rapport test (Value Prop #2) is also
exercised here at the unit-level via tools.eval_hy_impl directly —
the live SDK version lives in tests/test_live_rapport.py and is run
separately because it costs money.
"""

import json
import pathlib
import tempfile

import pytest

import voice_controlled_synth  # noqa: F401 — registers hy importer
from voice_controlled_synth import tools, world
from voice_controlled_synth.eval_log import EvalLog


@pytest.fixture
def tmp_log(tmp_path):
    return EvalLog(tmp_path / "log.jsonl")


def test_eval_log_writes_jsonl(tmp_log):
    rec = tmp_log.record("(+ 1 2)", True, "3", "", "", None, 1.5)
    lines = tmp_log.path.read_text().strip().split("\n")
    assert len(lines) == 1
    parsed = json.loads(lines[0])
    assert parsed["code"] == "(+ 1 2)"
    assert parsed["ok"] is True
    assert parsed["session_turn"] == 1
    assert parsed["hy_version"] == "1.3.0"
    assert parsed["session_id"] == tmp_log.session_id


def test_eval_log_increments_turn(tmp_log):
    tmp_log.record("a", True, "1", "", "", None, 0)
    tmp_log.record("b", True, "2", "", "", None, 0)
    rows = [json.loads(l) for l in tmp_log.path.read_text().splitlines()]
    assert [r["session_turn"] for r in rows] == [1, 2]


def test_eval_hy_arithmetic():
    r = tools.eval_hy_impl("(+ 1 2)")
    assert r["ok"] is True
    assert r["value"] == "3"
    assert r["stdout"] == ""
    assert r["error"] is None


def test_eval_hy_error_path():
    r = tools.eval_hy_impl("(/ 1 0)")
    assert r["ok"] is False
    assert r["value"] is None
    assert "ZeroDivisionError" in r["error"]


def test_eval_hy_unbalanced_parens():
    r = tools.eval_hy_impl("(+ 1 2")
    assert r["ok"] is False
    assert r["error"] is not None


def test_eval_hy_stdout_capture():
    r = tools.eval_hy_impl('(print "hello from inside eval")')
    assert r["ok"] is True
    assert "hello from inside eval" in r["stdout"]


def test_world_state_persists_across_evals():
    """The load-bearing demonstration of Value Prop #2 at unit-level."""
    name = "rapport_test_42"
    # Clean any previous run
    if hasattr(world, name):
        delattr(world, name)
    # Turn 1: define
    r1 = tools.eval_hy_impl(f"(setv {name.replace('_', '-')} 123)")
    assert r1["ok"], r1["error"]
    assert getattr(world, name) == 123
    # Turn 2: use the defined value
    r2 = tools.eval_hy_impl(f"(* {name.replace('_', '-')} 2)")
    assert r2["ok"], r2["error"]
    assert r2["value"] == "246"
    # cleanup so subsequent test runs are fresh
    delattr(world, name)


def test_state_dump_shape():
    s = tools.state_dump_impl()
    assert "defined_names" in s
    assert "bpm" in s
    assert "server_connected" in s
    assert "default_port" in s
    assert s["default_port"] == 57110
    assert s["server_connected"] is False  # we never connected in this test
    # Preloaded helpers should appear
    assert "note_to_hz" in s["defined_names"]
    assert "connect_server" in s["defined_names"]


def test_build_server_returns_mcp_config(tmp_log):
    srv = tools.build_server(tmp_log)
    assert srv["type"] == "sdk"
    assert srv["name"] == "vcs"
    assert srv["instance"] is not None


def test_world_note_to_hz():
    assert abs(world.note_to_hz(69) - 440.0) < 0.001  # A4
    assert abs(world.note_to_hz(60) - 261.625) < 0.01  # C4


def test_daemon_module_loads():
    from voice_controlled_synth import daemon
    assert daemon.read_primer().startswith("# Hy 1.3 primer")
    assert callable(daemon.build_options)
