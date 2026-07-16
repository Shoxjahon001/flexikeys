from __future__ import annotations

import json
import pathlib
import uuid
from typing import Any

from fastapi import HTTPException

from flexikeys.modules.ai_assistant.llm_provider import LlmProvider
from flexikeys.modules.ai_assistant.repository import AiAssistantRepository
from flexikeys.modules.ai_assistant.schemas import ChatRequest, ChatResponseOut, MessageOut

# ── Load system prompt at module import time ──────────────────────────────────
_SYSTEM_PROMPT = (
    pathlib.Path(__file__).parent / "system_prompt_v1.md"
).read_text(encoding="utf-8")

# ── Medical disclaimer trigger keywords ──────────────────────────────────────
_MEDICAL_KEYWORDS: frozenset[str] = frozenset(
    [
        "therapy",
        "therapist",
        "diagnosis",
        "diagnose",
        "doctor",
        "medical",
        "treatment",
        "disorder",
        "syndrome",
        "autism",
        "cerebral palsy",
        "disability",
        "ot",
        "occupational therapy",
        "speech therapy",
        "physiotherapy",
    ]
)

_MEDICAL_DISCLAIMER = (
    "> Please note: I'm an educational assistant and not a substitute for "
    "medical or therapeutic advice. For questions about your child's health or "
    "development, please consult a qualified healthcare professional."
)

# Max tool-use rounds to prevent infinite loops
_MAX_TOOL_ROUNDS = 3


def _build_grounded_context(
    *,
    display_name: str,
    email: str,  # accepted but intentionally excluded from output (PII rule)
    birth_year: int | None = None,  # accepted but intentionally excluded from output
    skills: list[Any],
    adaptations: list[Any],
) -> dict[str, Any]:
    """
    Build the structured context dict passed to the LLM.
    PII rule: email, birth_year, and parent_id are NOT included.
    Only display_name (child first name) is allowed.
    """
    # email and birth_year are accepted as parameters to make the call-site
    # explicit, but they must never appear in the returned dict.
    return {
        "child_name": display_name,
        "skills": skills,
        "adaptations": adaptations,
    }


# Skills a child has never attempted aren't "difficult" — they're just not
# started yet, so they're excluded from suggestions (see _build_suggested_activities).
_MAX_SUGGESTED_ACTIVITIES = 3


def _build_suggested_activities(skills: list[Any]) -> list[dict[str, str]]:
    """
    Turn the child's weakest attempted skills into concrete at-home practice
    suggestions, grounded in real mastery data (skill.p_known / skill.label)
    rather than generic filler.
    """
    attempted = [s for s in skills if s.attempts > 0]
    weakest = sorted(attempted, key=lambda s: s.p_known)[:_MAX_SUGGESTED_ACTIVITIES]

    if not weakest:
        return [
            {
                "title": "Start with a short daily session",
                "description": (
                    "There isn't enough practice data yet to target a specific "
                    "skill — a few minutes a day will help the next report "
                    "show what to focus on."
                ),
            }
        ]

    return [
        {
            "title": f"Practice {_title_case_label(s.label)}",
            "description": (
                f"Currently at {round(s.p_known * 100)}% mastery. Spend a few "
                f"minutes together tracing, saying, or typing it slowly — "
                f"short, low-pressure repetition works best."
            ),
        }
        for s in weakest
    ]


def _title_case_label(label: str) -> str:
    """Curriculum labels aren't consistently cased (e.g. "Shape circle" vs
    "Letter E") — normalize for display in generated suggestion text."""
    return " ".join(word.capitalize() for word in label.split())


class AiAssistantService:
    def __init__(
        self,
        session: Any,
        progress_repo: Any,
        parent_repo: Any,
        provider: LlmProvider,
    ) -> None:
        self._session = session
        self._repo = AiAssistantRepository(session)
        self._progress_repo = progress_repo
        self._parent_repo = parent_repo
        self._provider = provider

    async def chat(
        self, request: ChatRequest, parent_id: uuid.UUID
    ) -> ChatResponseOut:
        # 1. Verify parent owns child
        child = await self._parent_repo.get_child(request.child_id, parent_id)
        if child is None:
            raise HTTPException(status_code=404, detail="child_not_found")

        # 2. Load or create conversation
        conv = await self._repo.get_or_create_conversation(
            parent_user_id=parent_id,
            conversation_id=request.conversation_id,
        )

        # 3. Load conversation history
        history = await self._repo.get_messages(conv.id)
        messages: list[dict[str, Any]] = [
            {"role": m.role, "content": m.content} for m in history
        ]

        # 4. Build system prompt, optionally prepend medical disclaimer
        system = _SYSTEM_PROMPT
        if self._contains_medical_keywords(request.message):
            system = _MEDICAL_DISCLAIMER + "\n\n" + system

        # 5. Append the user message
        messages.append({"role": "user", "content": request.message})

        # 6. Tool-use loop (max _MAX_TOOL_ROUNDS rounds)
        tools = self._build_tools()
        assistant_text = ""
        for _round in range(_MAX_TOOL_ROUNDS):
            completion = await self._provider.complete(system, messages, tools)
            assistant_text = completion.text

            if not completion.tool_calls:
                break

            # Execute each tool call and append results. tool_calls is carried
            # alongside the text so a provider can reconstruct its own
            # native tool-use representation on the next round (e.g.
            # Anthropic's tool_use content blocks) — the flat text alone
            # loses that structure.
            messages.append(
                {
                    "role": "assistant",
                    "content": assistant_text,
                    "tool_calls": [
                        {"id": tc.call_id, "name": tc.name, "arguments": tc.arguments}
                        for tc in completion.tool_calls
                    ],
                }
            )
            for tc in completion.tool_calls:
                result = await self._execute_tool(
                    tc.name, tc.arguments, request.child_id, request.ui_language
                )
                messages.append(
                    {
                        "role": "tool",
                        "tool_call_id": tc.call_id,
                        "content": result,
                    }
                )

        # 7. Save messages to DB
        await self._repo.save_message(conv.id, "user", request.message)
        saved_response = await self._repo.save_message(
            conv.id, "assistant", assistant_text
        )
        await self._repo.update_conversation_timestamp(conv.id)
        await self._session.commit()

        return ChatResponseOut(
            conversation_id=conv.id,
            message=MessageOut(
                id=saved_response.id,
                role=saved_response.role,
                content=saved_response.content,
                created_at=saved_response.created_at,
            ),
        )

    async def list_conversations(
        self, parent_id: uuid.UUID
    ) -> list[dict[str, Any]]:
        conversations = await self._repo.list_conversations(parent_id)
        result = []
        for conv in conversations:
            messages = await self._repo.get_messages(conv.id)
            result.append(
                {
                    "id": conv.id,
                    "title": conv.title,
                    "created_at": conv.created_at,
                    "messages": [
                        {
                            "id": m.id,
                            "role": m.role,
                            "content": m.content,
                            "created_at": m.created_at,
                        }
                        for m in messages
                    ],
                }
            )
        return result

    async def get_conversation(
        self, conversation_id: uuid.UUID, parent_id: uuid.UUID
    ) -> dict[str, Any]:
        conv = await self._repo.get_conversation_with_messages(
            conversation_id, parent_id
        )
        if conv is None:
            raise HTTPException(status_code=404, detail="conversation_not_found")
        messages = await self._repo.get_messages(conv.id)
        return {
            "id": conv.id,
            "title": conv.title,
            "created_at": conv.created_at,
            "messages": [
                {
                    "id": m.id,
                    "role": m.role,
                    "content": m.content,
                    "created_at": m.created_at,
                }
                for m in messages
            ],
        }

    async def _execute_tool(
        self,
        tool_name: str,
        args: dict[str, Any],
        child_id: uuid.UUID,
        ui_language: str,
    ) -> str:
        """Dispatch tool calls to service methods; return JSON string."""
        try:
            if tool_name == "get_progress_summary":
                language = args.get("language", "en")
                from flexikeys.modules.progress.repository import ProgressRepository
                from flexikeys.modules.progress.service import ProgressService

                progress_svc = ProgressService(ProgressRepository(self._session))
                skills = await progress_svc.get_skills(child_id, language)
                return json.dumps(
                    [
                        {
                            "skill_key": s.skill_key,
                            "label": s.label,
                            "p_known": s.p_known,
                            "attempts": s.attempts,
                        }
                        for s in skills
                    ]
                )

            elif tool_name == "get_weekly_report":
                from datetime import UTC, datetime, timedelta

                from flexikeys.workers.weekly_report import run_weekly_report

                week_start = datetime.now(UTC).date() - timedelta(days=7)
                payload = await run_weekly_report(self._session, child_id, week_start)
                return json.dumps(payload, default=str)

            elif tool_name == "get_adaptation_history":
                limit = int(args.get("limit", 10))
                from flexikeys.modules.progress.repository import ProgressRepository
                from flexikeys.modules.progress.service import ProgressService

                progress_svc = ProgressService(ProgressRepository(self._session))
                adaptations = await progress_svc.get_adaptations(
                    child_id, ui_language, limit, 0
                )
                return json.dumps(
                    [
                        {
                            "changed_at": a.changed_at.isoformat(),
                            "param": a.param,
                            "sentence": a.sentence,
                        }
                        for a in adaptations
                    ]
                )

            elif tool_name == "get_suggested_activities":
                from flexikeys.modules.progress.repository import ProgressRepository
                from flexikeys.modules.progress.service import ProgressService

                progress_svc = ProgressService(ProgressRepository(self._session))
                skills = await progress_svc.get_skills(child_id, "en")
                return json.dumps(_build_suggested_activities(skills))

            else:
                return json.dumps({"error": f"Unknown tool: {tool_name}"})

        except Exception as exc:
            return json.dumps({"error": str(exc)})

    def _build_tools(self) -> list[dict[str, Any]]:
        return [
            {
                "name": "get_progress_summary",
                "description": (
                    "Return the child's current skill mastery summary, "
                    "including p_known (probability of mastery) per skill."
                ),
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "language": {
                            "type": "string",
                            "description": "Learning language code: 'en', 'uz', or 'ru'.",
                        }
                    },
                    "required": [],
                },
            },
            {
                "name": "get_weekly_report",
                "description": (
                    "Return the child's activity summary for the past 7 days, "
                    "including time spent, items completed, streak, and accuracy trend."
                ),
                "input_schema": {
                    "type": "object",
                    "properties": {},
                    "required": [],
                },
            },
            {
                "name": "get_adaptation_history",
                "description": (
                    "Return recent keyboard/interface adaptations with human-readable "
                    "explanations of why each change was made."
                ),
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "limit": {
                            "type": "integer",
                            "description": (
                                "Maximum number of adaptations to return (default 10)."
                            ),
                        }
                    },
                    "required": [],
                },
            },
            {
                "name": "get_suggested_activities",
                "description": (
                    "Return a list of suggested at-home practice activities "
                    "based on the child's current weak skills."
                ),
                "input_schema": {
                    "type": "object",
                    "properties": {},
                    "required": [],
                },
            },
        ]

    @staticmethod
    def _contains_medical_keywords(text: str) -> bool:
        low = text.lower()
        return any(kw in low for kw in _MEDICAL_KEYWORDS)
