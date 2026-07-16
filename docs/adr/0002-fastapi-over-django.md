# ADR-0002 — FastAPI over Django (REST Framework)

**Status:** Accepted  
**Date:** 2026-07-10  
**Deciders:** Engineering team

## Context

We need a Python web framework for the FlexiKeys backend. The two realistic contenders are Django + DRF and FastAPI.

## Considered Options

| Criterion | Django + DRF | FastAPI |
|---|---|---|
| Async-native | No (ASGI support is bolted-on) | Yes — built on Starlette/ASGI |
| Typing | Optional | Required; Pydantic v2 models are the schema |
| Auto OpenAPI | Third-party (drf-spectacular) | Built-in, always in sync |
| Performance | Adequate | ~3× higher throughput for I/O-bound workloads |
| Adaptive engine | Awkward with ORM signals | Clean service layer, easy background tasks |
| Ecosystem | Mature, batteries included | Growing fast; SQLAlchemy 2 async covers DB |
| Learning curve | High (ORM, managers, signals, middleware) | Low for typed Python devs |

## Decision

**FastAPI** with async SQLAlchemy 2 + Alembic. Django's ORM and signal system add complexity that actively works against the clean service-layer architecture the adaptive engine requires.

## Consequences

We manage our own: auth (python-jose + passlib), migrations (Alembic), task queue (Arq). All are well-understood, independently testable components. The OpenAPI spec is always authoritative and in sync.