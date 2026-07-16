from __future__ import annotations

import enum


class UserRole(str, enum.Enum):
    parent = "parent"
    teacher = "teacher"
    admin = "admin"


class OAuthProvider(str, enum.Enum):
    google = "google"
    apple = "apple"


class LearningLanguage(str, enum.Enum):
    en = "en"
    uz = "uz"
    ru = "ru"


class LessonType(str, enum.Enum):
    typing = "typing"
    drawing = "drawing"
    listening = "listening"
    story = "story"


class ItemType(str, enum.Enum):
    letter = "letter"
    number = "number"
    word = "word"
    sentence = "sentence"
    shape = "shape"
    color = "color"
    trace_path = "trace_path"
    story_page = "story_page"


class EventType(str, enum.Enum):
    keystroke = "keystroke"
    trace_point = "trace_point"
    item_shown = "item_shown"
    item_completed = "item_completed"
    hint_shown = "hint_shown"
    break_taken = "break_taken"


class AdaptationReasonCode(str, enum.Enum):
    accuracy_drop = "accuracy_drop"
    latency_rise = "latency_rise"
    fatigue = "fatigue"
    mastery_gain = "mastery_gain"
    accidental_taps = "accidental_taps"


class LevelStatus(str, enum.Enum):
    locked = "locked"
    active = "active"
    mastered = "mastered"


class RewardKind(str, enum.Enum):
    badge = "badge"
    world = "world"
    mascot_emotion = "mascot_emotion"
    background = "background"
    accessory = "accessory"


class RewardSource(str, enum.Enum):
    earned = "earned"
    purchased_with_coins = "purchased_with_coins"


class SubmissionStatus(str, enum.Enum):
    pending = "pending"
    in_progress = "in_progress"
    completed = "completed"


class ReportScope(str, enum.Enum):
    parent_daily = "parent_daily"
    parent_weekly = "parent_weekly"
    teacher_class = "teacher_class"


class AssetKind(str, enum.Enum):
    audio = "audio"
    image = "image"
    rive = "rive"
    font = "font"


class ConsentType(str, enum.Enum):
    data_processing = "data_processing"
    coppa_parent_consent = "coppa_parent_consent"