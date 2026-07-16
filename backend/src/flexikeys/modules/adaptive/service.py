from __future__ import annotations

import uuid
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.adaptive import mastery as mastery_mod
from flexikeys.modules.adaptive import metrics as metrics_mod
from flexikeys.modules.adaptive import policy as policy_mod
from flexikeys.modules.adaptive import repetition as rep_mod
from flexikeys.modules.adaptive.policy import default_profile
from flexikeys.modules.adaptive.repository import AdaptiveRepository


class AdaptiveService:
    def __init__(self, session: AsyncSession) -> None:
        self._repo = AdaptiveRepository(session)

    async def get_profile(self, child_id: uuid.UUID) -> dict[str, Any]:
        """Return the current AdaptationProfile.params (or default)."""
        profile = await self._repo.get_profile(child_id)
        return profile.params if profile else default_profile()

    async def process_session_events(
        self,
        child_id: uuid.UUID,
        language: str,
        session_id: str,
        events: list[dict[str, Any]],
    ) -> None:
        """
        Core metrics → mastery → policy pipeline.
        Called as a background task after event batch ingest.
        """
        # 1. Compute session-level metrics
        session_metrics = metrics_mod.compute_session_metrics(events)
        per_skill = metrics_mod.compute_per_skill_metrics(events)
        session_metrics["per_skill"] = per_skill

        # 2. Update SkillMastery for each skill via BKT
        mastery_map: dict[str, float] = {}
        for skill_key, skill_metrics in per_skill.items():
            sm = await self._repo.get_skill_mastery(child_id, language, skill_key)
            p_known_current = float(sm.p_known) if sm else mastery_mod.P_INIT
            attempts = sm.attempts if sm else 0
            correct_count = sm.correct if sm else 0
            prev_ewma_acc = float(sm.ewma_accuracy) if sm and sm.ewma_accuracy else None
            prev_ewma_lat = float(sm.ewma_latency_ms) if sm and sm.ewma_latency_ms else None

            # Graded events for this skill
            skill_events = [
                e for e in events
                if (e.get("skill_key") == skill_key or e.get("payload", {}).get("skill_key") == skill_key)
                and e.get("payload", {}).get("correct") is not None
            ]
            p_known_updated = p_known_current
            delta_attempts = 0
            delta_correct = 0
            for e in skill_events:
                is_correct = bool(e["payload"]["correct"])
                p_known_updated = mastery_mod.bkt_update(p_known_updated, is_correct)
                delta_attempts += 1
                if is_correct:
                    delta_correct += 1

            new_ewma_acc = metrics_mod.ewma_update(prev_ewma_acc, skill_metrics.get("ewma_accuracy") or 0.0) if skill_metrics.get("ewma_accuracy") is not None else prev_ewma_acc
            new_ewma_lat = metrics_mod.ewma_update(prev_ewma_lat, skill_metrics.get("ewma_latency_ms") or 0.0) if skill_metrics.get("ewma_latency_ms") is not None else prev_ewma_lat

            await self._repo.upsert_skill_mastery(
                child_id, language, skill_key,
                p_known=p_known_updated,
                attempts_delta=delta_attempts,
                correct_delta=delta_correct,
                ewma_accuracy=new_ewma_acc,
                ewma_latency_ms=new_ewma_lat,
            )
            mastery_map[skill_key] = p_known_updated

            # Update SM-2 repetition queue
            if delta_attempts > 0:
                rq = await self._repo.get_skill_mastery(child_id, language, skill_key)
                queue_rows = await self._repo.list_due_queue(child_id, language)
                queue_item = next(
                    (r for r in queue_rows if r.skill_key == skill_key), None
                )
                interval = queue_item.interval_days if queue_item else 0
                ease = float(queue_item.ease) if queue_item else rep_mod.EASE_INIT
                lapses = queue_item.lapses if queue_item else 0
                # Use last graded result for SM-2
                last_correct = skill_events[-1]["payload"]["correct"] if skill_events else True
                new_interval, new_ease, new_lapses = rep_mod.sm2_update(
                    interval, ease, lapses, bool(last_correct)
                )
                due_at = rep_mod.next_due_at(new_interval)
                await self._repo.upsert_queue_entry(
                    child_id, language, skill_key, due_at, new_interval, new_ease, new_lapses
                )

        # 3. Load current profile → run policy
        profile_params = await self.get_profile(child_id)
        new_params, changes = policy_mod.apply(
            profile=profile_params,
            metrics=session_metrics,
            mastery=mastery_map,
            last_changes=None,  # TODO load from Redis for hysteresis
            session_id=session_id,
        )

        # 4. Persist updated profile + audit log
        version = int(new_params.get("version", 1))
        await self._repo.upsert_profile(child_id, new_params, version)
        if changes:
            await self._repo.record_changes(child_id, changes)
