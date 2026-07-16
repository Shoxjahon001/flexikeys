"""PDF report generation.

HTML rendering is a pure function; WeasyPrint rendering is marked STUB.
Tests can verify HTML output without requiring WeasyPrint installed.
"""
from __future__ import annotations

from datetime import date
from typing import Any

import structlog

logger = structlog.get_logger()

# ── Copy map for "needs attention" framing across languages ───────────────────
# "could use extra practice" — never "struggling", never ranked.
_NEEDS_ATTENTION_LABEL: dict[str, str] = {
    "en": "could use extra practice",
    "uz": "qo'shimcha mashq tavsiya etiladi",
    "ru": "рекомендуется дополнительная практика",
}

_REPORT_TITLES: dict[str, dict[str, str]] = {
    "parent_weekly": {
        "en": "Weekly Progress Report",
        "uz": "Haftalik Taraqqiyot Hisoboti",
        "ru": "Еженедельный отчёт о прогрессе",  # noqa: RUF001
    },
    "teacher_class": {
        "en": "Class Progress Report",
        "uz": "Sinf Taraqqiyot Hisoboti",
        "ru": "Отчёт о прогрессе класса",  # noqa: RUF001
    },
}

_SECTION_LABELS: dict[str, dict[str, str]] = {
    "summary": {
        "en": "Summary",
        "uz": "Xulosa",
        "ru": "Сводка",
    },
    "mastered_skills": {
        "en": "Mastered Skills",
        "uz": "O'zlashtirilgan ko'nikmalar",
        "ru": "Освоенные навыки",
    },
    "needs_practice": {
        "en": "Areas for Practice",
        "uz": "Mashq talab qiladigan sohalar",
        "ru": "Области для практики",
    },
    "time_spent": {
        "en": "Time Spent",
        "uz": "Sarflangan vaqt",
        "ru": "Затраченное время",
    },
    "streak": {
        "en": "Practice Streak",
        "uz": "Muntazam mashq",
        "ru": "Серия занятий",
    },
    "min": {
        "en": "min",
        "uz": "daq",
        "ru": "мин",
    },
    "days": {
        "en": "days",
        "uz": "kun",
        "ru": "дней",
    },
    "roster": {
        "en": "Class Roster",
        "uz": "Sinf ro'yxati",
        "ru": "Список класса",
    },
    "student": {
        "en": "Student",
        "uz": "O'quvchi",
        "ru": "Учащийся",
    },
    "mastery": {
        "en": "Mastery",
        "uz": "O'zlashtirish",
        "ru": "Освоение",
    },
    "attention": {
        "en": "Note",
        "uz": "Eslatma",
        "ru": "Примечание",
    },
}


def _lbl(key: str, lang: str) -> str:
    return _SECTION_LABELS.get(key, {}).get(lang, _SECTION_LABELS.get(key, {}).get("en", key))


def render_parent_weekly_html(
    child_name: str,
    week_start: date,
    language: str,
    time_spent_min: float,
    streak_days: int,
    mastered_skills: list[str],
    areas_needing_practice: list[str],
) -> str:
    """Pure function — renders an HTML string for the parent weekly report.

    No PII beyond child display_name. Email and parent_id excluded.
    """
    lang = language if language in ("en", "uz", "ru") else "en"
    title = _REPORT_TITLES["parent_weekly"][lang]
    needs_label = _NEEDS_ATTENTION_LABEL[lang]

    mastered_items = "".join(f"<li>{s}</li>" for s in mastered_skills)
    practice_items = "".join(
        f"<li>{s} — <em>{needs_label}</em></li>" for s in areas_needing_practice
    )

    return f"""<!DOCTYPE html>
<html lang="{lang}">
<head>
  <meta charset="utf-8">
  <title>{title}</title>
  <style>
    body {{ font-family: Nunito, sans-serif; color: #4A5568; padding: 2rem; }}
    h1 {{ color: #4A5568; }}
    .section {{ margin-bottom: 1.5rem; }}
    .stat {{ display: inline-block; margin-right: 2rem; }}
    ul {{ padding-left: 1.2rem; }}
    li {{ margin-bottom: 0.3rem; }}
  </style>
</head>
<body>
  <h1>{title}</h1>
  <p><strong>{child_name}</strong> — {week_start.isoformat()}</p>

  <div class="section">
    <h2>{_lbl("summary", lang)}</h2>
    <span class="stat">
      {_lbl("time_spent", lang)}: <strong>{time_spent_min:.0f} {_lbl("min", lang)}</strong>
    </span>
    <span class="stat">
      {_lbl("streak", lang)}: <strong>{streak_days} {_lbl("days", lang)}</strong>
    </span>
  </div>

  <div class="section">
    <h2>{_lbl("mastered_skills", lang)}</h2>
    <ul>{mastered_items or "<li>—</li>"}</ul>
  </div>

  <div class="section">
    <h2>{_lbl("needs_practice", lang)}</h2>
    <ul>{practice_items or "<li>—</li>"}</ul>
  </div>
</body>
</html>"""


def render_teacher_class_html(
    class_name: str,
    report_date: date,
    language: str,
    students: list[dict[str, Any]],
) -> str:
    """Pure function — renders an HTML class report for teachers.

    Students list: [{display_name, mastery_score, needs_attention}]
    No parent contact data (email, phone) included.
    """
    lang = language if language in ("en", "uz", "ru") else "en"
    title = _REPORT_TITLES["teacher_class"][lang]
    needs_label = _NEEDS_ATTENTION_LABEL[lang]

    rows = ""
    for s in students:
        mastery_pct = f"{s.get('mastery_score', 0) * 100:.0f}%"
        note = needs_label if s.get("needs_attention") else ""
        rows += (
            f"<tr><td>{s.get('display_name', '')}</td>"
            f"<td>{mastery_pct}</td>"
            f"<td>{note}</td></tr>\n"
        )

    return f"""<!DOCTYPE html>
<html lang="{lang}">
<head>
  <meta charset="utf-8">
  <title>{title}</title>
  <style>
    body {{ font-family: Nunito, sans-serif; color: #4A5568; padding: 2rem; }}
    h1 {{ color: #4A5568; }}
    table {{ border-collapse: collapse; width: 100%; }}
    th, td {{ border: 1px solid #E2E8F0; padding: 0.5rem 1rem; text-align: left; }}
    th {{ background: #F7FAFC; }}
  </style>
</head>
<body>
  <h1>{title}</h1>
  <p><strong>{class_name}</strong> — {report_date.isoformat()}</p>

  <h2>{_lbl("roster", lang)}</h2>
  <table>
    <thead>
      <tr>
        <th>{_lbl("student", lang)}</th>
        <th>{_lbl("mastery", lang)}</th>
        <th>{_lbl("attention", lang)}</th>
      </tr>
    </thead>
    <tbody>
      {rows or '<tr><td colspan="3">—</td></tr>'}
    </tbody>
  </table>
</body>
</html>"""


def html_to_pdf(html: str) -> bytes:
    """Convert HTML string to PDF bytes via WeasyPrint.

    STUB: #51 — WeasyPrint requires system fonts and shared libraries.
    Install with: pip install weasyprint
    Fonts needed for Cyrillic: Noto Serif (noto-fonts), DejaVu
    Fonts needed for Uzbek Latin: same Noto fonts cover Latin + apostrophe
    """
    try:
        from weasyprint import HTML  # type: ignore[import]

        return HTML(string=html).write_pdf()
    except ImportError:
        logger.warning("weasyprint_not_installed_returning_html_bytes")
        return html.encode("utf-8")
