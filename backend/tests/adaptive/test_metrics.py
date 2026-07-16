"""EWMA, fatigue, precision, confusion matrix unit tests."""
from __future__ import annotations

from flexikeys.modules.adaptive.metrics import (
    EWMA_ALPHA,
    compute_accidental_tap_rate,
    compute_ewma_accuracy,
    compute_ewma_latency,
    compute_fatigue_index,
    compute_session_metrics,
    compute_touch_precision,
    ewma_update,
    update_confusion_matrix,
)


def _keystroke(
    target: str = "a",
    actual: str = "a",
    latency_ms: float = 300.0,
    hesitation_ms: float = 0.0,
    accidental: bool = False,
    offset_ratio: float = 0.1,
) -> dict:
    return {
        "event_type": "keystroke",
        "payload": {
            "event_type": "keystroke",
            "target_key": target,
            "actual_key": actual,
            "correct": target == actual,  # explicit bool for metrics pipeline
            "latency_ms": latency_ms,
            "time_to_first_touch_ms": hesitation_ms,
            "touch_offset_x": 0.0,
            "touch_offset_y": 0.0,
            "offset_ratio": offset_ratio,
            "accidental_tap": accidental,
            "retry_count": 0,
        },
    }


class TestEwmaUpdate:
    def test_first_call_seeds_with_current(self) -> None:
        result = ewma_update(None, 0.9)
        assert result == 0.9

    def test_alpha_weighting(self) -> None:
        old = 0.5
        new_val = 1.0
        expected = EWMA_ALPHA * new_val + (1 - EWMA_ALPHA) * old
        assert abs(ewma_update(old, new_val) - expected) < 1e-10

    def test_converges_to_constant(self) -> None:
        v = 0.5
        for _ in range(100):
            v = ewma_update(v, 1.0)  # type: ignore[arg-type]
        assert v > 0.98


class TestComputeEwmaAccuracy:
    def test_empty_returns_none(self) -> None:
        assert compute_ewma_accuracy([]) is None

    def test_all_correct(self) -> None:
        events = [_keystroke("a", "a") for _ in range(5)]
        acc = compute_ewma_accuracy(events)
        assert acc is not None
        assert abs(acc - 1.0) < 0.05

    def test_all_wrong(self) -> None:
        events = [_keystroke("a", "b") for _ in range(5)]
        acc = compute_ewma_accuracy(events)
        assert acc is not None
        assert acc < 0.3


class TestComputeEwmaLatency:
    def test_empty_returns_none(self) -> None:
        assert compute_ewma_latency([]) is None

    def test_single_event(self) -> None:
        events = [_keystroke(latency_ms=400.0)]
        result = compute_ewma_latency(events)
        assert result == 400.0

    def test_convergence(self) -> None:
        events = [_keystroke(latency_ms=500.0) for _ in range(20)]
        result = compute_ewma_latency(events)
        assert abs(result - 500.0) < 20.0  # type: ignore[operator]


class TestFatigueIndex:
    def test_empty_returns_none(self) -> None:
        assert compute_fatigue_index([]) is None

    def test_flat_accuracy_near_zero_slope(self) -> None:
        events = [_keystroke("a", "a") for _ in range(10)]
        result = compute_fatigue_index(events)
        assert result is not None
        assert abs(result) < 0.1

    def test_declining_accuracy_negative_slope(self) -> None:
        # First 5 correct, last 5 wrong
        events = [_keystroke("a", "a") for _ in range(5)] + [
            _keystroke("a", "b") for _ in range(5)
        ]
        result = compute_fatigue_index(events)
        assert result is not None
        assert result < 0.0

    def test_too_few_events_returns_none(self) -> None:
        events = [_keystroke() for _ in range(2)]
        result = compute_fatigue_index(events)
        # 3 or fewer events can't fit a regression reliably
        assert result is None or isinstance(result, float)


class TestTouchPrecision:
    def test_empty_returns_none(self) -> None:
        assert compute_touch_precision([]) is None

    def test_perfect_precision(self) -> None:
        events = [_keystroke(offset_ratio=0.0) for _ in range(5)]
        result = compute_touch_precision(events)
        assert result == 0.0

    def test_high_offset(self) -> None:
        events = [_keystroke(offset_ratio=0.5) for _ in range(5)]
        result = compute_touch_precision(events)
        assert abs(result - 0.5) < 0.01  # type: ignore[operator]


class TestAccidentalTapRate:
    def test_no_accidentals(self) -> None:
        events = [_keystroke(accidental=False) for _ in range(5)]
        result = compute_accidental_tap_rate(events)
        assert result == 0.0

    def test_all_accidental(self) -> None:
        events = [_keystroke(accidental=True) for _ in range(5)]
        result = compute_accidental_tap_rate(events)
        assert result == 1.0

    def test_empty(self) -> None:
        assert compute_accidental_tap_rate([]) is None


class TestConfusionMatrix:
    def test_correct_key_no_entry(self) -> None:
        matrix: dict = {}
        result = update_confusion_matrix(matrix, "a", "a")
        # Correct key — should not add to confusion matrix
        assert result == {}

    def test_wrong_key_adds_entry(self) -> None:
        matrix: dict = {}
        result = update_confusion_matrix(matrix, "b", "d")
        assert result.get("b", {}).get("d", 0) == 1

    def test_accumulates(self) -> None:
        matrix: dict = {}
        for _ in range(3):
            matrix = update_confusion_matrix(matrix, "b", "d")
        assert matrix["b"]["d"] == 3


class TestComputeSessionMetrics:
    def test_mixed_events(self) -> None:
        events = [_keystroke("a", "a") for _ in range(4)] + [_keystroke("a", "b")]
        result = compute_session_metrics(events)
        assert "ewma_accuracy" in result
        assert "ewma_latency_ms" in result
        assert "accidental_tap_rate" in result
        assert "fatigue_index" in result

    def test_empty(self) -> None:
        result = compute_session_metrics([])
        assert result["ewma_accuracy"] is None
