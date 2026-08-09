# "My Voice" — AAC Module Phase 4: Parent Dashboard

> Status: **Approved.** All three open questions below were resolved after
> Phase 5 — see `docs/aac_phase5_polish_qa.md` "Resolved open questions":
> voice recording was added (not left typed-only), `FkCard` was fixed
> globally (not left as a local patch), and custom cards stayed
> single-child (no change).
> Companion to Phases 0-3. Covers the new "My Voice" tab in the parent
> dashboard, custom card management, and settings — the last piece before
> Phase 5's polish/QA pass.

## Decisions made this phase (confirmed with you before building)

Two capabilities the original spec asked for needed a new dependency or new
risk surface, so I asked rather than deciding silently:

1. **Custom card photos** → **added `image_picker`**. Gallery + camera,
   with `NSPhotoLibraryUsageDescription`/`NSCameraUsageDescription` (iOS)
   and `CAMERA` permission (Android) added.
2. **"Record own voice OR type text for TTS"** → **typed text only**. No
   audio-recording package was added — every custom card's "voice" is the
   typed label read aloud via the existing `AacAudioPlayer`/`TtsService`
   fallback (already fully working, no new permission, works in all three
   languages immediately). Recording is a real, larger follow-up (new
   package, mic permission, playback UI) if you want it later.

## Backend: `GET /aac/stats`

New endpoint alongside Phase 3's `/aac/compose-sentence` and `/aac/insights`
in the same `modules/aac/` — parent-auth, ownership-checked, rate-limited
(20/60s, no LLM cost involved so a looser limit than the AI endpoints).

Returns two shapes, both computed with plain SQL aggregation (`GROUP BY`),
no LLM involved:
- `today`: `(card_id, category, count)` — powers the "Water ×12" stat chips.
- `trend`: `(date, category, count)` for the last 7 UTC calendar days —
  powers the bar chart.

**Card labels are deliberately not in this response** — vocabulary text
only exists in the bundled Flutter asset (Phase 1's decision), never synced
to the backend. The client maps `card_id → label/glyph` itself via
`AacCardRepository`, which it already loads for the child-facing screens.

Cached 5 minutes per child (short — Today's counts change all day, unlike
Phase 3's insights which cache for a full day).

## Flutter: the "My Voice" tab

Added as `ParentHomeScreen`'s 4th tab (Home, Progress, **My Voice**, Ask
AI — shifted "Ask AI" from index 2 to 3; the one existing deep-link call
site, `profile_screen.dart`'s `_openAssistant()`, was updated to match).

`AacDashboardScreen` (`lib/features/aac/presentation/parent/`) mirrors
`_HomeTab`'s existing shape exactly: no own Scaffold, a `ListView` of cards,
`FutureProvider.family` + `.when()` for loading/error states — same pattern
as `childSummaryProvider`/`adaptationsProvider`. Shows:
- **Today**: stat chips (emoji + label + count), category-tinted.
- **This Week**: a `BarChart` (fl_chart, already a dependency, matches the
  spec's "soft rounded bars, category colors" — each day's bar takes the
  color of whichever category dominated that day's taps).
- **Insights**: Phase 3's `/aac/insights` cards, with the medical disclaimer
  shown when present.
- Header icons to **Manage Cards** and **Settings**.

## Card Manager (`AacCardManagerScreen`)

List + add/edit/delete for `AacCustomCardStore` (built in Phase 1, unused
until now). The add/edit form: photo (optional, `image_picker` → copied
into `ApplicationDocumentsDirectory/aac_custom_photos/` so it survives
restarts, unlike the picker's own temp path), a label field, and a category
chip picker, with a live `AacCard` preview.

**The typed label is used as both the card's label and its spoken
sentence, verbatim** — no assumed "I want {noun}" grammar. Same reasoning
as Phase 3's Sentence Strip fallback: a parent typing "Rex" or "cold" in
any of the three languages shouldn't be silently wrapped in an
English-shaped sentence template.

**Custom cards are local-only and not child-scoped** — consistent with how
`UserService`/`ProgressStore` and the rest of this app's local-only stores
already work off a single "active child" per device, not a `child_id` key.
Flagging this as a real limitation for multi-child households, not a
decision I want to make silently permanent: whoever picks up multi-child
support on this device later will need to key this store too.

### A gap this phase fixed along the way: custom photos weren't showing up anywhere

Building the Card Manager surfaced a real correctness bug in the
already-shipped Phase 2 screens: `AacCardGridScreen`, `AacFringeScreen`,
`AacSentenceStripScreen`, and `AacConfirmationScreen` all rendered every
card's glyph via `aacGlyph(emojiForCard(card.id))` directly — which has no
way to know about a card's `customPhotoPath`. A parent-added photo of
grandma would never have appeared anywhere a child could actually tap it.

Fixed by adding `glyphForCard(AacCardDef card)` to `aac_glyphs.dart` (photo
when set, emoji fallback otherwise) and switching every card-rendering call
site to use it. `AacConfirmationScreen.glyphEmoji: String` was widened to
`glyph: Widget` (matching `AacCard.glyph`'s existing pattern from Phase 2)
so the confirmation overlay — the moment that matters most — shows the
real photo too. Fringe options are unaffected (`AacFringeOption` has no
photo field in the data model; only top-level cards can be custom).

## Settings (`AacParentSettingsScreen`)

Wires up controls that already had a model/store but no UI:
- **Progression level** (1-4) — writes to the new `AacProgressionStore`
  (the `AacProgressionState` model existed since Phase 1, was never
  persisted until this screen needed something to read/write).
- **Card size** (L/XL/XXL), **dwell-time** (+ duration slider),
  **high contrast**, **reduced motion** — all `AacSettingsStore`, built in
  Phase 2, now finally has a UI.

Language/voice are intentionally **not** duplicated here — they're the
app's existing learning-language setting (`UserService`), not a
second AAC-specific language switch.

A real, unrelated bug surfaced while testing this screen: `ListTile`/
`SwitchListTile` inside `FkCard` throws a framework assertion
("background color or ink splashes may be invisible") because `FkCard`
paints its background via a plain `Container`, not a `Material` ancestor.
This is a **pre-existing gap affecting `settings_screen.dart` too** (same
`ListTile`-in-`FkCard` pattern there), just never caught because that
screen has no test coverage exercising it. Fixed locally here (wrapped the
accessibility switches in a transparent `Material`) rather than changing
the shared `FkCard` atom, which is out of this phase's scope and would need
visual verification across every existing `FkCard` + `ListTile` usage
before I'd trust changing it blind.

## Verification

**Backend**: `ruff check` clean, `mypy` clean (strict), `pytest` —
16 tests in `test_aac.py` (13 from Phase 3 + 3 new `get_stats` tests), all
pass.

**Flutter**: `flutter analyze` clean, `flutter test` — 194/194 pass
(17 new tests this phase: `AacProgressionStore` (3), `aac_dashboard_
provider` JSON parsing (4), `glyphForCard` (2), `AacCardManagerScreen` (3),
`AacParentSettingsScreen` (5)). `AacDashboardScreen` itself has no direct
widget test — it's the one screen in this phase that depends on live HTTP
responses via `ApiClient`, which has no dependency-injection seam for
mocking (unlike the backend's `httpx.MockTransport` pattern). Flagging this
as a real test gap, not silently skipping it: the sub-widgets it composes
(`_TodayStats`, `_TrendChart`, `_InsightsSection`) are private to the file
and untestable in isolation as currently structured. Worth revisiting if
`ApiClient` ever gets a test seam for other reasons — not proposing adding
one just for this.

## Open questions for you before Phase 5

1. Custom-card voice recording — worth the new dependency later, or is
   typed-text-to-speech the permanent answer?
2. `FkCard` + `ListTile` Material gap — worth fixing at the shared-atom
   level (benefits `settings_screen.dart` too), or leave each call site to
   patch locally as it's discovered?
3. Multi-child custom cards — worth scoping `AacCustomCardStore` by child
   now, or wait until multi-child support is a real, scheduled need?
