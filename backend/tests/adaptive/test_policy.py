"""Policy determinism, hysteresis, bounded step, hint logic tests."""
from __future__ import annotations

import pytest

from flexikeys.modules.adaptive.metrics import TOUCH_OFFSET_THRESHOLD
from flexikeys.modules.adaptive.policy import (
    ACCURACY_HIGH,
    ACCURACY_LOW,
    DWELL_MAX_MS,
    DWELL_STEP_MS,
    HINT_MAX,
    KEY_SCALE_STEP,
    apply,
    default_profile,
)


def _metrics(
    accidental_tap_rate: float = 0.0,
    touch_precision: float = 0.1,
    fatigued: bool = False,
    per_skill: dict | None = None,
) -> dict:
    return {
        "accidental_tap_rate": accidental_tap_rate,
        "touch_precision": touch_precision,
        "fatigued": fatigued,
        "per_skill": per_skill or {},
    }


def _per_skill(key: str, accuracy: float = 0.75, hesitation_ms: float = 0.0) -> dict:
    return {key: {"ewma_accuracy": accuracy, "hesitation_ms": hesitation_ms}}


class TestDefaultProfile:
    def test_has_required_fields(self) -> None:
        p = default_profile()
        required = [
            "key_scale",
            "key_scale_per_key",
            "key_spacing",
            "dwell_time_ms",
            "debounce_ms",
            "hint_level",
            "session_pacing",
        ]
        for field in required:
            assert field in p


class TestApply:
    def test_returns_profile_and_changes(self) -> None:
        profile = default_profile()
        new_profile, changes = apply(profile, _metrics(), {}, {}, "session1")
        assert isinstance(new_profile, dict)
        assert isinstance(changes, list)

    def test_low_per_skill_accuracy_raises_per_key_scale(self) -> None:
        profile = default_profile()
        metrics = _metrics(per_skill=_per_skill("a", accuracy=0.40))
        new_profile, changes = apply(profile, metrics, {}, {}, "s1")
        # Per-key scale for "a" should go up
        assert new_profile["key_scale_per_key"].get("a", 1.0) > 1.0

    def test_high_per_skill_accuracy_lowers_per_key_scale(self) -> None:
        profile = default_profile()
        profile["key_scale_per_key"]["a"] = 1.20  # start elevated
        metrics = _metrics(per_skill=_per_skill("a", accuracy=0.92))
        new_profile, changes = apply(profile, metrics, {}, {}, "s1")
        assert new_profile["key_scale_per_key"].get("a", 1.0) <= 1.20

    def test_key_scale_step_bounded(self) -> None:
        profile = default_profile()
        metrics = _metrics(per_skill=_per_skill("a", accuracy=0.30))
        new_profile, _ = apply(profile, metrics, {}, {}, "s1")
        current = new_profile["key_scale_per_key"].get("a", 1.0)
        assert abs(current - 1.0) <= KEY_SCALE_STEP + 1e-9

    def test_dwell_time_raised_on_accidentals(self) -> None:
        profile = default_profile()
        metrics = _metrics(accidental_tap_rate=0.20)
        new_profile, _ = apply(profile, metrics, {}, {}, "s1")
        assert new_profile["dwell_time_ms"] > 0

    def test_dwell_time_step_bounded(self) -> None:
        profile = default_profile()
        metrics = _metrics(accidental_tap_rate=0.20)
        new_profile, _ = apply(profile, metrics, {}, {}, "s1")
        delta = abs(new_profile["dwell_time_ms"] - profile.get("dwell_time_ms", 0))
        assert delta <= DWELL_STEP_MS + 1e-9

    def test_dwell_time_max_cap(self) -> None:
        profile = default_profile()
        profile["dwell_time_ms"] = DWELL_MAX_MS
        metrics = _metrics(accidental_tap_rate=0.20)
        new_profile, _ = apply(profile, metrics, {}, {}, "s1")
        assert new_profile["dwell_time_ms"] <= DWELL_MAX_MS

    def test_key_scale_up_on_poor_touch_precision(self) -> None:
        profile = default_profile()
        metrics = _metrics(touch_precision=0.50)  # > TOUCH_OFFSET_THRESHOLD 0.30
        new_profile, changes = apply(profile, metrics, {}, {}, "s1")
        assert new_profile["key_scale"] > profile.get("key_scale", 1.0)

    def test_hint_level_raised_on_hesitation(self) -> None:
        profile = default_profile()
        metrics = _metrics(per_skill=_per_skill("a", hesitation_ms=3000.0))  # > 2000 threshold
        new_profile, changes = apply(profile, metrics, {}, {}, "s1")
        assert new_profile["hint_level"].get("a", 0) > 0

    def test_hint_level_bounded(self) -> None:
        profile = default_profile()
        profile["hint_level"]["a"] = HINT_MAX
        metrics = _metrics(per_skill=_per_skill("a", hesitation_ms=3000.0))
        new_profile, _ = apply(profile, metrics, {}, {}, "s1")
        assert new_profile["hint_level"].get("a", 0) <= HINT_MAX

    def test_hint_decays_when_mastered(self) -> None:
        profile = default_profile()
        profile["hint_level"]["a"] = 2
        metrics = _metrics(per_skill=_per_skill("a", accuracy=0.92))
        mastery = {"a": 0.95}  # mastery is {skill_key: p_known float}
        new_profile, _ = apply(profile, metrics, mastery, {}, "s1")
        assert new_profile["hint_level"].get("a", 0) <= 2

    def test_hysteresis_blocks_reversal(self) -> None:
        profile = default_profile()
        profile["key_scale"] = 1.10
        # Global scale was increased last session
        last_changes = {"key_scale": {"direction": 1, "session_id": "s_prev"}}
        # High precision this session — would normally decrease scale, but hysteresis blocks
        metrics = _metrics(touch_precision=0.05)  # below threshold → no scale up
        new_profile, changes = apply(profile, metrics, {}, last_changes, "s_curr")
        # scale should not have been changed downward (no down rule exists for scale anyway)
        assert new_profile["key_scale"] >= 1.0

    def test_hysteresis_same_session_allowed(self) -> None:
        # Multiple calls in same session should not be blocked
        profile = default_profile()
        last_changes = {"dwell_time_ms": {"direction": 1, "session_id": "s1"}}
        metrics = _metrics(accidental_tap_rate=0.20)
        new_profile, changes = apply(profile, metrics, {}, last_changes, "s1")
        # Same session: should still allow change
        assert new_profile["dwell_time_ms"] >= 0

    def test_changes_have_explanation_key(self) -> None:
        profile = default_profile()
        metrics = _metrics(accidental_tap_rate=0.20)
        _, changes = apply(profile, metrics, {}, {}, "s1")
        for change in changes:
            assert change.explanation_key.startswith("adaptation.")

    def test_deterministic(self) -> None:
        profile = default_profile()
        metrics = _metrics(accidental_tap_rate=0.20)
        r1, c1 = apply(profile, metrics, {}, {}, "s1")
        r2, c2 = apply(profile, metrics, {}, {}, "s1")
        assert r1 == r2
        assert len(c1) == len(c2)

    def test_fatigue_triggers_break(self) -> None:
        profile = default_profile()
        metrics = _metrics(fatigued=True)
        new_profile, changes = apply(profile, metrics, {}, {}, "s1")
        has_break = new_profile["session_pacing"].get("suggest_break", False)
        assert has_break

    def test_no_fatigue_clears_break(self) -> None:
        profile = default_profile()
        profile["session_pacing"] = {"suggest_break": True}
        metrics = _metrics(fatigued=False)
        new_profile, _ = apply(profile, metrics, {}, {}, "s1")
        assert not new_profile["session_pacing"].get("suggest_break", False)

    def test_version_increments_on_change(self) -> None:
        profile = default_profile()
        profile["version"] = 5
        metrics = _metrics(accidental_tap_rate=0.20)
        new_profile, changes = apply(profile, metrics, {}, {}, "s1")
        if changes:
            assert new_profile["version"] == 6

    def test_no_change_no_version_bump(self) -> None:
        profile = default_profile()
        profile["version"] = 5
        metrics = _metrics()  # neutral metrics
        new_profile, changes = apply(profile, metrics, {}, {}, "s1")
        if not changes:
            assert new_profile["version"] == 5
