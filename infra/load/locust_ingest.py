"""
FlexiKeys load test — event ingest endpoint.

Target: POST /api/v1/sessions/{session_id}/events
Goal: 200 concurrent users, p95 < 150 ms

Usage:
  pip install locust
  locust -f infra/load/locust_ingest.py \
         --host http://localhost:8000 \
         --users 200 --spawn-rate 20 \
         --run-time 2m --headless \
         --html infra/load/report.html

The test seeds its own auth tokens on startup; it does not assume
any pre-existing database state. If the DB is empty the setup task
will register + login + create a child + start a session automatically.
"""
from __future__ import annotations

import random
import uuid
from typing import Any

from locust import HttpUser, between, task


class EventIngestUser(HttpUser):
    """Simulates a child device sending keystroke events."""

    wait_time = between(0.5, 2.0)

    _access_token: str = ""
    _child_token: str = ""
    _session_id: str = ""

    def on_start(self) -> None:
        """Register → login → create child → start session."""
        uid = uuid.uuid4().hex[:8]
        email = f"loadtest_{uid}@example.invalid"
        password = "LoadTest!2024"

        # Register
        reg = self.client.post(
            "/api/v1/auth/register",
            json={"email": email, "password": password, "role": "parent"},
            name="[setup] register",
        )
        if reg.status_code not in (200, 201):
            return
        self._access_token = reg.json()["access_token"]
        auth_headers = {"Authorization": f"Bearer {self._access_token}"}

        # Create child
        child_resp = self.client.post(
            "/api/v1/children",
            json={"display_name": f"Kid_{uid}", "learning_language": "en"},
            headers=auth_headers,
            name="[setup] create_child",
        )
        if child_resp.status_code not in (200, 201):
            return
        child_id = child_resp.json()["id"]

        # Get child token
        session_resp = self.client.post(
            f"/api/v1/children/{child_id}/session",
            headers=auth_headers,
            name="[setup] child_session",
        )
        if session_resp.status_code != 200:
            return
        self._child_token = session_resp.json()["child_token"]
        child_headers = {"Authorization": f"Bearer {self._child_token}"}

        # Start learning session
        sess_resp = self.client.post(
            "/api/v1/sessions",
            json={
                "child_id": child_id,
                "language": "en",
                "device_info": {"platform": "android", "version": "loadtest"},
                "client_version": "1.0.0",
            },
            headers=child_headers,
            name="[setup] start_session",
        )
        if sess_resp.status_code in (200, 201):
            self._session_id = sess_resp.json()["id"]

    @task(10)
    def ingest_keystroke_batch(self) -> None:
        """Send a batch of 5–15 keystroke events — the hot path."""
        if not self._session_id or not self._child_token:
            return

        events = [_random_keystroke_event() for _ in range(random.randint(5, 15))]
        self.client.post(
            f"/api/v1/sessions/{self._session_id}/events",
            json={"events": events},
            headers={"Authorization": f"Bearer {self._child_token}"},
            name="POST /sessions/{id}/events",
        )

    @task(2)
    def get_adaptive_profile(self) -> None:
        """Fetch the adaptive profile — called before each level."""
        if not self._child_token:
            return
        self.client.get(
            "/api/v1/adaptive/profile",
            headers={"Authorization": f"Bearer {self._child_token}"},
            name="GET /adaptive/profile",
        )

    @task(1)
    def health_check(self) -> None:
        """Background health-check traffic."""
        self.client.get("/health", name="GET /health")


def _random_keystroke_event() -> dict[str, Any]:
    keys = list("abcdefghijklmnopqrstuvwxyz0123456789")
    target = random.choice(keys)
    actual = target if random.random() > 0.15 else random.choice(keys)
    return {
        "event_id": str(uuid.uuid4()),
        "kind": "keystroke",
        "target_key": target,
        "actual_key": actual,
        "latency_ms": int(random.gauss(600, 300)),
        "time_to_first_touch_ms": int(random.gauss(800, 400)),
        "touch_x": random.uniform(0.1, 0.9),
        "touch_y": random.uniform(0.1, 0.9),
        "key_center_x": 0.5,
        "key_center_y": 0.5,
        "accidental_tap": random.random() < 0.05,
        "retry_count": 0,
        "occurred_at": "2026-01-01T12:00:00Z",
    }