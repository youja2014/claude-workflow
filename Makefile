.PHONY: help doctor install install-dry install-yes uninstall sync verify install-git-hooks test test-install test-templates test-templates-full clean

help:
	@echo "claude-workflow management targets:"
	@echo "  doctor                Verify environment (uv, yarn, docker, git, python, node)"
	@echo "  install               Install harness/ to ~/.claude/ (interactive conflict resolution)"
	@echo "  install-dry           Show what install would do, without writing"
	@echo "  install-yes           Install non-interactively (overwrite all conflicts)"
	@echo "  install-git-hooks     Install repo pre-push hook that runs 'make verify'"
	@echo "  uninstall             Remove files installed by this project (preserves .local)"
	@echo "  sync                  Re-deploy harness/ (alias for install-yes)"
	@echo "  verify                Vendor-neutral check: equivalent to 'make test'."
	@echo "                        Use in pre-push hook or any CI runner."
	@echo "  test                  Run all self-tests (install + templates)"
	@echo "  test-install          Verify install/uninstall cycle in isolated HOME"
	@echo "  test-templates        Scaffold + lint/typecheck/test each Python template"
	@echo "  test-templates-full   Same as test-templates plus yarn install for TS templates"
	@echo "  clean                 Remove generated caches"

doctor:
	bash scripts/doctor.sh

install:
	bash install.sh

install-dry:
	bash install.sh --dry-run

install-yes:
	bash install.sh --yes

uninstall:
	bash uninstall.sh

sync: install-yes

verify: test

install-git-hooks:
	bash scripts/install-git-hooks.sh

test: test-install test-templates

test-install:
	bash scripts/test-install.sh

test-templates:
	bash scripts/test-templates.sh

test-templates-full:
	bash scripts/test-templates.sh --with-yarn

clean:
	rm -rf .ruff_cache .pytest_cache .mypy_cache node_modules
