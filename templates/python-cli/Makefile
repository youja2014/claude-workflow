.PHONY: help install doctor lint format typecheck test test-cov run docker-build docker-up docker-down clean

help:
	@echo "Targets:"
	@echo "  install       uv sync + pre-commit install"
	@echo "  doctor        verify tooling"
	@echo "  lint          ruff check"
	@echo "  format        ruff format"
	@echo "  typecheck     pyright"
	@echo "  test          pytest"
	@echo "  test-cov      pytest with coverage"
	@echo "  run           run CLI (pass ARGS=...)"
	@echo "  docker-build  build docker image"
	@echo "  docker-up     docker compose up"
	@echo "  docker-down   docker compose down"

install:
	uv sync
	uv run pre-commit install
	uv run pre-commit install --hook-type commit-msg

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
