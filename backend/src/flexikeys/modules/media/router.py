from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import get_db
from flexikeys.core.deps import require_role
from flexikeys.core.enums import UserRole
from flexikeys.modules.media.repository import MediaRepository
from flexikeys.modules.media.service import MediaService
from flexikeys.modules.media.schemas import AssetOut, UploadResponse
from flexikeys.modules.users.models import User

router = APIRouter(prefix="/media", tags=["media"])


@router.post("/upload", response_model=UploadResponse, status_code=201)
async def upload_asset(
    file: UploadFile,
    _user: Annotated[User, Depends(require_role(UserRole.admin))],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> UploadResponse:
    """Upload a media asset (admin only). Used by content pipeline."""
    data = await file.read()
    mime = file.content_type or "application/octet-stream"
    storage_key = f"uploads/{file.filename}"

    media_svc = MediaService()
    chk = media_svc.checksum(data)

    # Dedup by checksum
    repo = MediaRepository(db)
    existing = await repo.find_by_checksum(chk)
    if existing:
        return UploadResponse(
            upload_url=media_svc.signed_url(existing.storage_key),
            asset_id=str(existing.id),
        )

    result = await media_svc.upload_asset(data, storage_key, mime)
    asset = await repo.create(
        kind="image" if mime.startswith("image/") else "audio",
        storage_key=result["storage_key"],
        mime=mime,
        size_bytes=result["bytes"],
        checksum=result["checksum"],
    )
    await db.commit()
    return UploadResponse(
        upload_url=media_svc.signed_url(asset.storage_key),
        asset_id=str(asset.id),
    )
