"""voice_controlled_synth — daemon scaffolding.

Importing this package registers the Hy importer so that sibling .hy
modules can be imported as regular Python submodules.
"""

import hy  # noqa: F401 — side effect: registers .hy importer
