# ── Build stage ──────────────────────────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build

RUN pip install --no-cache-dir pip==24.3.1 setuptools wheel

COPY pyproject.toml .
COPY src/ src/

RUN pip install --no-cache-dir --target /deps ".[dev]" && \
    pip install --no-cache-dir --target /deps .

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM python:3.12-slim AS runtime

# Non-root user
RUN groupadd --gid 1001 app && \
    useradd --uid 1001 --gid app --shell /bin/bash --create-home app

WORKDIR /app

COPY --from=builder /deps /usr/local/lib/python3.12/site-packages/
COPY --from=builder /build/src /app/src
COPY alembic.ini .
COPY alembic ./alembic
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENV PYTHONPATH=/app/src \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER app

EXPOSE 8000

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["python", "-m", "uvicorn", "flexikeys.main:app", "--host", "0.0.0.0", "--port", "8000"]