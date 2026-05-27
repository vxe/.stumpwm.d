.PHONY: help install test run-stdin run-http panic smoke-scsynth analyze clean

VENV   := venv
PY     := $(VENV)/bin/python
PYTEST := $(VENV)/bin/pytest
UV     := $(HOME)/.local/bin/uv

help:           ## show this help
	@echo "voice-controlled-synth — targets:"
	@sed -nE 's/^([a-zA-Z_-]+):.*## (.*)/  \1\t\2/p' $(MAKEFILE_LIST)

install:        ## create venv + install deps
	$(UV) venv $(VENV)
	$(UV) pip install --python ./$(PY) -e .[dev]

test:           ## run offline unit tests (no SDK, no scsynth)
	$(PYTEST) -v tests/

run-stdin:      ## start the daemon in stdin mode (one prompt per line)
	$(PY) -m voice_controlled_synth

run-http:       ## start the daemon on http://127.0.0.1:8765
	$(PY) -m voice_controlled_synth --http 8765

panic:          ## /g_freeAll scsynth on port 57110
	./panic.sh

smoke-scsynth:  ## boot scsynth + supriya + 0.3s tone (produces audio!)
	$(PY) tools/smoke_scsynth.py

smoke-scsynth-connect: ## connect to existing scsynth (e.g. cl-collider's) and play a tone
	$(PY) tools/smoke_scsynth.py --connect-only

analyze:        ## summarise the JSONL eval log
	$(PY) tools/analyze_eval_log.py

analyze-errors: ## dump every failed eval verbatim (issue-report material)
	$(PY) tools/analyze_eval_log.py --errors-only

clean:          ## remove venv + caches
	rm -rf $(VENV) .pytest_cache **/__pycache__ *.egg-info
