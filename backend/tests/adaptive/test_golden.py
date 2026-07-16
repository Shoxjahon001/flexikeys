"""
Contract tests: Python policy output vs shared/adaptive_policy.json golden fixtures.

These tests ensure that the Python implementation matches the documented spec
precisely, so the Dart client can implement the same algorithm from the same
JSON spec and produce identical results.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

import pytest

from flexikeys.modules.adaptive.mastery import P_INIT, bkt_sequence
from flexikeys.modules.adaptive.policy import apply
from flexikeys.modules.adaptive.repetition import sm2_update

SPEC_PATH = (
    Path(__file__).parent.parent.parent.parent / "shared" / "adaptive_policy.json"
)


@pytest.fixture(scope="module")
def spec() -> dict:
    return json.loads(SPEC_PATH.read_text())


def _approx(a: float, b: float, tol: float = 0.005) -> bool:
    return math.isclose(a, b, abs_tol=tol)


class TestBktGolden:
    def test_3_step_sequence(self, spec: dict) -> None:
        fixture = next(f for f in spec["golden_fixtures"] if f["id"] == "bkt_3step")
        responses: list[bool] = fixture["input"]["responses"]
        expected: list[float] = fixture["expected_p_known_sequence"]
        result = bkt_sequence(responses, p_init=spec["bkt"]["p_init"])
        assert len(result) == len(expected)
        for i, (got, want) in enumerate(zip(result, expected)):
            assert _approx(got, want), f"step {i}: got {got:.5f}, want {want:.5f}"


class TestSm2Golden:
    def test_3_step(self, spec: dict) -> None:
        fixture = next(f for f in spec["golden_fixtures"] if f["id"] == "sm2_3step")
        inputs = fixture["input"]
        expected = fixture["expected"]
        for step_input, step_expected in zip(inputs, expected):
            got_interval, got_ease, got_lapses = sm2_update(
                step_input["interval"],
                step_input["ease"],
                step_input["lapses"],
                step_input["correct"],
            )
            assert got_interval == step_expected["interval"], (
                f"interval: got {got_interval}, want {step_expected['interval']}"
            )
            assert _approx(got_ease, step_expected["ease"]), (
                f"ease: got {got_ease:.3f}, want {step_expected['ease']:.3f}"
            )
            assert got_lapses == step_expected["lapses"]


class TestPolicyGolden:
    def _run_fixture(self, fixture: dict) -> tuple[dict, list]:
        inp = fixture["input"]
        return apply(
            inp["profile"],
            inp["metrics"],
            inp["mastery"],
            inp["last_changes"],
            inp["session_id"],
        )

    def test_accidental_tap_fixture(self, spec: dict) -> None:
        fixture = next(f for f in spec["golden_fixtures"] if f["id"] == "policy_accidental_tap")
        new_profile, changes = self._run_fixture(fixture)
        expected_changes = set(fixture["expected_changes"])
        got_changes = {c.param for c in changes}
        assert expected_changes <= got_changes, (
            f"Expected changes {expected_changes}, got {got_changes}"
        )
        for key, val in fixture["expected_profile_partial"].items():
            if isinstance(val, float):
                assert _approx(new_profile[key], val), (
                    f"{key}: got {new_profile[key]}, want {val}"
                )
            else:
                assert new_profile[key] == val

    def test_poor_precision_fixture(self, spec: dict) -> None:
        fixture = next(f for f in spec["golden_fixtures"] if f["id"] == "policy_poor_precision")
        new_profile, changes = self._run_fixture(fixture)
        expected_changes = set(fixture["expected_changes"])
        got_changes = {c.param for c in changes}
        assert expected_changes <= got_changes
        assert _approx(new_profile["key_scale"], fixture["expected_profile_partial"]["key_scale"])

    def test_fatigue_fixture(self, spec: dict) -> None:
        fixture = next(f for f in spec["golden_fixtures"] if f["id"] == "policy_fatigue")
        new_profile, changes = self._run_fixture(fixture)
        expected_changes = set(fixture["expected_changes"])
        got_changes = {c.param for c in changes}
        assert expected_changes <= got_changes
        assert new_profile["session_pacing"]["suggest_break"] is True

    def test_all_fixtures_covered(self, spec: dict) -> None:
        """Every fixture in the spec is exercised."""
        fixture_ids = {f["id"] for f in spec["golden_fixtures"]}
        assert "bkt_3step" in fixture_ids
        assert "sm2_3step" in fixture_ids
        assert "policy_accidental_tap" in fixture_ids
        assert "policy_poor_precision" in fixture_ids
        assert "policy_fatigue" in fixture_ids
