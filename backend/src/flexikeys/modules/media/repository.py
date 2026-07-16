from __future__ import annotations

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.modules.curriculum.models import Asset


class MediaRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._s = session

    async def find_by_checksum(self, checksum: str) -> Asset | None:
        result = await self._s.execute(
            select(Asset).where(Asset.checksum == checksum)
        )
        return result.scalar_one_or_none()

    async def find_by_key(self, storage_key: str) -> Asset | None:
        result = await self._s.execute(
            select(Asset).where(Asset.storage_key == storage_key)
        )
        return result.scalar_one_or_none()

    async def create(
        self,
        kind: str,
        storage_key: str,
        mime: str,
        size_bytes: int,
        checksum: str,
    ) -> Asset:
        from flexikeys.core.enums import AssetKind
        asset = Asset(
            id=uuid.uuid4(),
            kind=AssetKind(kind),
            storage_key=storage_key,
            mime=mime,
            bytes=size_bytes,
            checksum=checksum,
        )
        self._s.add(asset)
        await self._s.flush()
        return asset
