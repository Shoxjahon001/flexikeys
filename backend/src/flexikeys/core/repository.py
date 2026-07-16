from __future__ import annotations

from typing import Any, Generic, Sequence, Type, TypeVar

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from flexikeys.core.db import Base

ModelT = TypeVar("ModelT", bound=Base)  # type: ignore[type-arg]


class BaseRepository(Generic[ModelT]):
    """Generic async CRUD base used by all module repositories."""

    def __init__(self, model: Type[ModelT], session: AsyncSession) -> None:
        self._model = model
        self._session = session

    async def get(self, id: Any) -> ModelT | None:
        return await self._session.get(self._model, id)

    async def list(self, *, limit: int = 100, offset: int = 0) -> Sequence[ModelT]:
        result = await self._session.execute(
            select(self._model).limit(limit).offset(offset)
        )
        return result.scalars().all()

    async def create(self, **kwargs: Any) -> ModelT:
        obj = self._model(**kwargs)
        self._session.add(obj)
        await self._session.flush()
        await self._session.refresh(obj)
        return obj

    async def update(self, obj: ModelT, **kwargs: Any) -> ModelT:
        for key, value in kwargs.items():
            setattr(obj, key, value)
        await self._session.flush()
        await self._session.refresh(obj)
        return obj

    async def delete(self, obj: ModelT) -> None:
        await self._session.delete(obj)
        await self._session.flush()