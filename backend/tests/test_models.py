"""Round-trip tests: insert one row per table, query it back, assert equality."""
from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession


# ── Helpers ──────────────────────────────────────────────────────────────────

def uid() -> uuid.UUID:
    return uuid.uuid4()


NOW = datetime.now(UTC)


# ── Identity & accounts ───────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_user_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.core.enums import UserRole

    u = User(id=uid(), email=f"{uid()}@test.example", role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    await db_session.refresh(u)

    fetched = await db_session.get(User, u.id)
    assert fetched is not None
    assert fetched.role == UserRole.parent


@pytest.mark.asyncio
async def test_oauth_identity_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User, OAuthIdentity
    from flexikeys.core.enums import UserRole, OAuthProvider

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()

    o = OAuthIdentity(id=uid(), user_id=u.id, provider=OAuthProvider.google, provider_subject=str(uid()))
    db_session.add(o)
    await db_session.flush()
    await db_session.refresh(o)

    fetched = await db_session.get(OAuthIdentity, o.id)
    assert fetched is not None
    assert fetched.provider == OAuthProvider.google


@pytest.mark.asyncio
async def test_child_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.core.enums import UserRole, LearningLanguage

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()

    c = Child(id=uid(), parent_id=u.id, display_name="Testchild", birth_year=2020,
              learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()
    await db_session.refresh(c)

    fetched = await db_session.get(Child, c.id)
    assert fetched is not None
    assert fetched.display_name == "Testchild"


@pytest.mark.asyncio
async def test_parental_consent_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.auth.models import ParentalConsent
    from flexikeys.core.enums import UserRole, LearningLanguage, ConsentType

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    c = Child(id=uid(), parent_id=u.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()

    pc = ParentalConsent(id=uid(), child_id=c.id, consent_type=ConsentType.data_processing, granted_at=NOW)
    db_session.add(pc)
    await db_session.flush()
    await db_session.refresh(pc)

    fetched = await db_session.get(ParentalConsent, pc.id)
    assert fetched is not None
    assert fetched.consent_type == ConsentType.data_processing


@pytest.mark.asyncio
async def test_refresh_token_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.auth.models import RefreshToken
    from flexikeys.core.enums import UserRole

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()

    rt = RefreshToken(id=uid(), user_id=u.id, token_hash=str(uid()), expires_at=NOW + timedelta(days=30))
    db_session.add(rt)
    await db_session.flush()
    await db_session.refresh(rt)

    fetched = await db_session.get(RefreshToken, rt.id)
    assert fetched is not None
    assert fetched.user_id == u.id


# ── Curriculum ────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_asset_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.curriculum.models import Asset
    from flexikeys.core.enums import AssetKind

    a = Asset(id=uid(), kind=AssetKind.audio, storage_key=f"audio/{uid()}.mp3",
              mime="audio/mpeg", bytes=12345, checksum="abc123")
    db_session.add(a)
    await db_session.flush()
    await db_session.refresh(a)

    fetched = await db_session.get(Asset, a.id)
    assert fetched is not None
    assert fetched.kind == AssetKind.audio


@pytest.mark.asyncio
async def test_curriculum_version_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.curriculum.models import CurriculumVersion

    cv = CurriculumVersion(id=uid(), version=f"test-{uid()}", checksum="x")
    db_session.add(cv)
    await db_session.flush()
    await db_session.refresh(cv)

    fetched = await db_session.get(CurriculumVersion, cv.id)
    assert fetched is not None
    assert fetched.checksum == "x"


@pytest.mark.asyncio
async def test_level_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.curriculum.models import CurriculumVersion, Level

    cv = CurriculumVersion(id=uid(), version=f"t-{uid()}", checksum="y")
    db_session.add(cv)
    await db_session.flush()

    lvl = Level(id=uid(), version_id=cv.id, ordinal=1, slug="letters")
    db_session.add(lvl)
    await db_session.flush()
    await db_session.refresh(lvl)

    fetched = await db_session.get(Level, lvl.id)
    assert fetched is not None
    assert fetched.slug == "letters"


@pytest.mark.asyncio
async def test_lesson_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.curriculum.models import CurriculumVersion, Level, Lesson
    from flexikeys.core.enums import LessonType

    cv = CurriculumVersion(id=uid(), version=f"t-{uid()}", checksum="z")
    db_session.add(cv)
    await db_session.flush()
    lvl = Level(id=uid(), version_id=cv.id, ordinal=1, slug="letters")
    db_session.add(lvl)
    await db_session.flush()

    les = Lesson(id=uid(), level_id=lvl.id, ordinal=1, slug="type-letters", lesson_type=LessonType.typing)
    db_session.add(les)
    await db_session.flush()
    await db_session.refresh(les)

    fetched = await db_session.get(Lesson, les.id)
    assert fetched is not None
    assert fetched.lesson_type == LessonType.typing


@pytest.mark.asyncio
async def test_item_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.curriculum.models import CurriculumVersion, Level, Lesson, Item
    from flexikeys.core.enums import LessonType, ItemType

    cv = CurriculumVersion(id=uid(), version=f"t-{uid()}", checksum="z")
    db_session.add(cv)
    await db_session.flush()
    lvl = Level(id=uid(), version_id=cv.id, ordinal=1, slug="letters")
    db_session.add(lvl)
    await db_session.flush()
    les = Lesson(id=uid(), level_id=lvl.id, ordinal=1, slug="sl", lesson_type=LessonType.typing)
    db_session.add(les)
    await db_session.flush()

    item = Item(id=uid(), lesson_id=les.id, ordinal=1, item_type=ItemType.letter,
                skill_key="en:letter:a", payload={"letter": "A"})
    db_session.add(item)
    await db_session.flush()
    await db_session.refresh(item)

    fetched = await db_session.get(Item, item.id)
    assert fetched is not None
    assert fetched.skill_key == "en:letter:a"
    assert fetched.payload == {"letter": "A"}


@pytest.mark.asyncio
async def test_item_localization_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.curriculum.models import (
        CurriculumVersion, Level, Lesson, Item, ItemLocalization,
    )
    from flexikeys.core.enums import LessonType, ItemType

    cv = CurriculumVersion(id=uid(), version=f"t-{uid()}", checksum="z")
    db_session.add(cv)
    await db_session.flush()
    lvl = Level(id=uid(), version_id=cv.id, ordinal=1, slug="letters")
    db_session.add(lvl)
    await db_session.flush()
    les = Lesson(id=uid(), level_id=lvl.id, ordinal=1, slug="sl", lesson_type=LessonType.typing)
    db_session.add(les)
    await db_session.flush()
    item = Item(id=uid(), lesson_id=les.id, ordinal=1, item_type=ItemType.letter, skill_key="en:letter:b")
    db_session.add(item)
    await db_session.flush()

    loc = ItemLocalization(id=uid(), item_id=item.id, language="en", text="B")
    db_session.add(loc)
    await db_session.flush()
    await db_session.refresh(loc)

    fetched = await db_session.get(ItemLocalization, loc.id)
    assert fetched is not None
    assert fetched.text == "B"
    assert fetched.language == "en"


# ── Sessions ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_learning_session_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.sessions.models import LearningSession
    from flexikeys.core.enums import UserRole, LearningLanguage

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    c = Child(id=uid(), parent_id=u.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()

    ls = LearningSession(id=uid(), child_id=c.id, language="en",
                         device_info={"platform": "android"}, client_version="1.0.0")
    db_session.add(ls)
    await db_session.flush()
    await db_session.refresh(ls)

    fetched = await db_session.get(LearningSession, ls.id)
    assert fetched is not None
    assert fetched.language == "en"
    assert fetched.device_info == {"platform": "android"}


@pytest.mark.asyncio
async def test_interaction_event_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.sessions.models import LearningSession, InteractionEvent
    from flexikeys.core.enums import UserRole, LearningLanguage, EventType

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    c = Child(id=uid(), parent_id=u.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()
    ls = LearningSession(id=uid(), child_id=c.id, language="en")
    db_session.add(ls)
    await db_session.flush()

    occurred = datetime(2026, 7, 10, 12, 0, 0, tzinfo=UTC)
    ev = InteractionEvent(
        session_id=ls.id,
        occurred_at=occurred,
        event_type=EventType.keystroke,
        skill_key="en:letter:a",
        payload={"target": "a", "actual": "a", "latency_ms": 350},
    )
    db_session.add(ev)
    await db_session.flush()

    result = await db_session.execute(
        select(InteractionEvent).where(InteractionEvent.session_id == ls.id)
    )
    events = result.scalars().all()
    assert len(events) == 1
    assert events[0].event_type == EventType.keystroke
    assert events[0].payload == {"target": "a", "actual": "a", "latency_ms": 350}


# ── Adaptive ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_skill_mastery_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.adaptive.models import SkillMastery
    from flexikeys.core.enums import UserRole, LearningLanguage

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    c = Child(id=uid(), parent_id=u.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()

    sm = SkillMastery(id=uid(), child_id=c.id, language="en", skill_key="en:letter:a",
                      attempts=10, correct=8)
    db_session.add(sm)
    await db_session.flush()
    await db_session.refresh(sm)

    fetched = await db_session.get(SkillMastery, sm.id)
    assert fetched is not None
    assert fetched.attempts == 10
    assert fetched.correct == 8


@pytest.mark.asyncio
async def test_adaptation_profile_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.adaptive.models import AdaptationProfile
    from flexikeys.core.enums import UserRole, LearningLanguage

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    c = Child(id=uid(), parent_id=u.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()

    params = {"key_scale": 1.3, "dwell_time_ms": 100, "hint_level": 1}
    ap = AdaptationProfile(id=uid(), child_id=c.id, params=params, version=2)
    db_session.add(ap)
    await db_session.flush()
    await db_session.refresh(ap)

    fetched = await db_session.get(AdaptationProfile, ap.id)
    assert fetched is not None
    assert fetched.params["key_scale"] == 1.3
    assert fetched.version == 2


@pytest.mark.asyncio
async def test_adaptation_change_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.adaptive.models import AdaptationChange
    from flexikeys.core.enums import UserRole, LearningLanguage, AdaptationReasonCode

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    c = Child(id=uid(), parent_id=u.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()

    ac = AdaptationChange(id=uid(), child_id=c.id, param="key_scale",
                          old_value="1.0", new_value="1.3",
                          reason_code=AdaptationReasonCode.accuracy_drop,
                          explanation_key="key_scale.increased.accuracy_drop")
    db_session.add(ac)
    await db_session.flush()
    await db_session.refresh(ac)

    fetched = await db_session.get(AdaptationChange, ac.id)
    assert fetched is not None
    assert fetched.reason_code == AdaptationReasonCode.accuracy_drop
    assert fetched.new_value == "1.3"


@pytest.mark.asyncio
async def test_repetition_queue_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.adaptive.models import RepetitionQueue
    from flexikeys.core.enums import UserRole, LearningLanguage

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    c = Child(id=uid(), parent_id=u.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()

    due = datetime(2026, 7, 15, tzinfo=UTC)
    rq = RepetitionQueue(id=uid(), child_id=c.id, language="en",
                         skill_key="en:letter:b", due_at=due)
    db_session.add(rq)
    await db_session.flush()
    await db_session.refresh(rq)

    fetched = await db_session.get(RepetitionQueue, rq.id)
    assert fetched is not None
    assert fetched.skill_key == "en:letter:b"


# ── Progress & rewards ────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_level_progress_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.curriculum.models import CurriculumVersion, Level
    from flexikeys.modules.progress.models import LevelProgress
    from flexikeys.core.enums import UserRole, LearningLanguage, LevelStatus

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    c = Child(id=uid(), parent_id=u.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()
    cv = CurriculumVersion(id=uid(), version=f"t-{uid()}", checksum="z")
    db_session.add(cv)
    await db_session.flush()
    lvl = Level(id=uid(), version_id=cv.id, ordinal=1, slug="letters")
    db_session.add(lvl)
    await db_session.flush()

    lp = LevelProgress(id=uid(), child_id=c.id, language="en", level_id=lvl.id, status=LevelStatus.active)
    db_session.add(lp)
    await db_session.flush()
    await db_session.refresh(lp)

    fetched = await db_session.get(LevelProgress, lp.id)
    assert fetched is not None
    assert fetched.status == LevelStatus.active


@pytest.mark.asyncio
async def test_daily_activity_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.progress.models import DailyActivity
    from flexikeys.core.enums import UserRole, LearningLanguage

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    c = Child(id=uid(), parent_id=u.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()

    da = DailyActivity(id=uid(), child_id=c.id, date=date(2026, 7, 10),
                       seconds_active=300, items_completed=12)
    db_session.add(da)
    await db_session.flush()
    await db_session.refresh(da)

    fetched = await db_session.get(DailyActivity, da.id)
    assert fetched is not None
    assert fetched.seconds_active == 300
    assert fetched.items_completed == 12


@pytest.mark.asyncio
async def test_wallet_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.rewards.models import Wallet
    from flexikeys.core.enums import UserRole, LearningLanguage

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    c = Child(id=uid(), parent_id=u.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()

    w = Wallet(child_id=c.id, coins=5, stars=2)
    db_session.add(w)
    await db_session.flush()
    await db_session.refresh(w)

    fetched = await db_session.get(Wallet, c.id)
    assert fetched is not None
    assert fetched.coins == 5
    assert fetched.stars == 2


@pytest.mark.asyncio
async def test_reward_definition_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.rewards.models import RewardDefinition
    from flexikeys.core.enums import RewardKind

    rd = RewardDefinition(id=uid(), kind=RewardKind.badge, slug=f"badge-{uid()}")
    db_session.add(rd)
    await db_session.flush()
    await db_session.refresh(rd)

    fetched = await db_session.get(RewardDefinition, rd.id)
    assert fetched is not None
    assert fetched.kind == RewardKind.badge


@pytest.mark.asyncio
async def test_reward_grant_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.rewards.models import RewardDefinition, RewardGrant
    from flexikeys.core.enums import UserRole, LearningLanguage, RewardKind, RewardSource

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    c = Child(id=uid(), parent_id=u.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()
    rd = RewardDefinition(id=uid(), kind=RewardKind.badge, slug=f"badge-{uid()}")
    db_session.add(rd)
    await db_session.flush()

    rg = RewardGrant(id=uid(), child_id=c.id, reward_definition_id=rd.id, source=RewardSource.earned)
    db_session.add(rg)
    await db_session.flush()
    await db_session.refresh(rg)

    fetched = await db_session.get(RewardGrant, rg.id)
    assert fetched is not None
    assert fetched.source == RewardSource.earned


# ── Teacher & classroom ───────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_class_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.teacher.models import Class
    from flexikeys.core.enums import UserRole

    u = User(id=uid(), role=UserRole.teacher)
    db_session.add(u)
    await db_session.flush()

    cls = Class(id=uid(), teacher_id=u.id, name="Test Class", join_code=str(uid())[:8].upper())
    db_session.add(cls)
    await db_session.flush()
    await db_session.refresh(cls)

    fetched = await db_session.get(Class, cls.id)
    assert fetched is not None
    assert fetched.name == "Test Class"


@pytest.mark.asyncio
async def test_class_enrollment_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.teacher.models import Class, ClassEnrollment
    from flexikeys.core.enums import UserRole, LearningLanguage

    teacher = User(id=uid(), role=UserRole.teacher)
    db_session.add(teacher)
    await db_session.flush()
    parent = User(id=uid(), role=UserRole.parent)
    db_session.add(parent)
    await db_session.flush()
    c = Child(id=uid(), parent_id=parent.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()
    cls = Class(id=uid(), teacher_id=teacher.id, name="C", join_code=str(uid())[:8].upper())
    db_session.add(cls)
    await db_session.flush()

    enr = ClassEnrollment(id=uid(), class_id=cls.id, child_id=c.id)
    db_session.add(enr)
    await db_session.flush()
    await db_session.refresh(enr)

    fetched = await db_session.get(ClassEnrollment, enr.id)
    assert fetched is not None
    assert fetched.class_id == cls.id


@pytest.mark.asyncio
async def test_assignment_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.curriculum.models import CurriculumVersion, Level
    from flexikeys.modules.teacher.models import Class, Assignment
    from flexikeys.core.enums import UserRole

    teacher = User(id=uid(), role=UserRole.teacher)
    db_session.add(teacher)
    await db_session.flush()
    cls = Class(id=uid(), teacher_id=teacher.id, name="C", join_code=str(uid())[:8].upper())
    db_session.add(cls)
    await db_session.flush()
    cv = CurriculumVersion(id=uid(), version=f"t-{uid()}", checksum="z")
    db_session.add(cv)
    await db_session.flush()
    lvl = Level(id=uid(), version_id=cv.id, ordinal=1, slug="letters")
    db_session.add(lvl)
    await db_session.flush()

    asgn = Assignment(id=uid(), class_id=cls.id, level_id=lvl.id, instructions="Practice A-Z")
    db_session.add(asgn)
    await db_session.flush()
    await db_session.refresh(asgn)

    fetched = await db_session.get(Assignment, asgn.id)
    assert fetched is not None
    assert fetched.instructions == "Practice A-Z"


@pytest.mark.asyncio
async def test_assignment_submission_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.children.models import Child
    from flexikeys.modules.teacher.models import Class, Assignment, AssignmentSubmission
    from flexikeys.core.enums import UserRole, LearningLanguage, SubmissionStatus

    teacher = User(id=uid(), role=UserRole.teacher)
    db_session.add(teacher)
    await db_session.flush()
    parent = User(id=uid(), role=UserRole.parent)
    db_session.add(parent)
    await db_session.flush()
    c = Child(id=uid(), parent_id=parent.id, display_name="X", learning_language=LearningLanguage.en)
    db_session.add(c)
    await db_session.flush()
    cls = Class(id=uid(), teacher_id=teacher.id, name="C", join_code=str(uid())[:8].upper())
    db_session.add(cls)
    await db_session.flush()
    asgn = Assignment(id=uid(), class_id=cls.id)
    db_session.add(asgn)
    await db_session.flush()

    sub = AssignmentSubmission(id=uid(), assignment_id=asgn.id, child_id=c.id, status=SubmissionStatus.pending)
    db_session.add(sub)
    await db_session.flush()
    await db_session.refresh(sub)

    fetched = await db_session.get(AssignmentSubmission, sub.id)
    assert fetched is not None
    assert fetched.status == SubmissionStatus.pending


# ── Platform ──────────────────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_ai_conversation_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.ai_assistant.models import AiConversation
    from flexikeys.core.enums import UserRole

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()

    conv = AiConversation(id=uid(), parent_user_id=u.id, title="How is Aisha progressing?")
    db_session.add(conv)
    await db_session.flush()
    await db_session.refresh(conv)

    fetched = await db_session.get(AiConversation, conv.id)
    assert fetched is not None
    assert fetched.title == "How is Aisha progressing?"


@pytest.mark.asyncio
async def test_ai_message_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.ai_assistant.models import AiConversation, AiMessage
    from flexikeys.core.enums import UserRole

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()
    conv = AiConversation(id=uid(), parent_user_id=u.id)
    db_session.add(conv)
    await db_session.flush()

    msg = AiMessage(id=uid(), conversation_id=conv.id, role="user", content="Tell me more")
    db_session.add(msg)
    await db_session.flush()
    await db_session.refresh(msg)

    fetched = await db_session.get(AiMessage, msg.id)
    assert fetched is not None
    assert fetched.content == "Tell me more"
    assert fetched.role == "user"


@pytest.mark.asyncio
async def test_notification_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.users.models import User
    from flexikeys.modules.notifications.models import Notification
    from flexikeys.core.enums import UserRole

    u = User(id=uid(), role=UserRole.parent)
    db_session.add(u)
    await db_session.flush()

    notif = Notification(id=uid(), user_id=u.id, kind="progress_milestone",
                         payload={"level": 1, "child": "Aisha"})
    db_session.add(notif)
    await db_session.flush()
    await db_session.refresh(notif)

    fetched = await db_session.get(Notification, notif.id)
    assert fetched is not None
    assert fetched.kind == "progress_milestone"
    assert fetched.payload == {"level": 1, "child": "Aisha"}


@pytest.mark.asyncio
async def test_report_round_trip(db_session: AsyncSession) -> None:
    from flexikeys.modules.parent.models import Report
    from flexikeys.core.enums import ReportScope

    r = Report(id=uid(), scope=ReportScope.parent_weekly,
               subject_id=uid(), period="2026-W28",
               payload={"mastery_avg": 0.72, "sessions": 5})
    db_session.add(r)
    await db_session.flush()
    await db_session.refresh(r)

    fetched = await db_session.get(Report, r.id)
    assert fetched is not None
    assert fetched.scope == ReportScope.parent_weekly
    assert fetched.payload["sessions"] == 5
