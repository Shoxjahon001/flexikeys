from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel


class AssetOut(BaseModel):
    id: str
    kind: str
    storage_key: str
    mime: str
    bytes: int
    url: str
    created_at: datetime


class UploadRequest(BaseModel):
    storage_key: str
    mime: str


class UploadResponse(BaseModel):
    upload_url: str
    asset_id: str
