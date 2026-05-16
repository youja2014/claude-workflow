.PHONY: help doctor install lint format typecheck test test-affected build docker-build docker-up docker-down graph clean

help:
	@echo "ts-nx monorepo targets:"
	@echo "  doctor         Verify env (node, yarn, docker)"
	@echo "  install        yarn install + husky"
	@echo "  lint           Run lint on all projects (incl. enforce-module-boundaries)"
	@echo "  format         Prettier write apps/ libs/"
	@echo "  typecheck      tsc --noEmit on all projects"
	@echo "  test           Run all project tests"
	@echo "  test-affected  Run only what changed vs main"
	@echo "  build          Build all apps"
	@echo "  graph          Open dependency graph in browser"
	@echo "  docker-build   Build api and web images"
	@echo "  docker-up      docker compose up -d"
	@echo "  docker-down    docker compose down"
	@echo "  clean          Remove caches"

doctor:
	@node -v && yarn -v && docker --version

install:
	yarn install
	yarn prepare

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
