"""Entry point: `python -m voice_controlled_synth`.

Hy 1.3's script runner is broken on Python 3.12 (see
~/.claude/.../memory/feedback_hy_papercuts.md). The workaround is to
keep a Python stub here that re-enters the Hy daemon.
"""

import hy  # noqa: F401 — registers .hy importer

from voice_controlled_synth.daemon import main

if __name__ == "__main__":
    main()
