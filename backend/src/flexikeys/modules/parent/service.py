from __future__ import annotations

import uuid
from datetime import UTC, datetime, timedelta

from fastapi import HTTPException

from flexikeys.modules.parent.repository import ParentRepository
from flexikeys.modules.parent.schemas import ChildSummaryOut, ExportDataOut, ReportOut


def _compute_streak(records: list) -> int:
    """
    Count consecutive active days ending on the most recent date.

    Each record must have `.date` (a `datetime.date`) and `.seconds_active` (int).
    A day with `seconds_active > 0` is considered active.
    """
    if not records:
        return 0

    active_dates = sorted(
        {r.date for r in records if r.seconds_active > 0},
        reverse=True,
    )
    if not active_dates:
        return 0

    streak = 1
    for i in range(1, len(active_dates)):
        if active_dates[i] == active_dates[i - 1] - timedelta(days=1):
            streak += 1
        else:
            break
    return streak


class ParentService:
    def __init__(self, repo: ParentRepository) -> None:
        self._repo = repo

    async def get_summary(
        self, child_id: uuid.UUID, parent_id: uuid.UUID
    ) -> ChildSummaryOut:
        child = await self._repo.get_child(child_id, parent_id)
        if child is None:
            raise HTTPException(status_code=404, detail="child_not_found")

        today_activity = await self._repo.get_today_activity(child_id)
        today_seconds = today_activity.seconds_active if today_activity else 0
        today_items = today_activity.items_completed if today_activity else 0

        all_activity = await self._repo.get_all_activity(child_id)
        streak = _compute_streak(all_activity)

        return ChildSummaryOut(
            child_id=child_id,
            display_name=child.display_name,
            today_minutes=round(today_seconds / 60.0, 2),
            today_items=today_items,
            streak_days=streak,
            learning_language=child.learning_language.value
            if hasattr(child.learning_language, "value")
            else str(child.learning_language),
            ui_language=child.ui_language,
        )

    async def list_reports(
        self, child_id: uuid.UUID, parent_id: uuid.UUID, scope: str | None
    ) -> list[ReportOut]:
        child = await self._repo.get_child(child_id, parent_id)
        if child is None:
            raise HTTPException(status_code=404, detail="child_not_found")

        reports = await self._repo.get_reports(child_id, scope)
        return [
            ReportOut(
                id=r.id,
                scope=r.scope.value if hasattr(r.scope, "value") else str(r.scope),
                period=r.period,
                payload=r.payload,
                created_at=r.created_at,
            )
            for r in reports
        ]

    async def export_child_data(
        self, child_id: uuid.UUID, parent_id: uuid.UUID
    ) -> ExportDataOut:
        child = await self._repo.get_child(child_id, parent_id)
        if child is None:
            raise HTTPException(status_code=404, detail="child_not_found")

        activity = await self._repo.get_all_activity(child_id)
        skill_mastery = await self._repo.get_all_skill_mastery(child_id)
        adaptation_changes = await self._repo.get_all_adaptation_changes(child_id)

        activity_records = [
            {
                "date": str(a.date),
                "seconds_active": a.seconds_active,
                "items_completed": a.items_completed,
                "avg_accuracy": float(a.avg_accuracy) if a.avg_accuracy is not None else None,
            }
            for a in activity
        ]
        skill_records = [
            {
                "skill_key": s.skill_key,
                "language": s.language,
                "p_known": float(s.p_known),
                "attempts": s.attempts,
                "correct": s.correct,
            }
            for s in skill_mastery
        ]
        adaptation_records = [
            {
                "changed_at": c.changed_at.isoformat(),
                "param": c.param,
                "old_value": c.old_value,
                "new_value": c.new_value,
                "reason_code": c.reason_code.value
                if hasattr(c.reason_code, "value")
                else str(c.reason_code),
            }
            for c in adaptation_changes
        ]

        return ExportDataOut(
            child_id=child_id,
            display_name=child.display_name,
            learning_language=child.learning_language.value
            if hasattr(child.learning_language, "value")
            else str(child.learning_language),
            activity_records=activity_records,
            skill_mastery=skill_records,
            adaptation_changes=adaptation_records,
            exported_at=datetime.now(UTC),
        )

    async def delete_child(
        self, child_id: uuid.UUID, parent_id: uuid.UUID
    ) -> None:
        child = await self._repo.get_child(child_id, parent_id)
        if child is None:
            raise HTTPException(status_code=404, detail="child_not_found")
        await self._repo.delete_child(child_id)
