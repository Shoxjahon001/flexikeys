"""BKT unit tests verified against hand-computed fixtures."""
from __future__ import annotations

import pytest

from flexikeys.modules.adaptive.mastery import (
    P_GUESS,
    P_INIT,
    P_LEARN,
    P_SLIP,
    bkt_sequence,
    bkt_update,
    is_mastered,
)


def _p_obs(p_known: float, correct: bool) -> float:
    if correct:
        return p_known * (1 - P_SLIP) + (1 - p_known) * P_GUESS
    return p_known * P_SLIP + (1 - p_known) * (1 - P_GUESS)


def _hand_compute(p_known: float, correct: bool) -> float:
    obs = _p_obs(p_known, correct)
    if correct:
        posterior = p_known * (1 - P_SLIP) / obs
    else:
        posterior = p_known * P_SLIP / obs
    return posterior + (1 - posterior) * P_LEARN


class TestBktUpdate:
    def test_attempt1_correct(self) -> None:
        result = bkt_update(P_INIT, correct=True)
        expected = _hand_compute(P_INIT, True)
        assert abs(result - expected) < 1e-5

    def test_attempt1_correct_approx_0_60(self) -> None:
        result = bkt_update(P_INIT, correct=True)
        assert abs(result - 0.60000) < 0.005

    def test_attempt2_correct(self) -> None:
        p1 = bkt_update(P_INIT, correct=True)
        result = bkt_update(p1, correct=True)
        expected = _hand_compute(p1, True)
        assert abs(result - expected) < 1e-5

    def test_attempt2_correct_approx_0_89(self) -> None:
        p1 = bkt_update(P_INIT, correct=True)
        result = bkt_update(p1, correct=True)
        assert abs(result - 0.89032) < 0.005

    def test_attempt3_incorrect(self) -> None:
        p1 = bkt_update(P_INIT, correct=True)
        p2 = bkt_update(p1, correct=True)
        result = bkt_update(p2, correct=False)
        expected = _hand_compute(p2, False)
        assert abs(result - expected) < 1e-5

    def test_attempt3_incorrect_approx_0_578(self) -> None:
        p1 = bkt_update(P_INIT, correct=True)
        p2 = bkt_update(p1, correct=True)
        result = bkt_update(p2, correct=False)
        assert abs(result - 0.57812) < 0.005

    def test_bounded_0_1(self) -> None:
        p = 0.99
        result = bkt_update(p, correct=True)
        assert 0.0 <= result <= 1.0

    def test_monotone_sequence(self) -> None:
        sequence = bkt_sequence([True] * 10)
        for a, b in zip(sequence, sequence[1:]):
            assert a <= b + 0.01


class TestIsMastered:
    def test_not_mastered_low_p(self) -> None:
        assert not is_mastered(0.80, 8)

    def test_not_mastered_insufficient_attempts(self) -> None:
        assert not is_mastered(0.98, 5)

    def test_mastered(self) -> None:
        assert is_mastered(0.95, 8)

    def test_mastered_exact_threshold(self) -> None:
        assert is_mastered(0.95, 8)

    def test_not_mastered_just_below_threshold(self) -> None:
        assert not is_mastered(0.949, 8)


class TestBktSequence:
    def test_empty(self) -> None:
        assert bkt_sequence([]) == []

    def test_length_matches(self) -> None:
        responses = [True, False, True, True]
        result = bkt_sequence(responses)
        assert len(result) == 4

    def test_all_correct_approaches_mastery(self) -> None:
        result = bkt_sequence([True] * 20)
        assert result[-1] >= 0.90

    def test_all_incorrect_stays_low(self) -> None:
        result = bkt_sequence([False] * 15)
        # guess factor limits how much you can learn from wrong answers
        assert result[-1] < 0.80

    def test_custom_p_init(self) -> None:
        result = bkt_sequence([True], p_init=0.5)
        assert result[0] > 0.5
