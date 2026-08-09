# "My Voice" — AAC Module Phase 3: AI Layer

> Status: **Approved.** Open question #1 below was resolved after Phase 5 —
> see `docs/aac_phase5_polish_qa.md` "Resolved open questions" for the
> implementation (AI polish pass + validator added to `generate_insights`).
> Companion to `docs/aac_design_system.md` (Phase 0) and
> `docs/aac_phase1_architecture.md` (Phase 1). Covers the backend AI layer
> (`backend/src/flexikeys/modules/aac/`) and the Flutter wiring into the
> Sentence Strip screen built in Phase 2.

## Decisions confirmed this phase

### `llm_provider.py` → `services/ai_service.py`

The Parent Dashboard AI Assistant feature (built earlier, unrelated task)
already has a working `AnthropicProvider` — full Messages API translation,
tool-use support, graceful degradation — living inside
`modules/ai_assistant/`. This phase needed the same client for sentence
composition, so rather than duplicate ~150 lines of wire-format translation
into `modules/aac/`, the provider moved to `services/ai_service.py` — a
true provider-agnostic shared service, matching what CLAUDE.md's tech-stack
table already names ("AI: Provider-agnostic `ai_service` module"). Both
`ai_assistant` and `aac` now import from the same place; `ai_assistant`'s
own tests were split accordingly (`tests/test_ai_service.py` for the
provider/translation logic, `tests/test_ai_assistant.py` keeps the
domain-specific tests: medical keywords, PII exclusion, suggested
activities).

Two small additions rode along with the move, since both consumers need
them:
- **`ChatCompletion.degraded: bool`** — `StubProvider` and every
  `AnthropicProvider` failure path (network error, non-200, unparseable
  response) now set this explicitly, so a consumer can detect "this isn't a
  real completion" without string-matching the canned message text.
  `compose_sentence` uses this to decide when to fall back to the template.
- **`MEDICAL_DISCLAIMER`** — promoted from a private constant in
  `ai_assistant/service.py` to a shared public one, so the exact wording
  (CLAUDE.md rule 7) can never drift between the two surfaces that show it.
- **Cost logging** — `AnthropicProvider.complete()` now logs
  `input_tokens`/`output_tokens` from Anthropic's own `usage` field on every
  successful call (`logger.info("anthropic_usage", ...)`) — an exact count,
  not an estimate, and never includes prompt/response content, only counts.

## Endpoints (`modules/aac/router.py`)

| Endpoint | Auth | Rate limit | Purpose |
|---|---|---|---|
| `POST /aac/events` | child-session | — (idempotent batch, same shape as `sessions`) | Implements the ingest contract `AacEventRepository` (Phase 1) already codes against. Was flagged as "not yet implemented" in Phase 1 — this is that follow-up. |
| `POST /aac/compose-sentence` | child-session | 30 req / 60s / IP | Sentence Strip (Level 4) word sequence → one natural sentence. |
| `GET /aac/insights` | parent (ownership-checked via `ParentRepository.get_child`) | 10 req / 60s / IP | Pattern-analysis observations for the parent dashboard (Phase 4 consumes this). |

Rate limits reuse `core/rate_limit.sliding_window_rate_limit` (already used
by the auth endpoints) — 30/60s on compose-sentence because a child
actively building sentences could plausibly tap "speak" many times in a
session; 10/60s on insights because it's parent-triggered and far less
frequent, and is itself cached for a day (see below).

## Sentence composer — AI-upgrade, guaranteed-correct fallback

`AacService.compose_sentence`:

1. Empty word list → the empty-string template, no LLM call.
2. Cache lookup (`aac:compose:{sha256(words|language)}`, 30-day TTL) — the
   same word sequence in the same language always composes to the same
   sentence, so repeats after the first are free and instant.
3. Calls the shared LLM provider with a system prompt constrained to: use
   only the given words' meaning, output only the sentence, keep it under
   15 words, never add facts/names not implied by the input.
4. If the completion is `degraded` (offline, no key, network/parse error)
   or empty, **or** on any exception — falls back to
   `_template_sentence()`: a plain space-joined string of the words, in
   order.

**Why the fallback is a naive join, not a smarter template** (the original
spec's phrasing, "template-based local fallback: 'I want {noun}'", could
read as asking for grammatical templates here): that smarter templating
already exists and is *correct* — it's `AacCardDef.sentenceFor()` from
Phase 1, used by every single-card and two-step (core+fringe) tap
("I want {noun}." / "My {noun} hurts."). The Sentence Strip is a
*different* case: an arbitrary, unstructured sequence of words with no
per-combination template to pick from. Guessing a sentence shape from
words alone gets it wrong easily ("Sad" + "Help" is not "I want sad help").
A naive join is honest about what it is and matches exactly what the
**Flutter client's own offline fallback already does**
(`AacSentenceStripScreen._speak()` before this phase) — so the composed
sentence is predictable and identical whether the naive path fires on the
client (no session at all) or the server (LLM degraded).

## Pattern-analysis insights — deliberately deterministic, not LLM-phrased

This is the one place this phase's implementation diverges from a literal
reading of "PHASE 3 — AI LAYER" — flagging it explicitly rather than
quietly deciding it alone.

`AacService.generate_insights` computes frequency deltas per category
(last 3 days vs. the 11 days before that) entirely with arithmetic — no
LLM call. An insight is only emitted when there's real baseline data and a
real ≥50% rate increase (no invented numbers, same bar as the parent AI
Assistant's `buildInsights()` in Flutter). A small explicit set of
categories/card ids (`feelings`, `needs`, specifically pain/sad/scared/
tired/medicine/help) get `tone: "attention"` and the shared
`MEDICAL_DISCLAIMER`; everything else is `tone: "neutral"`.

I considered adding an LLM "phrasing polish" pass on top (matching
`compose_sentence`'s AI-upgrade/deterministic-fallback pattern) but decided
against it for this specific surface: an insight about a *pain* card
frequency spike is exactly the content CLAUDE.md rule 7 is strictest
about, and a deterministic template is **guaranteed** never to drift into
diagnostic-sounding language, where an LLM rephrasing pass — even with a
careful system prompt — is not guaranteed, and a bug here is higher-stakes
than a slightly-less-natural insight sentence. This is a judgment call, not
a technical limitation — happy to add the polish pass with a strict
post-generation validator (reject anything that adds new claims or removes
the disclaimer) if you'd rather the "AI Layer" framing hold literally here
too.

Results are cached per `(child_id, date)` for 1 day — the closest honest
analogue to "daily" available today (see below).

## No real cron scheduler exists in this codebase — and this doesn't add one

Confirmed by inspection before deciding anything: `workers/daily_rollup.py`
and `workers/weekly_report.py` are **not** actually scheduled anywhere —
`daily_rollup` has no caller at all yet, and `weekly_report` is invoked
on-demand when the AI Assistant's tool-use loop or a report request calls
it, not on a timer. `sessions/router.py` even has a `# STUB #2: Replace
with ARQ` comment already anticipating this gap. Building a AAC-specific
"daily job" that isn't wired to any real scheduler would be exactly the
kind of placeholder CLAUDE.md says not to add. `generate_insights` is
instead invoked **on request** (parent dashboard fetch) with a 1-day cache
— honest about being on-demand-with-caching, not a real cron, consistent
with how `weekly_report` already works. Wiring a real ARQ/ARQ-cron
scheduler is a legitimate, larger follow-up that should cover all three
"STUB" jobs together, not be improvised solely for AAC.

## Privacy — what actually reaches Claude

- **compose_sentence**: the tapped words (e.g. `["water", "cold",
  "please"]`) and the target language code. No child_id, no name, no
  category, no event history.
- **generate_insights**: nothing — this call never reaches the LLM at all
  (see above).

`child_id` appears in the FastAPI request/response schemas and the Redis
cache key, never in an LLM-facing payload.

## Flutter wiring

`AacSentenceComposerService` (`lib/features/aac/data/`) calls
`POST /aac/compose-sentence` with a 3-second client-side timeout —
deliberately shorter than `ApiClient`'s own 10s internal timeout, because
waiting 10 seconds in silence for a "nicer" sentence is worse than
speaking the naive join promptly. The entire body (including the
`SecureTokenStore.getActiveChildId()` lookup, not just the HTTP call) is
wrapped in one try/catch — an earlier version of this file only guarded
the network call, which meant a secure-storage failure would throw
uncaught out of `compose()` and crash the "speak" flow; caught by a test
exercising exactly that path
(`test_falls_back_to_the_naive_word-join_when_child_session_lookup_fails`)
before this reached you.

`AacSentenceStripScreen._speak()` now calls the composer, disables the
speak/clear controls while composing (`_composing` flag) to prevent a
double-tap race, then logs the event and speaks using whatever sentence
came back — AI-composed or naive-joined, the child always hears something.

## Verification

**Backend**: `ruff check` clean, `mypy` clean (strict), `pytest` — 48 tests
across `test_aac.py` (13 new), `test_ai_service.py` (10, moved out of
`test_ai_assistant.py`), `test_ai_assistant.py` (25 remaining) all pass in
isolation and together. The full suite has pre-existing failures in
unrelated files
(`test_admin.py`, `test_teacher.py`, etc.) that reproduce identically
without any of this phase's changes and pass individually — a known
event-loop/fixture-ordering issue in the existing suite, not a regression
introduced here. `alembic` migration `0006_aac_events.py` chained onto the
current head (`0005_child_game_progress` → `f6a7b8c9d0e1`); not yet applied
against a real database (none running in this environment) — schema
reviewed by hand against the `AacEvent` model instead.

**Flutter**: `flutter analyze` clean, `flutter test` — 177/177 pass
(2 new tests for `AacSentenceComposerService`, existing Sentence Strip
screen tests re-verified against the new `_speak()` behavior).

## Open questions for you before Phase 4

1. **Insights: deterministic vs. LLM-polished** (see above) — keep as-is,
   or add a strictly-validated AI polish pass?
2. Phase 4 (Parent Dashboard) is the first real consumer of
   `GET /aac/insights` — no Flutter UI was built for it this phase, only
   the backend endpoint and its data contract.
3. Real ARQ/cron scheduling for `daily_rollup`, `weekly_report`, and AAC
   pattern-analysis is a legitimate shared follow-up, not scoped to this
   phase.
