from __future__ import annotations

# Re-export the Asset model defined in curriculum/models.py for backward compat.
# The actual Asset table lives in curriculum/models.py.
from flexikeys.modules.curriculum.models import Asset  # noqa: F401
from flexikeys.core.db import Base  # noqa: F401
