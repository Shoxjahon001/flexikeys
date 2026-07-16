"""
Deterministic adaptation policy.

Interface
---------
    apply(profile, metrics, mastery, last_changes, session_id)
        -> (new_profile, list[PolicyChange])

This is a **pure function**: no I/O, no randomness, identical inputs
always produce identical outputs.  All numeric rules are bounded and
gradual; max step per call is shown in each constant below.

Hysteresis
----------
last_changes: dict[param_key, {"direction": +1/-1, "session_id": str}]
A change that opposes the direction of the *previous session's* change
on the same param is blocked.  Same-session changes are always allowed
(the engine may call apply() multiple times within one session).

How to swap in an ML model
--------------------------
Replace the rule table in `apply()` with a call to your model, keeping
the same return signature.  The audit log, repository, and profile
delivery are upstream of this function and do not change.
"""
from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass
from typing import Any

from flexikeys.modules.adaptive.metrics import (
    ACCIDENTAL_TAP_THRESHOLD,
    HESITATION_THRESHOLD_MS,
    TOUCH_OFFSET_THRESHOLD,
)

# ── Rule bounds & step sizes ──────────────────────────────────────────────────

ACCURACY_LOW: float = 0.60
ACCURACY_HIGH: float = 0.85
KEY_SCALE_STEP: float = 0.05
KEY_SCALE_PER_KEY_MAX: float = 1.50
KEY_SCALE_GLOBAL_MAX: float = 1.40
KEY_SCALE_MIN: float = 1.00
KEY_SPACING_STEP: float = 0.05
KEY_SPACING_MAX: float = 1.60
KEY_SPACING_MIN: float = 1.00
DWELL_STEP_MS: int = 20
DWELL_MAX_MS: int = 300
DWELL_MIN_MS: int = 0
HINT_MAX: int = 3
HINT_MIN: int = 0
HINT_DECAY_MASTERY_THRESHOLD: float = 0.90

# Explanation keys map 1-to-1 to parent-facing localised strings in the l10n catalogue.
# Format:  "reason.param_direction"
_EXPL = {
    "scale_up": "adaptation.key_scale_up",
    "scale_down": "adaptation.key_scale_down",
    "dwell_up": "adaptation.dwell_time_up",
    "spacing_up": "adaptation.key_spacing_up",
    "global_scale_up": "adaptation.global_scale_up",
    "hint_up": "adaptation.hint_level_up",
    "hint_down": "adaptation.hint_level_down",
    "break": "adaptation.break_suggested",
}


# ── Data types ────────────────────────────────────────────────────────────────


@dataclass
class PolicyChange:
    param: str
    old_value: Any
    new_value: Any
    reason_code: str      # one of AdaptationReasonCode values
    explanation_key: str  # localisation key


def default_profile() -> dict[str, Any]:
    """Return an empty adaptation profile with safe defaults."""
    return {
        "key_scale": 1.0,
        "key_scale_per_key": {},
        "key_spacing": 1.0,
        "dwell_time_ms": 0,
        "debounce_ms": 50,
        "hint_level": {},
        "session_pacing": {"suggest_break": False},
        "progression_gate": True,
        "version": 1,
    }


# ── Helper utilities ──────────────────────────────────────────────────────────


def _clamp(value: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, value))


def _r2(v: float) -> float:
    return round(v, 2)


# ── Main policy function ──────────────────────────────────────────────────────


def apply(
    profile: dict[str, Any],
    metrics: dict[str, Any],
    mastery: dict[str, float],
    last_changes: dict[str, dict[str, Any]] | None = None,
    session_id: str | None = None,
) -> tuple[dict[str, Any], list[PolicyChange]]:
    """
    Compute the next adaptation profile and the list of changes made.

    Parameters
    ----------
    profile:
        Current AdaptationProfile.params dict (from DB).
    metrics:
        Output of compute_session_metrics(), optionally with
        metrics["per_skill"][skill_key] populated by compute_per_skill_metrics().
    mastery:
        {skill_key: p_known float} for every skill seen this session.
    last_changes:
        Hysteresis state; mutated in place by this function and
        should be persisted by the caller between sessions.
    session_id:
        String identifier for the current session (for hysteresis).

    Returns
    -------
    (new_profile, list[PolicyChange]) — changes is empty when nothing moved.
    """
    new_profile = deepcopy(profile)
    new_profile.setdefault("key_scale_per_key", {})
    new_profile.setdefault("hint_level", {})
    new_profile.setdefault("session_pacing", {"suggest_break": False})
    new_profile.setdefault("key_scale", 1.0)
    new_profile.setdefault("key_spacing", 1.0)
    new_profile.setdefault("dwell_time_ms", 0)
    new_profile.setdefault("version", 1)

    changes: list[PolicyChange] = []
    last: dict[str, dict[str, Any]] = last_changes if last_changes is not None else {}

    def _can_change(param: str, direction: int) -> bool:
        """Hysteresis gate: block opposite-direction change from a prior session."""
        prev = last.get(param)
        if prev is None:
            return True
        # Same session — always allow (engine may call multiple times)
        if session_id is not None and prev.get("session_id") == session_id:
            return True
        # Different session — block opposite direction
        return prev.get("direction", 0) != -direction

    def _record(
        param: str,
        old: Any,
        new: Any,
        reason: str,
        expl: str,
        direction: int,
    ) -> None:
        if old == new:
            return
        changes.append(PolicyChange(param, old, new, reason, expl))
        last[param] = {"direction": direction, "session_id": session_id}

    # ── Per-skill accuracy → key_scale_per_key ────────────────────────────────
    per_skill: dict[str, dict[str, Any]] = metrics.get("per_skill", {})
    for skill_key, sm in per_skill.items():
        acc = sm.get("ewma_accuracy")
        param_k = f"key_scale.{skill_key}"
        current_scale = float(new_profile["key_scale_per_key"].get(skill_key, 1.0))

        if acc is not None:
            if acc < ACCURACY_LOW and _can_change(param_k, +1):
                new_scale = _r2(_clamp(current_scale + KEY_SCALE_STEP, KEY_SCALE_MIN, KEY_SCALE_PER_KEY_MAX))
                _record(param_k, current_scale, new_scale, "accuracy_drop", _EXPL["scale_up"], +1)
                new_profile["key_scale_per_key"][skill_key] = new_scale
                current_scale = new_scale

            elif acc >= ACCURACY_HIGH and current_scale > KEY_SCALE_MIN and _can_change(param_k, -1):
                new_scale = _r2(_clamp(current_scale - KEY_SCALE_STEP, KEY_SCALE_MIN, KEY_SCALE_PER_KEY_MAX))
                _record(param_k, current_scale, new_scale, "mastery_gain", _EXPL["scale_down"], -1)
                new_profile["key_scale_per_key"][skill_key] = new_scale

        # Hesitation → hint_level up
        hesitation = sm.get("hesitation_ms")
        param_h = f"hint_level.{skill_key}"
        cur_hint = int(new_profile["hint_level"].get(skill_key, 0))
        if (
            hesitation is not None
            and hesitation > HESITATION_THRESHOLD_MS
            and cur_hint < HINT_MAX
            and _can_change(param_h, +1)
        ):
            new_hint = cur_hint + 1
            _record(param_h, cur_hint, new_hint, "latency_rise", _EXPL["hint_up"], +1)
            new_profile["hint_level"][skill_key] = new_hint
            cur_hint = new_hint

        # Mastery → hint decay
        p_known = mastery.get(skill_key, 0.0)
        if p_known >= HINT_DECAY_MASTERY_THRESHOLD and cur_hint > HINT_MIN and _can_change(param_h, -1):
            new_hint = max(HINT_MIN, cur_hint - 1)
            _record(param_h, cur_hint, new_hint, "mastery_gain", _EXPL["hint_down"], -1)
            new_profile["hint_level"][skill_key] = new_hint

    # ── Accidental taps → dwell_time_ms + key_spacing ────────────────────────
    acc_tap = metrics.get("accidental_tap_rate")
    if acc_tap is not None and acc_tap > ACCIDENTAL_TAP_THRESHOLD:
        old_dwell = int(new_profile.get("dwell_time_ms", 0))
        new_dwell = int(_clamp(old_dwell + DWELL_STEP_MS, DWELL_MIN_MS, DWELL_MAX_MS))
        if _can_change("dwell_time_ms", +1):
            _record("dwell_time_ms", old_dwell, new_dwell, "accidental_taps", _EXPL["dwell_up"], +1)
            new_profile["dwell_time_ms"] = new_dwell

        old_spacing = float(new_profile.get("key_spacing", 1.0))
        new_spacing = _r2(_clamp(old_spacing + KEY_SPACING_STEP, KEY_SPACING_MIN, KEY_SPACING_MAX))
        if _can_change("key_spacing", +1):
            _record("key_spacing", old_spacing, new_spacing, "accidental_taps", _EXPL["spacing_up"], +1)
            new_profile["key_spacing"] = new_spacing

    # ── Touch precision → global key_scale ───────────────────────────────────
    precision = metrics.get("touch_precision")
    if precision is not None and precision > TOUCH_OFFSET_THRESHOLD:
        old_scale = float(new_profile.get("key_scale", 1.0))
        new_scale = _r2(_clamp(old_scale + KEY_SCALE_STEP, KEY_SCALE_MIN, KEY_SCALE_GLOBAL_MAX))
        if _can_change("key_scale", +1):
            _record("key_scale", old_scale, new_scale, "accuracy_drop", _EXPL["global_scale_up"], +1)
            new_profile["key_scale"] = new_scale

    # ── Fatigue → suggest break ───────────────────────────────────────────────
    pacing = dict(new_profile.get("session_pacing", {}))
    if metrics.get("fatigued", False):
        if not pacing.get("suggest_break", False):
            pacing["suggest_break"] = True
            new_profile["session_pacing"] = pacing
            changes.append(PolicyChange(
                "session_pacing.suggest_break",
                False, True,
                "fatigue", _EXPL["break"],
            ))
    else:
        if pacing.get("suggest_break", False):
            pacing["suggest_break"] = False
            new_profile["session_pacing"] = pacing

    # ── Version bump ──────────────────────────────────────────────────────────
    if changes:
        new_profile["version"] = int(new_profile.get("version", 1)) + 1

    return new_profile, changes
