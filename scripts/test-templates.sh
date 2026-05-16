#!/usr/bin/env bash
# test-templates.sh — Smoke-test each template by scaffolding into a temp dir
# and running its lint/typecheck/test pipeline.
#
# Python templates: uv sync + ruff + pyright + pytest (full).
# TypeScript templates: skip yarn install by default (slow) — use --with-yarn
# to also run yarn install + lint + typecheck.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

WITH_YARN=0
for arg in "$@"; do
  case "$arg" in
    --with-yarn) WITH_YARN=1 ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \?//'; exit 0 ;;
  esac
done

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

PASS=0
FAIL=0
FAILED_STACKS=""

mark_fail() { FAIL=$((FAIL+1)); FAILED_STACKS="$FAILED_STACKS $1"; echo "  FAIL: $1 — $2"; }
mark_pass() { PASS=$((PASS+1)); echo "  PASS: $1"; }

run_python() {
  local stack="$1"
  local dest="$TMP_ROOT/$stack"
  echo
  echo "=== $stack (Python) ==="
  bash "$ROOT_DIR/scripts/scaffold.sh" --stack "$stack" --name "smoke-$stack" --dest "$dest" --desc "smoke test" >/dev/null 2>&1 \
    || { mark_fail "$stack" "scaffold failed"; return; }
  ( cd "$dest" && uv sync --quiet >/dev/null 2>&1 ) \
    || { mark_fail "$stack" "uv sync failed"; return; }
  ( cd "$dest" && uv run --quiet ruff check src tests >/dev/null 2>&1 ) \
    || { mark_fail "$stack" "ruff check failed"; return; }
  ( cd "$dest" && uv run --quiet ruff format --check src tests >/dev/null 2>&1 ) \
    || { mark_fail "$stack" "ruff format check failed"; return; }
  ( cd "$dest" && uv run --quiet pyright >/dev/null 2>&1 ) \
    || { mark_fail "$stack" "pyright failed"; return; }
  # FastAPI defines unit/e2e/integration markers; CLI has none — let pytest pick.
  local pytest_args=("pytest")
  if [[ "$stack" == "fastapi" ]]; then
    pytest_args+=("-m" "unit or e2e")
  fi
  ( cd "$dest" && uv run --quiet "${pytest_args[@]}" >/dev/null 2>&1 ) \
    || { mark_fail "$stack" "pytest failed"; return; }
  mark_pass "$stack"
}

run_typescript() {
  local stack="$1"
  local dest="$TMP_ROOT/$stack"
  echo
  echo "=== $stack (TypeScript) ==="
  bash "$ROOT_DIR/scripts/scaffold.sh" --stack "$stack" --name "smoke-$stack" --dest "$dest" --desc "smoke test" >/dev/null 2>&1 \
    || { mark_fail "$stack" "scaffold failed"; return; }

  if [[ "$WITH_YARN" == "1" ]]; then
    ( cd "$dest" && corepack enable >/dev/null 2>&1 && yarn install --immutable >/dev/null 2>&1 ) \
      || { mark_fail "$stack" "yarn install failed"; return; }
    ( cd "$dest" && yarn typecheck >/dev/null 2>&1 ) \
      || { mark_fail "$stack" "tsc failed"; return; }
    ( cd "$dest" && yarn lint >/dev/null 2>&1 ) \
      || { mark_fail "$stack" "eslint failed"; return; }
    mark_pass "$stack (full)"
  else
    # Required surface files for the TS Nx monorepo template.
    local required=("package.json" "nx.json" "tsconfig.base.json" "eslint.config.mjs" \
                    "apps/api/project.json" "apps/web/project.json" "libs/shared-types/project.json")
    for f in "${required[@]}"; do
      [[ -f "$dest/$f" ]] || { mark_fail "$stack" "missing $f"; return; }
    done
    mark_pass "$stack (scaffold only — pass --with-yarn for full)"
  fi
}

run_python cli
run_python fastapi
run_typescript nx-monorepo

echo
echo "===================="
echo "templates pass=$PASS fail=$FAIL"
[[ -n "$FAILED_STACKS" ]] && echo "failed:$FAILED_STACKS"
[[ "$FAIL" -gt 0 ]] && exit 1 || exit 0
