FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
WORKDIR /app

# ---- builder ----
FROM base AS builder
COPY pyproject.toml uv.lock* ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev || uv sync --no-dev
COPY src ./src
COPY migrations ./migrations
COPY alembic.ini ./

# ---- runtime ----
FROM base AS runtime
RUN useradd --create-home --shell /bin/bash app
WORKDIR /app
COPY --from=builder /app /app
ENV PATH="/app/.venv/bin:$PATH"
USER app
EXPOSE 8000
CMD ["uvicorn", "__package__.main:app", "--host", "0.0.0.0", "--port", "8000"]
