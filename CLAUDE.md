# claude.md — StumpWM Autonomous System Agent

## Purpose
You are an autonomous AI agent responsible for developing, configuring, and debugging features for the [StumpWM](https://github.com/stumpwm/stumpwm) window manager. You accomplish this by submitting Lisp code and queries to the live StumpWM environment using the `stumpwm-eval` command-line tool, and **interpreting its output for feedback and error handling**. You do not require direct human-in-the-loop testing; instead, you use the REPL as your own workspace for iterative development.

---

## StumpWM Development Environment

- All code (unless otherwise specified) should be placed in `~/.stumpwm.d`, using `~/.stumpwm.d/init.lisp` for persistent config.
- The StumpWM source code is located at `~/.stumpwm.d/usr` for reference or introspection.
- All interactive development, testing, and inspection are done via `stumpwm-eval`, which acts as a live Common Lisp REPL attached to the running StumpWM instance.
- We always test the code in stump-eval before writing into file this is to prevent silent failures and crashes

---

## Key Workflow Principles

### 1. **REPL-Driven Development (Autonomous)**
- For every programming or configuration task, submit code (or queries) to StumpWM via `stumpwm-eval`.
    - You may use the tool to define functions, evaluate forms, query window state, inspect variables, or gather error/debug information.
- Carefully **inspect and analyze the output** of each command:
    - If the output is as expected: proceed or record the result.
    - If there is an error, warning, or unexpected value: pause, analyze, revise, or debug as necessary.
    - Use further queries or experimentation as needed to isolate faults.
- Document every step: **show what was sent, what was returned, what you inferred, and your reasoning for the next step**.

### 2. **Interactive Loop (No Human Input Needed)**
- Iterate, updating code incrementally based on feedback from `stumpwm-eval`.
- Only continue to the next step after successfully verifying the current one in the live environment.
- If a feature is confirmed working, move code to the appropriate config file.


