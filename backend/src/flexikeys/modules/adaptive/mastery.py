"""
Bayesian Knowledge Tracing (BKT).

Published parameters (change in config, never in this file):
    P_INIT   = 0.20   initial P(known) when a skill is first seen
    P_LEARN  = 0.15   P(unknown → known) per attempt (learning rate)
    P_SLIP   = 0.10   P(wrong | known)  — momentary slip
    P_GUESS  = 0.20   P(right | unknown) — lucky guess

Mastery definition:
    p_known ≥ MASTERY_THRESHOLD  AND  attempts ≥ MIN_ATTEMPTS

How ML models slot in later
----------------------------
Replace `bkt_update()` with a neural predictor that takes the full
attempt history and returns a float in [0, 1].  The rest of the
pipeline (mastery check, progression gate, repetition scheduler) is
unchanged because they only consume the returned float.

Hand-computed test fixtures (for regression tests)
---------------------------------------------------
Initial p_known = 0.20

Attempt 1 — correct:
  p_correct = 0.20*(1-0.10) + 0.80*0.20 = 0.18 + 0.16 = 0.34
  p(L|correct) = 0.18 / 0.34 ≈ 0.52941
  after learn   = 0.52941 + 0.47059*0.15 ≈ 0.60000

Attempt 2 — correct:
  p_correct = 0.60*0.90 + 0.40*0.20 = 0.54 + 0.08 = 0.62
  p(L|correct) = 0.54 / 0.62 ≈ 0.87097
  after learn   ≈ 0.87097 + 0.12903*0.15 ≈ 0.89032

Attempt 3 — incorrect:
  p_incorrect = 0.89032*0.10 + 0.10968*0.80 = 0.08903 + 0.08774 = 0.17678
  p(L|incorrect) = 0.08903 / 0.17678 ≈ 0.50367
  after learn    ≈ 0.50367 + 0.49633*0.15 ≈ 0.57812
"""
from __future__ import annotations

P_INIT: float = 0.20
P_LEARN: float = 0.15
P_SLIP: float = 0.10
P_GUESS: float = 0.20
MASTERY_THRESHOLD: float = 0.95
MIN_ATTEMPTS: int = 8


def bkt_update(p_known: float, correct: bool) -> float:
    """
    One BKT update step.

    Parameters
    ----------
    p_known:
        Current P(skill is known), in [0, 1].
    correct:
        True if the child answered correctly.

    Returns
    -------
    Updated P(known) after the observation and the learning step.
    """
    if correct:
        p_obs = p_known * (1.0 - P_SLIP) + (1.0 - p_known) * P_GUESS
        p_known_given_obs = (p_known * (1.0 - P_SLIP)) / p_obs if p_obs else p_known
    else:
        p_obs = p_known * P_SLIP + (1.0 - p_known) * (1.0 - P_GUESS)
        p_known_given_obs = (p_known * P_SLIP) / p_obs if p_obs else p_known

    # Learning transition: unknown → known
    return p_known_given_obs + (1.0 - p_known_given_obs) * P_LEARN


def is_mastered(p_known: float, attempts: int) -> bool:
    """Return True when the skill qualifies as mastered."""
    return p_known >= MASTERY_THRESHOLD and attempts >= MIN_ATTEMPTS


def bkt_sequence(
    responses: list[bool],
    p_init: float = P_INIT,
) -> list[float]:
    """
    Run BKT over a sequence of boolean responses.
    Returns list of p_known values *after* each update (same length as responses).
    Useful for unit tests and the simulation harness.
    """
    p = p_init
    result: list[float] = []
    for correct in responses:
        p = bkt_update(p, correct)
        result.append(round(p, 8))
    return result
