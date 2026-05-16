#!/usr/bin/env bash
# block-dangerous.sh — PreToolUse hook (Bash). Blocks obviously destructive commands.
#
# Exit code 2 → Claude refuses the call. Anything else → allow.

set -uo pipefail

# Resolve jq portably (see format-on-save.sh for the same logic)
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
    echo "$1"; return
  fi
  cat
}

if [[ -z "$JQ_BIN" ]]; then
  exit 0
fi

INPUT="$(read_stdin_json "${1:-}")"
CMD="$(printf '%s' "$INPUT" | "$JQ_BIN" -r '.tool_input.command // empty' 2>/dev/null)"

[[ -z "$CMD" ]] && exit 0

# Patterns we refuse (case-insensitive). Tune to taste.
DANGEROUS_PATTERNS=(
  'rm[[:space:]]+-rf[[:space:]]+/'
  'rm[[:space:]]+-rf[[:space:]]+\$HOME'
  'rm[[:space:]]+-rf[[:space:]]+~'
  ':(){[[:space:]]*:[[:space:]]*\|[[:space:]]*:&[[:space:]]*}'  # fork bomb
  'mkfs\.'
  'dd[[:space:]]+if='
  'chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/'
  'git[[:space:]]+push[[:space:]]+.*--force.*[[:space:]](main|master)'
  'git[[:space:]]+reset[[:space:]]+--hard.*origin/'
  '--no-verify'
  '--no-gpg-sign'
)

for pat in "${DANGEROUS_PATTERNS[@]}"; do
  if [[ "$CMD" =~ $pat ]]; then
    echo "[block-dangerous] refused: pattern '$pat' matched command:" >&2
    echo "  $CMD" >&2
    echo "Override: explicitly ask the user to run this themselves with '!'." >&2
    exit 2
  fi
done

exit 0
