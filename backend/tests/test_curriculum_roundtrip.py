"""
Round-trip integration test: import → API → response parses cleanly.

For each level JSON file in shared/curriculum/:
  1. Run the importer CLI (dry-run) to confirm validation passes.
  2. Parse the JSON using CurriculumLevel to confirm schema acceptance.
  3. Confirm all items in all three languages have non-empty audio refs.

This test does NOT require a live DB; it exercises the schema validation
and importer logic in isolation using dry-run mode.
The second half (API → Dart model parse) is exercised by the Flutter
widget tests — listed here as a reference checkpoint only.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).parent.parent.parent.parent
SHARED_CURRICULUM = REPO_ROOT / "shared" / "curriculum"
BACKEND_DIR = Path(__file__).parent.parent


def _level_files() -> list[Path]:
    return sorted(SHARED_CURRICULUM.glob("level_*.json"))


@pytest.mark.skipif(
    not SHARED_CURRICULUM.exists(),
    reason="shared/curriculum/ directory not found",
)
class TestCurriculumRoundTrip:
    """Import-side round-trip: file → validator → importer dry-run."""

    def test_shared_curriculum_directory_exists(self) -> None:
        assert SHARED_CURRICULUM.is_dir(), f"Missing: {SHARED_CURRICULUM}"

    def test_all_16_level_files_present(self) -> None:
        files = _level_files()
        assert len(files) == 16, (
            f"Expected 16 level files in {SHARED_CURRICULUM}, found {len(files)}:\n"
            + "\n".join(f.name for f in files)
        )

    @pytest.mark.parametrize("level_num", range(1, 17))
    def test_level_schema_validates(self, level_num: int) -> None:
        from flexikeys.modules.curriculum.schemas import CurriculumLevel

        candidates = list(SHARED_CURRICULUM.glob(f"level_{level_num:02d}_*.json"))
        assert candidates, f"No file for level {level_num}"

        raw = json.loads(candidates[0].read_text(encoding="utf-8"))
        level = CurriculumLevel(**raw)
        assert level.level == level_num

    @pytest.mark.parametrize("level_num", range(1, 17))
    def test_all_items_have_audio_all_langs(self, level_num: int) -> None:
        from flexikeys.modules.curriculum.schemas import CurriculumLevel

        candidates = list(SHARED_CURRICULUM.glob(f"level_{level_num:02d}_*.json"))
        if not candidates:
            pytest.skip(f"No file for level {level_num}")

        raw = json.loads(candidates[0].read_text(encoding="utf-8"))
        level = CurriculumLevel(**raw)

        for lesson in level.lessons:
            for item in lesson.items:
                for lang, loc in item.l10n.items():
                    assert loc.audio, (
                        f"Level {level_num}, item {item.skill_key}, "
                        f"lang={lang}: empty audio"
                    )

    def test_importer_dry_run_passes(self) -> None:
        """Run the importer CLI in dry-run mode; expect exit code 0."""
        result = subprocess.run(
            [
                sys.executable,
                "-m",
                "flexikeys.tools.import_curriculum",
                str(SHARED_CURRICULUM),
                "--dry-run",
            ],
            cwd=BACKEND_DIR,
            capture_output=True,
            text=True,
        )
        assert result.returncode == 0, (
            f"import_curriculum --dry-run failed:\n"
            f"stdout: {result.stdout}\n"
            f"stderr: {result.stderr}"
        )

    @pytest.mark.parametrize("level_num", range(1, 17))
    def test_level_item_count_documented(self, level_num: int) -> None:
        """Each level must have at least 1 item per lesson."""
        from flexikeys.modules.curriculum.schemas import CurriculumLevel

        candidates = list(SHARED_CURRICULUM.glob(f"level_{level_num:02d}_*.json"))
        if not candidates:
            pytest.skip(f"No file for level {level_num}")

        raw = json.loads(candidates[0].read_text(encoding="utf-8"))
        level = CurriculumLevel(**raw)

        for lesson in level.lessons:
            assert len(lesson.items) >= 1, (
                f"Level {level_num} lesson '{lesson.slug}' has no items"
            )

    def test_uz_alphabet_o_apostrophe_handled(self) -> None:
        """o' and g' must appear as Uzbek text values in the level 1 letter lesson.

        Skill keys are language-agnostic ({lang}:letter:X); the UZ-specific
        letter text lives in item.l10n['uz'].text.
        """
        candidates = list(SHARED_CURRICULUM.glob("level_01_*.json"))
        assert candidates, "Missing level 01 file"

        raw = json.loads(candidates[0].read_text(encoding="utf-8"))

        # Parse via raw JSON (pydantic may not be available in this env)
        uz_texts = [
            item["l10n"]["uz"]["text"].lower()
            for lesson in raw["lessons"]
            for item in lesson["items"]
            if "uz" in item.get("l10n", {})
        ]
        has_o_apo = any("o'" in t for t in uz_texts)
        has_g_apo = any("g'" in t for t in uz_texts)
        assert has_o_apo, f"No o' in level 1 UZ text values: {uz_texts[:15]}"
        assert has_g_apo, f"No g' in level 1 UZ text values: {uz_texts[:15]}"