"""
Session and event-ingest schemas.

Event payloads use Pydantic discriminated unions so that each
event_type has its own validated payload shape.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from typing import Annotated, Any, Literal

from pydantic import BaseModel, ConfigDict, Field


# ── Per-event-type payload models ─────────────────────────────────────────────


class KeystrokePayload(BaseModel):
    event_type: Literal["keystroke"] = "keystroke"
    target_key: str
    actual_key: str
    latency_ms: float = Field(ge=0)
    correct: bool
    rejected_by_dwell: bool = False
    rejected_by_debounce: bool = False
    # Touch precision signals
    offset_ratio: float | None = Field(default=None, ge=0)  # |offset| / key_size
    touch_offset_x: float | None = None
    touch_offset_y: float | None = None
    # Hesitation: time from item-shown to first finger contact
    time_to_first_touch_ms: float | None = Field(default=None, ge=0)
    # Accidental contact that was rejected or re-tapped
    accidental_tap: bool = False
    retry_count: int = Field(default=0, ge=0)
    dwell_ms: float | None = None
    skill_key: str | None = None


class ItemCompletedPayload(BaseModel):
    event_type: Literal["item_completed"] = "item_completed"
    item_id: uuid.UUID | None = None
    skill_key: str | None = None
    correct: bool
    response_time_ms: float = Field(ge=0)
    sequence_index: int = Field(ge=0)
    time_to_first_touch_ms: float | None = Field(default=None, ge=0)


class ItemShownPayload(BaseModel):
    event_type: Literal["item_shown"] = "item_shown"
    item_id: uuid.UUID | None = None
    skill_key: str | None = None
    sequence_index: int = Field(ge=0)


class TracePointPayload(BaseModel):
    event_type: Literal["trace_point"] = "trace_point"
    x: float
    y: float
    pressure: float | None = None
    skill_key: str | None = None


class HintShownPayload(BaseModel):
    event_type: Literal["hint_shown"] = "hint_shown"
    skill_key: str | None = None
    hint_level: int = Field(ge=0, le=3)


class BreakTakenPayload(BaseModel):
    event_type: Literal["break_taken"] = "break_taken"
    duration_ms: float | None = None


EventPayload = Annotated[
    KeystrokePayload
    | ItemCompletedPayload
    | ItemShownPayload
    | TracePointPayload
    | HintShownPayload
    | BreakTakenPayload,
    Field(discriminator="event_type"),
]


# ── Event ingest schemas ──────────────────────────────────────────────────────


class EventIn(BaseModel):
    occurred_at: datetime
    payload: EventPayload
    item_id: uuid.UUID | None = None
    skill_key: str | None = None

    @property
    def event_type(self) -> str:
        return self.payload.event_type


class EventBatchIn(BaseModel):
    """
    Batch of up to 500 events.
    batch_id must be client-generated UUID for idempotency.
    """
    batch_id: uuid.UUID
    events: list[EventIn] = Field(min_length=1, max_length=500)


class EventBatchOut(BaseModel):
    accepted: int
    deduplicated: bool


# ── Session schemas ───────────────────────────────────────────────────────────


class SessionCreate(BaseModel):
    child_id: uuid.UUID
    language: str = "en"
    device_info: dict[str, Any] | None = None
    client_version: str | None = None


class SessionEnd(BaseModel):
    ended_at: datetime | None = None


class SessionOut(BaseModel):
    id: uuid.UUID
    child_id: uuid.UUID
    language: str
    started_at: datetime
    ended_at: datetime | None
    client_version: str | None

    model_config = ConfigDict(from_attributes=True)
