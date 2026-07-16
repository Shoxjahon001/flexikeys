# Phase 05 — Curriculum Content Pipeline & Localization

## Prerequisites
Phases 01–04.

## Goal
All 16 levels authored as versioned, localized content in English, Uzbek (Latin), and Russian, served through the curriculum API, with a media pipeline for audio and images.

## 1. Content Format (`shared/curriculum/`)
Versioned JSON (one file per level), schema-validated (publish a JSON Schema + Pydantic model):
```json
{
  "level": 6, "slug": "animals",
  "lessons": [{
    "slug": "farm-animals", "type": "typing",
    "items": [{
      "type": "word", "skill_key": "{lang}:word:cow",
      "l10n": {
        "en": {"text": "Cow", "audio": "audio/en/cow.mp3", "sound": "audio/fx/cow_moo.mp3", "image": "img/animals/cow.webp"},
        "uz": {"text": "Sigir", "audio": "audio/uz/sigir.mp3", "sound": "audio/fx/cow_moo.mp3", "image": "img/animals/cow.webp"},
        "ru": {"text": "Корова", "audio": "audio/ru/korova.mp3", "sound": "audio/fx/cow_moo.mp3", "image": "img/animals/cow.webp"}
      }
    }]
  }]
}
```

## 2. Author the Content (real content, not lorem ipsum)
Write complete, age-appropriate item lists for all 16 levels in all three languages. Respect each language's alphabet: Uzbek Latin (o', g', sh, ch, ng), Russian Cyrillic (33 letters) — Level 1 differs per language, and `skill_key`s are per-language. Sequence letters by frequency/ease, not alphabetically. Levels: 1 Letters, 2 Numbers, 3 Shapes, 4 Colors, 5 Family, 6 Animals (with animal sounds), 7 Fruits, 8 Vegetables, 9 Toys, 10 Transport, 11 Body Parts, 12 Clothes, 13 Nature, 14 Simple Words (3–5 letters, from already-mastered letters only — enforce this constraint in the validator), 15 Sentences (2–4 words), 16 Stories (4–6 page micro-stories with one typed word per page). Drawing lessons interleaved: trace paths defined as normalized point sequences in item payloads for letters, numbers, shapes, plus flowers/clouds/animals outlines, connect-dots, and simple mazes.

## 3. Importer & API
- `python -m flexikeys.tools.import_curriculum shared/curriculum/` → validates, diffs against current version, writes new `curriculum_version` transactionally.
- API (child token): `GET /curriculum/levels?lang=`, `GET /curriculum/levels/{slug}/lessons`, `GET /lessons/{id}` (items with signed asset URLs). Redis-cached with version-based invalidation. `GET /curriculum/next` — the adaptive engine's item selector (Phase 04 repetition + gating) packaged as "next lesson plan" for the client.

## 4. Media Pipeline
- `modules/media`: upload to S3/minio, checksum dedup, signed GET URLs, image variant generation (webp, 2 sizes).
- TTS generation tool `flexikeys.tools.generate_tts` behind a `TtsProvider` interface (implement provider adapter reading `TTS_PROVIDER` env; if no key present, generate silent placeholder files and log loudly — mark `# STUB:` only at the provider-key level, the pipeline itself is real). Voice direction documented: warm, calm, professional child voice, slow pace; letters pronounced, words pronounced, animals: sound first, then word.
- App-side `AudioService` (just_audio): sequential queue (moo → "Cow"), preload next item's assets, cache to disk (drift-indexed), volume-safe defaults.

## 5. App l10n
Complete ARB files (en/uz/ru) for all UI + mascot copy catalog (all expressions × contexts, effort-based praise only, reviewed against the copy rules in CLAUDE.md). UI language and learning language are separate settings; both switchable at runtime without restart.

## Acceptance Criteria
- [ ] Validator rejects: missing language, missing audio ref, Level 14+ words using unintroduced letters
- [ ] All 16 levels import cleanly; item counts per level documented
- [ ] Curriculum API serves localized lessons with signed URLs; cached responses invalidate on new version
- [ ] Alphabet correctness spot-checked per language (uz: o'/g' handled as single skill units)
- [ ] App switches learning language end-to-end: text, audio queue, progress scope
- [ ] Round-trip test: import → API → Dart models parse every level without error
