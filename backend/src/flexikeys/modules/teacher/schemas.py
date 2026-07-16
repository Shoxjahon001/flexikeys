from __future__ import annotations

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class ClassOut(BaseModel):
    id: uuid.UUID
    name: str
    join_code: str
    student_count: int
    created_at: datetime

    model_config = {"from_attributes": True}


class CreateClassIn(BaseModel):
    name: str = Field(..., min_length=1, max_length=128)


class ClassEnrollmentOut(BaseModel):
    class_id: uuid.UUID
    class_name: str
    enrolled_at: datetime


class EnrollIn(BaseModel):
    join_code: str = Field(..., min_length=4, max_length=16)
    child_id: uuid.UUID


class AssignmentOut(BaseModel):
    id: uuid.UUID
    class_id: uuid.UUID
    level_id: uuid.UUID | None
    lesson_id: uuid.UUID | None
    due_at: datetime | None
    instructions: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class CreateAssignmentIn(BaseModel):
    level_id: uuid.UUID | None = None
    lesson_id: uuid.UUID | None = None
    due_at: datetime | None = None
    instructions: str | None = Field(default=None, max_length=2000)


class StudentSummaryOut(BaseModel):
    child_id: uuid.UUID
    display_name: str
    mastery_score: float
    last_active: datetime | None
    needs_attention: bool
    skills_needing_practice: list[str] = Field(default_factory=list)


class NeedsAttentionOut(BaseModel):
    child_id: uuid.UUID
    display_name: str
    # "could use extra practice" framing — never "struggling" or ranked
    skills_needing_practice: list[str]


class ClassAnalyticsOut(BaseModel):
    class_id: uuid.UUID
    class_name: str
    student_count: int
    avg_mastery: float
    needs_attention_count: int
    student_summaries: list[StudentSummaryOut]
