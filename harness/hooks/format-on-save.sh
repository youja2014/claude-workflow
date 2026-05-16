#!/usr/bin/env bash
# format-on-save.sh — PostToolUse hook (Write|Edit). Auto-formats by extension.
#
# Called by Claude Code with the edited file path injected via stdin (JSON).
# We extract tool_input.file_path and dispatch to the appropriate formatter.
#
# Failure is non-fatal: we do not block the edit — just log to stderr.

set -uo pipefail

# Resolve jq portably:
#   1. $CLAUDE_JQ env var (user override)
#   2. ~/.claude/hooks/jq.exe (Windows convention)
#   3. PATH
JQ_BIN="${CLAUDE_JQ:-}"
if [[ -z "$JQ_BIN" || ! -x "$JQ_BIN" ]]; then
  CANDIDATE="${HOME:-$USERPROFILE}/.claude/hooks/jq.exe"
  if [[ -x "$CANDIDATE" ]]; then
    JQ_BIN="$CANDIDATE"
  else
    JQ_BIN="$(command -v jq || true)"
  fi
fi

read_stdin_json() {
  if [[ -n "${1:-}" ]]; then
    echo "$1"
    return
  fi
  cat
}

if [[ -z "$JQ_BIN" ]]; then
  echo "[format-on-save] jq not found — skipping" >&2
  exit 0
fi

INPUT="$(read_stdin_json "${1:-}")"
FILE_PATH="$(printf '%s' "$INPUT" | "$JQ_BIN" -r '.tool_input.file_path // empty' 2>/dev/null)"

[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

# Normalize Windows backslashes
FILE_PATH="$(printf '%s' "$FILE_PATH" | tr '\\' '/')"

ext="${FILE_PATH##*.}"
case "$ext" in
  py)
    if command -v uv >/dev/null 2>&1; then
      uv run --quiet ruff format "$FILE_PATH" 2>/dev/null \
        || uvx --quiet ruff format "$FILE_PATH" 2>/dev/null \
        || true
      uv run --quiet ruff check --fix "$FILE_PATH" 2>/dev/null \
        || uvx --quiet ruff check --fix "$FILE_PATH" 2>/dev/null \
        || true
    fi
    ;;
  ts|tsx|js|jsx|json|md|yml|yaml|css|html)
    proj_dir="$(dirname "$FILE_PATH")"
    while [[ "$proj_dir" != "/" && "$proj_dir" != "." && ! -f "$proj_dir/package.json" ]]; do
      proj_dir="$(dirname "$proj_dir")"
    done
    if [[ -f "$proj_dir/package.json" ]]; then
      ( cd "$proj_dir" && yarn --silent prettier --write "$FILE_PATH" 2>/dev/null ) || true
    fi
    ;;
esac

exit 0
