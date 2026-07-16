"""
Child motor-profile simulator for the adaptive engine.

Creates synthetic interaction_event sequences that mimic three child
profiles and pipes them through the full algorithm pipeline so that
regression and scenario tests can assert on the adaptation outputs.
"""
from __future__ import annotations

import random
from copy import deepcopy
from dataclasses import dataclass, field
from typing import Any

from flexikeys.modules.adaptive.mastery import bkt_update
from flexikeys.modules.adaptive.metrics import (
    FATIGUE_THRESHOLD,
    compute_fatigue_index,
    compute_session_metrics,
)
from flexikeys.modules.adaptive.policy import apply, default_profile
from flexikeys.modules.adaptive.repetition import sm2_update


@dataclass
class MotorProfile:
    """Parameterises a simulated child's motor behaviour."""

    name: str
    base_accuracy: float          # 0.0 - 1.0
    accuracy_std: float           # per-keystroke jitter
    latency_ms: float             # mean keypress latency
    accidental_tap_prob: float    # probability any tap is accidental
    offset_ratio_mean: float      # mean touch offset ratio
    fatigue_slope: float          # accuracy decrease per N events within a session


STRUGGLING = MotorProfile(
    name="struggling",
    base_accuracy=0.40,
    accuracy_std=0.15,
    latency_ms=1500.0,
    accidental_tap_prob=0.15,
    offset_ratio_mean=0.45,
    fatigue_slope=-0.02,
)

FAST_LEARNER = MotorProfile(
    name="fast_learner",
    base_accuracy=0.85,
    accuracy_std=0.08,
    latency_ms=400.0,
    accidental_tap_prob=0.02,
    offset_ratio_mean=0.10,
    fatigue_slope=0.0,
)

FATIGUING = MotorProfile(
    name="fatiguing",
    base_accuracy=0.85,
    accuracy_std=0.10,
    latency_ms=600.0,
    accidental_tap_prob=0.05,
    offset_ratio_mean=0.20,
    fatigue_slope=-0.15,  # steep fatigue: accuracy drops ~0.015/event over a session
)


def _make_keystroke_event(
    target: str,
    profile: MotorProfile,
    event_index: int,
) -> dict[str, Any]:
    """Generate a single synthetic keystroke event dict."""
    # Accuracy degrades with fatigue
    effective_acc = max(
        0.0,
        profile.base_accuracy + profile.fatigue_slope * event_index * 0.1
        + random.gauss(0, profile.accuracy_std),
    )
    correct = random.random() < effective_acc
    actual = target if correct else _random_neighbour(target)
    accidental = random.random() < profile.accidental_tap_prob
    offset = max(0.0, random.gauss(profile.offset_ratio_mean, 0.05))

    return {
        "event_type": "keystroke",
        "payload": {
            "event_type": "keystroke",
            "target_key": target,
            "actual_key": actual,
            "correct": correct,
            "latency_ms": max(50.0, random.gauss(profile.latency_ms, profile.latency_ms * 0.2)),
            "time_to_first_touch_ms": max(
                0.0, random.gauss(profile.latency_ms * 1.5, profile.latency_ms * 0.4)
            ),
            "touch_offset_x": offset * 0.7,
            "touch_offset_y": offset * 0.7,
            "offset_ratio": offset,
            "accidental_tap": accidental,
            "retry_count": 0,
        },
        "skill_key": target,
    }


def _random_neighbour(key: str) -> str:
    """Return a plausible mistype for the given key."""
    neighbours = {
        "a": "s", "b": "v", "c": "x", "d": "f", "e": "r",
        "f": "g", "g": "h", "h": "j", "i": "o", "j": "k",
        "k": "l", "l": "k", "m": "n", "n": "m", "o": "p",
        "p": "o", "q": "w", "r": "e", "s": "a", "t": "y",
        "u": "y", "v": "b", "w": "q", "x": "z", "y": "u",
        "z": "x",
    }
    return neighbours.get(key, "a")


@dataclass
class SessionResult:
    session_number: int
    events: list[dict[str, Any]]
    metrics: dict[str, Any]
    profile: dict[str, Any]
    changes: list[Any]
    p_known_per_skill: dict[str, float] = field(default_factory=dict)
    fatigued: bool = False


def run_simulation(
    profile: MotorProfile,
    num_sessions: int = 5,
    events_per_session: int = 30,
    skills: list[str] | None = None,
    seed: int = 42,
) -> list[SessionResult]:
    """
    Run a multi-session simulation for one child motor profile.

    Returns a list of SessionResult, one per session.
    """
    random.seed(seed)
    if skills is None:
        skills = list("abcde")

    adaptation = deepcopy(default_profile())
    last_changes: dict[str, dict[str, Any]] = {}
    p_known: dict[str, float] = dict.fromkeys(skills, 0.2)
    sm2_state: dict[str, tuple[int, float, int]] = dict.fromkeys(skills, (1, 2.5, 0))
    results: list[SessionResult] = []

    for session_num in range(1, num_sessions + 1):
        events: list[dict[str, Any]] = []
        for i in range(events_per_session):
            skill = skills[i % len(skills)]
            ev = _make_keystroke_event(skill, profile, i)
            events.append(ev)

            # Update BKT mastery
            correct = ev["payload"]["actual_key"] == ev["payload"]["target_key"]
            p_known[skill] = bkt_update(p_known[skill], correct)

            # Update SM-2 schedule
            interval, ease, lapses = sm2_state[skill]
            sm2_state[skill] = sm2_update(interval, ease, lapses, correct)

        session_metrics = compute_session_metrics(events)

        # Build per_skill metrics
        per_skill: dict[str, dict[str, Any]] = {}
        for sk in skills:
            sk_events = [e for e in events if e.get("skill_key") == sk]
            if sk_events:
                per_skill[sk] = compute_session_metrics(sk_events)

        session_metrics["per_skill"] = per_skill

        # Check fatigue
        fatigue_idx = compute_fatigue_index(events)
        fatigued = fatigue_idx is not None and fatigue_idx < FATIGUE_THRESHOLD
        session_metrics["fatigued"] = fatigued

        # Run policy
        mastery_floats = dict(p_known.items())
        new_adaptation, changes = apply(
            adaptation, session_metrics, mastery_floats, last_changes, f"session_{session_num}"
        )

        # Update last_changes from policy (policy mutates the dict in-place)
        adaptation = new_adaptation
        results.append(
            SessionResult(
                session_number=session_num,
                events=events,
                metrics=session_metrics,
                profile=deepcopy(adaptation),
                changes=changes,
                p_known_per_skill=deepcopy(p_known),
                fatigued=fatigued,
            )
        )

    return results
