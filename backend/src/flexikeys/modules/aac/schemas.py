from __future__ import annotations

import uuid
from datetime import date, datetime
from typing import Literal

from pydantic import BaseModel, Field

# ── Event ingest (matches app/lib/features/aac/data/aac_event_repository.dart) ─


class AacEventIn(BaseModel):
    card_id: str = Field(max_length=64)
    category: str = Field(max_length=32)
    sentence_spoken: str = Field(max_length=500)
    language: str = Field(max_length=10)
    tapped_at: datetime


class AacEventBatchIn(BaseModel):
    child_id: uuid.UUID
    batch_id: uuid.UUID
    events: list[AacEventIn] = Field(min_length=1, max_length=500)


class AacEventBatchOut(BaseModel):
    accepted: int
    deduplicated: bool


# ── Sentence composer ──────────────────────────────────────────────────────────


class ComposeSentenceRequest(BaseModel):
    child_id: uuid.UUID
    # Bare vocabulary words tapped in sequence (e.g. ["water", "cold",
    # "please"]) — never PII, never free text the child didn't select from
    # the card grid.
    words: list[str] = Field(min_length=1, max_length=10)
    language: str = Field(default="en", max_length=10)


class ComposeSentenceResponse(BaseModel):
    sentence: str
    source: Literal["ai", "template"]


# ── Neural TTS (Sentence Strip playback — ad-hoc text, no bundled asset) ───────


class TtsRequest(BaseModel):
    text: str = Field(min_length=1, max_length=500)
    lang: Literal["en", "uz", "ru"]


# ── Pattern-analysis insights (parent dashboard) ───────────────────────────────


class AacInsightOut(BaseModel):
    category: str
    headline: str
    body: str
    tone: Literal["positive", "neutral", "attention"]


class AacInsightsResponse(BaseModel):
    insights: list[AacInsightOut]
    disclaimer: str | None
    generated_at: datetime


# ── Parent dashboard stats (Today + 7-day trend) ───────────────────────────────
# card labels are NOT included — vocabulary text lives only in the bundled
# Flutter asset (see docs/aac_phase1_architecture.md), never synced to the
# backend. The client maps card_id -> label/glyph itself via
# AacCardRepository, which already has to load that data anyway.


class AacTodayCardStat(BaseModel):
    card_id: str
    category: str
    count: int


class AacTrendPoint(BaseModel):
    date: date
    category: str
    count: int


class AacStatsResponse(BaseModel):
    today: list[AacTodayCardStat]
    trend: list[AacTrendPoint]
