from __future__ import annotations

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.deps import get_child_claims, get_current_user
from flexikeys.core.enums import UserRole
from flexikeys.modules.adaptive.repository import AdaptiveRepository
from flexikeys.modules.adaptive.schemas import AdaptationProfileOut, ProfileResponse, SkillMasteryOut
from flexikeys.modules.adaptive.service import AdaptiveService
from flexikeys.modules.users.models import User

router = APIRouter(prefix="/adaptive", tags=["adaptive"])


@router.get("/profile", response_model=ProfileResponse)
async def get_child_profile(
    claims: Annotated[dict, Depends(get_child_claims)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ProfileResponse:
    """Return the current adaptation profile for the authenticated child session."""
    child_id = uuid.UUID(str(claims["sub"]))
    language = str(claims.get("lang", "en"))
    repo = AdaptiveRepository(db)

    profile = await repo.get_profile(child_id)
    mastery_rows = await repo.list_skill_mastery(child_id, language)

    from flexikeys.modules.adaptive.policy import default_profile
    profile_params = profile.params if profile else default_profile()
    profile_out = AdaptationProfileOut(
        child_id=child_id,
        params=profile_params,
        version=profile.version if profile else 1,
        updated_at=profile.updated_at if profile else __import__("datetime").datetime.now(__import__("datetime").timezone.utc),
    )
    mastery_out = [
        SkillMasteryOut(
            skill_key=m.skill_key,
            language=m.language,
            p_known=float(m.p_known),
            attempts=m.attempts,
            correct=m.correct,
            ewma_accuracy=float(m.ewma_accuracy) if m.ewma_accuracy else None,
            ewma_latency_ms=float(m.ewma_latency_ms) if m.ewma_latency_ms else None,
            last_seen_at=m.last_seen_at,
        )
        for m in mastery_rows
    ]
    return ProfileResponse(profile=profile_out, mastery=mastery_out)
