.PHONY: help doctor install install-git-hooks lint format typecheck test test-affected verify build docker-build docker-up docker-down graph clean

help:
	@echo "ts-nx monorepo targets:"
	@echo "  doctor             Verify env (node, yarn, docker)"
	@echo "  install            yarn install + install local git hooks"
	@echo "  install-git-hooks  point core.hooksPath to .githooks/"
	@echo "  lint               Run lint on all projects (incl. enforce-module-boundaries)"
	@echo "  format             Prettier write apps/ libs/"
	@echo "  typecheck          tsc --noEmit on all projects"
	@echo "  test               Run all project tests"
	@echo "  test-affected      Run only what changed vs main"
	@echo "  verify             lint + typecheck + test (used by pre-push)"
	@echo "  build              Build all apps"
	@echo "  graph              Open dependency graph in browser"
	@echo "  docker-build       Build api and web images"
	@echo "  docker-up          docker compose up -d"
	@echo "  docker-down        docker compose down"
	@echo "  clean              Remove caches"

doctor:
	@node -v && yarn -v && docker --version

install:
	yarn install
	bash scripts/install-git-hooks.sh

install-git-hooks:
	bash scripts/install-git-hooks.sh

verify: lint typecheck test

lint:
	yarn lint

format:
	yarn format

typecheck:
	yarn typecheck

test:
	yarn test

test-affected:
	yarn nx affected --target=test

build:
	yarn build

graph:
	yarn graph

docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

clean:
	rm -rf node_modules dist coverage .nx/cache .nx/workspace-data
