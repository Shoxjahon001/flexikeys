"""
Per-session and per-skill metric computation.

All functions are pure (no side effects).  They operate on lists of
event dicts; callers normalise DB rows before passing in.

Constants
---------
EWMA_ALPHA = 0.15
    Standard exponential weight for accuracy and latency streams.
FATIGUE_THRESHOLD = -0.05
    Linear-regression slope (accuracy per item) below which the session
    is considered fatigued.
"""
from __future__ import annotations

from typing import Any

EWMA_ALPHA: float = 0.15
FATIGUE_THRESHOLD: float = -0.005  # slope per item (0.5% accuracy loss per item)
TOUCH_OFFSET_THRESHOLD: float = 0.30  # fraction of key size
ACCIDENTAL_TAP_THRESHOLD: float = 0.08  # 8 %
HESITATION_THRESHOLD_MS: float = 1200.0  # 1.2 s


# ── EWMA ──────────────────────────────────────────────────────────────────────


def ewma_update(
    old: float | None,
    new_value: float,
    alpha: float = EWMA_ALPHA,
) -> float:
    """Single EWMA step.  First call (old=None) returns new_value as seed."""
    if old is None:
        return new_value
    return alpha * new_value + (1.0 - alpha) * old


# ── Per-metric accumulators ───────────────────────────────────────────────────


def compute_ewma_accuracy(events: list[dict[str, Any]]) -> float | None:
    """EWMA of keystroke/item_completed correctness (payload.correct bool)."""
    graded = [
        e for e in events
        if e.get("payload", {}).get("correct") is not None
    ]
    if not graded:
        return None
    result: float | None = None
    for e in graded:
        result = ewma_update(result, 1.0 if e["payload"]["correct"] else 0.0)
    return result


def compute_ewma_latency(events: list[dict[str, Any]]) -> float | None:
    """EWMA of keystroke latency (payload.latency_ms, ms)."""
    latency_events = [
        e for e in events
        if e.get("payload", {}).get("latency_ms") is not None
    ]
    if not latency_events:
        return None
    result: float | None = None
    for e in latency_events:
        result = ewma_update(result, float(e["payload"]["latency_ms"]))
    return result


def compute_hesitation(events: list[dict[str, Any]]) -> float | None:
    """EWMA of time_to_first_touch (payload.time_to_first_touch_ms, ms)."""
    he = [
        e for e in events
        if e.get("payload", {}).get("time_to_first_touch_ms") is not None
    ]
    if not he:
        return None
    result: float | None = None
    for e in he:
        result = ewma_update(result, float(e["payload"]["time_to_first_touch_ms"]))
    return result


def compute_accidental_tap_rate(events: list[dict[str, Any]]) -> float | None:
    """
    Taps flagged as accidental (rejected by dwell/debounce, or explicitly flagged) ÷
    total keystroke events.  Returns None when there are no keystroke events.
    """
    ks = [e for e in events if e.get("event_type") == "keystroke"]
    if not ks:
        return None
    rejected = sum(
        1 for e in ks
        if e.get("payload", {}).get("rejected_by_dwell", False)
        or e.get("payload", {}).get("rejected_by_debounce", False)
        or e.get("payload", {}).get("accidental_tap", False)
    )
    return rejected / len(ks)


def compute_fatigue_index(events: list[dict[str, Any]]) -> float | None:
    """
    Linear-regression slope of per-item accuracy over the session sequence.
    Prefers `item_completed` events (sorted by payload.sequence_index);
    falls back to any event with a `correct` field in the payload (e.g. keystrokes)
    when no item_completed events are present.
    Returns None when fewer than 4 observations are available.
    """
    completed = sorted(
        [e for e in events if e.get("event_type") == "item_completed"],
        key=lambda e: e.get("payload", {}).get("sequence_index", 0),
    )
    if len(completed) < 4:
        # Fallback: any keystroke or other event with a `correct` field
        completed = [
            e for e in events
            if e.get("payload", {}).get("correct") is not None
        ]
    if len(completed) < 4:
        return None

    n = len(completed)
    xs = list(range(n))
    ys = [1.0 if e.get("payload", {}).get("correct", False) else 0.0 for e in completed]

    x_mean = sum(xs) / n
    y_mean = sum(ys) / n
    numerator = sum((x - x_mean) * (y - y_mean) for x, y in zip(xs, ys, strict=True))
    denominator = sum((x - x_mean) ** 2 for x in xs)
    if denominator == 0.0:
        return 0.0
    return numerator / denominator


def compute_touch_precision(events: list[dict[str, Any]]) -> float | None:
    """
    Mean of payload.offset_ratio (|offset from key centre| / key size,
    computed client-side).  Returns None when no such events present.
    """
    pe = [
        e for e in events
        if e.get("payload", {}).get("offset_ratio") is not None
    ]
    if not pe:
        return None
    return sum(float(e["payload"]["offset_ratio"]) for e in pe) / len(pe)


def update_confusion_matrix(
    matrix: dict[str, dict[str, int]],
    target: str,
    actual: str,
) -> dict[str, dict[str, int]]:
    """
    Increment target→actual error count.
    Correct answers (target == actual) are ignored.
    Returns the (mutated) matrix for convenience.
    """
    if actual == target:
        return matrix
    row = matrix.setdefault(target, {})
    row[actual] = row.get(actual, 0) + 1
    return matrix


# ── Session-level aggregation ─────────────────────────────────────────────────


def compute_session_metrics(events: list[dict[str, Any]]) -> dict[str, Any]:
    """
    Aggregate all metrics for a flat list of events from one session.
    Returns a dict ready for the policy function.
    """
    fatigue = compute_fatigue_index(events)
    return {
        "ewma_accuracy": compute_ewma_accuracy(events),
        "ewma_latency_ms": compute_ewma_latency(events),
        "hesitation_ms": compute_hesitation(events),
        "accidental_tap_rate": compute_accidental_tap_rate(events),
        "fatigue_index": fatigue,
        "fatigued": fatigue is not None and fatigue < FATIGUE_THRESHOLD,
        "touch_precision": compute_touch_precision(events),
        "per_skill": {},  # populated by caller from per-skill partitions
    }


def compute_per_skill_metrics(
    all_events: list[dict[str, Any]],
) -> dict[str, dict[str, Any]]:
    """
    Group events by skill_key and compute per-skill metrics.
    Returns {skill_key: metrics_dict}.
    """
    by_skill: dict[str, list[dict[str, Any]]] = {}
    for e in all_events:
        sk = e.get("skill_key") or e.get("payload", {}).get("skill_key")
        if sk:
            by_skill.setdefault(sk, []).append(e)

    result: dict[str, dict[str, Any]] = {}
    for sk, evts in by_skill.items():
        result[sk] = {
            "ewma_accuracy": compute_ewma_accuracy(evts),
            "ewma_latency_ms": compute_ewma_latency(evts),
            "hesitation_ms": compute_hesitation(evts),
        }
    return result
