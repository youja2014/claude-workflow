.PHONY: help install install-git-hooks doctor lint format typecheck test test-unit test-integration test-e2e verify run migrate-rev migrate-up docker-build docker-up docker-down clean

help:
	@echo "Targets:"
	@echo "  install            uv sync + install local git hooks"
	@echo "  install-git-hooks  point core.hooksPath to .githooks/"
	@echo "  doctor             verify tooling"
	@echo "  lint               ruff check"
	@echo "  format             ruff format + check --fix"
	@echo "  typecheck          pyright"
	@echo "  test               all tests"
	@echo "  test-unit          unit only"
	@echo "  test-integration   integration only (needs docker)"
	@echo "  test-e2e           e2e only"
	@echo "  verify             lint + typecheck + (unit + e2e tests; used by pre-push)"
	@echo "  run                run dev server"
	@echo "  migrate-rev        alembic revision --autogenerate -m MSG"
	@echo "  migrate-up         alembic upgrade head"
	@echo "  docker-build       build docker image"
	@echo "  docker-up          docker compose up -d"
	@echo "  docker-down        docker compose down"

install:
	uv sync
	bash scripts/install-git-hooks.sh

install-git-hooks:
	bash scripts/install-git-hooks.sh

verify: lint typecheck
	uv run pytest -m "unit or e2e"

doctor:
	@command -v uv >/dev/null || (echo "uv missing" && exit 1)
	@command -v docker >/dev/null || (echo "docker missing" && exit 1)
	@uv run python -c "import sys; assert sys.version_info >= (3, 12)"
	@echo "OK"

lint:
	uv run ruff check src tests

format:
	uv run ruff format src tests
	uv run ruff check --fix src tests

typecheck:
	uv run pyright

test:
	uv run pytest

test-unit:
	uv run pytest -m unit

test-integration:
	uv run pytest -m integration

test-e2e:
	uv run pytest -m e2e

run:
	uv run uvicorn __package__.main:app --reload --host 0.0.0.0 --port 8000

migrate-rev:
	@test -n "$(MSG)" || (echo "Usage: make migrate-rev MSG='description'" && exit 1)
	uv run alembic revision --autogenerate -m "$(MSG)"

migrate-up:
	uv run alembic upgrade head

docker-build:
	docker build -t __project_kebab__:latest .

docker-up:
	docker compose up -d

docker-down:
	docker compose down

clean:
	rm -rf .venv .pytest_cache .ruff_cache .pyright dist build *.egg-info htmlcov .coverage
