# aac

Backend for the "My Voice" AAC (Augmentative and Alternative Communication)
module — Phase 3 "AI Layer" of the client-side AAC work in `app/lib/features/aac/`.

- `POST /aac/events` — child-session auth. Idempotent batch ingest of
  offline-logged card taps (contract defined client-side in
  `AacEventRepository`, Phase 1; this router implements it for real).
- `POST /aac/compose-sentence` — child-session auth, rate-limited. Composes
  one natural sentence from a Sentence Strip word sequence via Claude, with
  a naive word-join fallback when the AI call degrades (offline/no key/error).
- `GET /aac/insights` — parent auth (ownership-checked via `ParentRepository`),
  rate-limited. Deterministic (not LLM-generated — see
  `docs/aac_phase3_ai_layer.md` for why) frequency-spike observations per
  category, cached for 1 day per child.

Uses `services.ai_service` (shared with `ai_assistant`) for the LLM call —
not a separate provider implementation.
