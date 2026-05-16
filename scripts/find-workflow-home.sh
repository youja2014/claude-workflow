#!/usr/bin/env bash
# find-workflow-home.sh — Locate the claude-workflow source directory.
#
# Resolution order:
#   1. $CLAUDE_WORKFLOW_HOME (explicit override)
#   2. Directory containing this script's parent (works when invoked from a clone)
#   3. ~/.claude/.claude-workflow.lock '# source_dir=...' record (set by install.sh)
#
# Prints the resolved absolute path on stdout. Exits 1 with a diagnostic on stderr
# if no candidate is valid.
#
# Usage:
#   home="$(bash scripts/find-workflow-home.sh)" || exit 1
#   bash "$home/scripts/scaffold.sh" ...

set -uo pipefail

resolve() {
  # 1. env var
  if [[ -n "${CLAUDE_WORKFLOW_HOME:-}" && -d "$CLAUDE_WORKFLOW_HOME/harness" ]]; then
    echo "$CLAUDE_WORKFLOW_HOME"
    return 0
  fi

  # 2. self-relative (this script lives in <root>/scripts/)
  local self_root
  self_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd)" || self_root=""
  if [[ -n "$self_root" && -d "$self_root/harness" ]]; then
    echo "$self_root"
    return 0
  fi

  # 3. lock file recorded by install.sh
  local lock="${CLAUDE_HOME:-$HOME/.claude}/.claude-workflow.lock"
  if [[ -f "$lock" ]]; then
    local from_lock
    # grep failure must not abort under set -e; tolerate missing line
    from_lock="$(grep '^# source_dir=' "$lock" 2>/dev/null | head -n1 | cut -d= -f2- || true)"
    if [[ -n "$from_lock" && -d "$from_lock/harness" ]]; then
      echo "$from_lock"
      return 0
    fi
  fi

  return 1
}

if home="$(resolve)"; then
  echo "$home"
  exit 0
else
  echo "ERROR: claude-workflow source not found." >&2
  echo "Set CLAUDE_WORKFLOW_HOME or run from inside a clone." >&2
  echo "Tried:" >&2
  echo "  1. \$CLAUDE_WORKFLOW_HOME = ${CLAUDE_WORKFLOW_HOME:-<unset>}" >&2
  echo "  2. self-relative parent" >&2
  echo "  3. ${CLAUDE_HOME:-$HOME/.claude}/.claude-workflow.lock (# source_dir=...)" >&2
  exit 1
fi
