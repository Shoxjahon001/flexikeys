"""PDF report unit tests — tests HTML rendering without WeasyPrint."""
from __future__ import annotations

from datetime import date

from flexikeys.workers.pdf_report import (
    _NEEDS_ATTENTION_LABEL,
    render_parent_weekly_html,
    render_teacher_class_html,
)

# ── Parent weekly HTML rendering ──────────────────────────────────────────────


def test_parent_weekly_html_renders_en() -> None:
    html = render_parent_weekly_html(
        child_name="Alex",
        week_start=date(2026, 7, 7),
        language="en",
        time_spent_min=45.0,
        streak_days=5,
        mastered_skills=["Letter A", "Letter B"],
        areas_needing_practice=["Letter Z"],
    )
    assert "Alex" in html
    assert "2026-07-07" in html
    assert "45" in html
    assert "Letter A" in html
    assert "Letter Z" in html
    assert "Weekly Progress Report" in html


def test_parent_weekly_html_renders_uz() -> None:
    html = render_parent_weekly_html(
        child_name="Amir",
        week_start=date(2026, 7, 7),
        language="uz",
        time_spent_min=30.0,
        streak_days=3,
        mastered_skills=["A harfi"],
        areas_needing_practice=[],
    )
    assert "Amir" in html
    assert "Haftalik Taraqqiyot Hisoboti" in html
    # Uzbek-specific Latin characters (O' and other characters)
    assert "O'zlashtirilgan" in html or "Xulosa" in html


def test_parent_weekly_html_renders_ru() -> None:
    html = render_parent_weekly_html(
        child_name="Саша",
        week_start=date(2026, 7, 7),
        language="ru",
        time_spent_min=20.0,
        streak_days=2,
        mastered_skills=["Буква А"],  # noqa: RUF001
        areas_needing_practice=["Буква Щ"],
    )
    assert "Саша" in html
    assert "Еженедельный отчёт о прогрессе" in html  # noqa: RUF001
    # Буква А, Буква Щ — Cyrillic content in mastered/practice sections  # noqa: RUF003
    assert "Буква А" in html  # noqa: RUF001
    assert "Буква Щ" in html


def test_parent_weekly_html_cyrillic_glyphs() -> None:
    """HTML must contain Cyrillic characters for Russian reports."""
    html = render_parent_weekly_html(
        child_name="Миша",
        week_start=date(2026, 7, 7),
        language="ru",
        time_spent_min=15.0,
        streak_days=1,
        mastered_skills=[],
        areas_needing_practice=[],
    )
    cyrillic_chars = sum(1 for c in html if "Ѐ" <= c <= "ӿ")
    assert cyrillic_chars > 5, "Expected Cyrillic characters in Russian PDF template"


def test_parent_weekly_html_uzbek_latin_glyphs() -> None:
    """HTML must handle Uzbek Latin characters (apostrophe-based special chars)."""
    html = render_parent_weekly_html(
        child_name="O'g'il",
        week_start=date(2026, 7, 7),
        language="uz",
        time_spent_min=10.0,
        streak_days=1,
        mastered_skills=["O'zbek so'zi"],
        areas_needing_practice=["Sh harfi"],
    )
    assert "O'g'il" in html
    assert "O'zbek so'zi" in html
    assert "Sh harfi" in html


def test_parent_weekly_html_excludes_parent_email() -> None:
    """No email address must appear in the rendered HTML."""
    html = render_parent_weekly_html(
        child_name="Lee",
        week_start=date(2026, 7, 7),
        language="en",
        time_spent_min=25.0,
        streak_days=0,
        mastered_skills=[],
        areas_needing_practice=[],
    )
    assert "@" not in html


def test_parent_weekly_needs_attention_framing_en() -> None:
    """Practice areas must use the correct 'could use extra practice' framing."""
    html = render_parent_weekly_html(
        child_name="Sam",
        week_start=date(2026, 7, 7),
        language="en",
        time_spent_min=10.0,
        streak_days=1,
        mastered_skills=[],
        areas_needing_practice=["Letter Y"],
    )
    assert _NEEDS_ATTENTION_LABEL["en"] in html
    # Must NOT use stigmatizing copy
    assert "struggling" not in html.lower()
    assert "failing" not in html.lower()
    assert "behind" not in html.lower()


def test_parent_weekly_needs_attention_framing_ru() -> None:
    html = render_parent_weekly_html(
        child_name="Маша",
        week_start=date(2026, 7, 7),
        language="ru",
        time_spent_min=10.0,
        streak_days=1,
        mastered_skills=[],
        areas_needing_practice=["Буква Ю"],
    )
    assert _NEEDS_ATTENTION_LABEL["ru"] in html


# ── Teacher class HTML rendering ──────────────────────────────────────────────


def test_teacher_class_html_renders_en() -> None:
    html = render_teacher_class_html(
        class_name="Bluebirds",
        report_date=date(2026, 7, 7),
        language="en",
        students=[
            {"display_name": "Alex", "mastery_score": 0.85, "needs_attention": False},
            {"display_name": "Sam", "mastery_score": 0.35, "needs_attention": True},
        ],
    )
    assert "Bluebirds" in html
    assert "Alex" in html
    assert "Sam" in html
    assert "Class Progress Report" in html
    assert "85%" in html
    assert "35%" in html


def test_teacher_class_html_needs_attention_framing() -> None:
    """Teacher class report must use 'could use extra practice' not 'struggling'."""
    html = render_teacher_class_html(
        class_name="Room A",
        report_date=date(2026, 7, 7),
        language="en",
        students=[
            {"display_name": "Jo", "mastery_score": 0.3, "needs_attention": True},
        ],
    )
    assert _NEEDS_ATTENTION_LABEL["en"] in html
    assert "struggling" not in html.lower()


def test_teacher_class_html_excludes_parent_contact() -> None:
    """No email or phone must appear in the class report."""
    html = render_teacher_class_html(
        class_name="Room B",
        report_date=date(2026, 7, 7),
        language="en",
        students=[
            {"display_name": "Child A", "mastery_score": 0.7, "needs_attention": False},
        ],
    )
    assert "@" not in html
    assert "phone" not in html.lower()
    assert "email" not in html.lower()


def test_teacher_class_html_renders_ru() -> None:
    html = render_teacher_class_html(
        class_name="Класс 1А",  # noqa: RUF001
        report_date=date(2026, 7, 7),
        language="ru",
        students=[
            {"display_name": "Миша", "mastery_score": 0.6, "needs_attention": False},
        ],
    )
    assert "Класс 1А" in html  # noqa: RUF001
    assert "Миша" in html
    assert "Отчёт о прогрессе класса" in html  # noqa: RUF001


def test_teacher_class_html_empty_roster() -> None:
    html = render_teacher_class_html(
        class_name="Empty",
        report_date=date(2026, 7, 7),
        language="en",
        students=[],
    )
    assert "Empty" in html
    assert "<tbody>" in html
