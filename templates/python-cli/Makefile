.PHONY: help install install-git-hooks doctor lint format typecheck test test-cov verify run docker-build docker-up docker-down clean

help:
	@echo "Targets:"
	@echo "  install            uv sync + install local git hooks"
	@echo "  install-git-hooks  point core.hooksPath to .githooks/"
	@echo "  doctor             verify tooling"
	@echo "  lint               ruff check"
	@echo "  format             ruff format"
	@echo "  typecheck          pyright"
	@echo "  test               pytest"
	@echo "  test-cov           pytest with coverage"
	@echo "  verify             lint + typecheck + test (used by pre-push)"
	@echo "  run                run CLI (pass ARGS=...)"
	@echo "  docker-build       build docker image"
	@echo "  docker-up          docker compose up"
	@echo "  docker-down        docker compose down"

install:
	uv sync
	bash scripts/install-git-hooks.sh

install-git-hooks:
	bash scripts/install-git-hooks.sh

verify: lint typecheck test

doctor:
	@command -v uv >/dev/null || (echo "uv not installed" && exit 1)
	@command -v docker >/dev/null || (echo "docker not installed" && exit 1)
	@uv run python -c "import sys; assert sys.version_info >= (3, 12), 'need python 3.12+'"
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

test-cov:
	uv run pytest --cov=src --cov-report=term-missing --cov-report=html

run:
	uv run __project_kebab__ $(ARGS)

docker-build:
	docker build -t __project_kebab__:latest .

docker-up:
	docker compose up -d

docker-down:
	docker compose down

clean:
	rm -rf .venv .pytest_cache .ruff_cache .pyright dist build *.egg-info htmlcov .coverage
