#!/usr/bin/env bash
# block-dangerous.sh — PreToolUse hook (Bash). Blocks obviously destructive commands.
#
# Two-tier check:
#   1) UNCONDITIONAL patterns — destructive shapes that have no safe use.
#   2) Token-aware git context — block --no-verify / --no-gpg-sign / force-push
#      only when they appear as actual git arguments (not in comments, prose,
#      or commit messages on their own line).
#
# Exit code 2 -> Claude refuses the call. Anything else -> allow.

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

# Unconditional patterns: matched against the trimmed sub-command.
UNCONDITIONAL_PATTERNS=(
  '^rm[[:space:]]+-rf[[:space:]]+/([[:space:]]|$)'
  '^rm[[:space:]]+-rf[[:space:]]+\$HOME'
  '^rm[[:space:]]+-rf[[:space:]]+~'
  ':\(\)\{[[:space:]]*:[[:space:]]*\|[[:space:]]*:&[[:space:]]*\};:'
  '^mkfs\.'
  '^dd[[:space:]]+.*if='
  '^chmod[[:space:]]+-R[[:space:]]+777[[:space:]]+/'
)

deny() {
  echo "[block-dangerous] refused: $1" >&2
  echo "  command: $CMD" >&2
  echo "Override: ask the user to run this themselves with '!'." >&2
  exit 2
}

check_subcmd() {
  local sub="$1"
  # Trim leading whitespace
  sub="${sub#"${sub%%[![:space:]]*}"}"
  # Skip empty or comment-only fragments
  case "$sub" in
    ''|\#*) return 0 ;;
  esac

  # Tier 1: unconditional destructive shapes
  local pat
  for pat in "${UNCONDITIONAL_PATTERNS[@]}"; do
    if [[ "$sub" =~ $pat ]]; then
      deny "destructive pattern '$pat'"
    fi
  done

  # Tier 2: git-context flags. Tokenize on whitespace.
  # shellcheck disable=SC2206
  local tokens=( $sub )
  local first="${tokens[0]:-}"
  [[ "$first" != "git" ]] && return 0

  local subcmd="${tokens[1]:-}"
  # Collect remaining args as space-delimited string for word matching.
  local args=" ${tokens[*]:2} "

  case "$subcmd" in
    commit|push|merge|rebase|am|cherry-pick|revert)
      if [[ "$args" == *" --no-verify "* ]]; then
        deny "git $subcmd with --no-verify (bypasses pre-commit hooks)"
      fi
      if [[ "$args" == *" --no-gpg-sign "* ]]; then
        deny "git $subcmd with --no-gpg-sign (bypasses commit signing)"
      fi
      ;;
  esac

  if [[ "$subcmd" == "push" ]]; then
    if [[ "$args" == *" --force "* || "$args" == *" -f "* || "$args" == *" --force-with-lease "* ]]; then
      if [[ "$args" == *" main "* || "$args" == *" master "* || "$args" == *":main "* || "$args" == *":master "* ]]; then
        deny "force-push to main/master"
      fi
    fi
  fi

  if [[ "$subcmd" == "reset" ]]; then
    if [[ "$args" == *" --hard "* && "$args" == *" origin/"* ]]; then
      deny "git reset --hard to remote ref (loses local commits)"
    fi
  fi

  return 0
}

# Split CMD on shell separators that begin a new command:
#   ; && || |
# Quote handling is intentionally simple — a --no-verify token inside a single
# quoted commit message will still trigger a deny. That false-positive is
# considered acceptable; for nuance, use bashlex (see block-dangerous notes).
IFS_SAVE="$IFS"
# Replace separators with newlines, then iterate.
SANITIZED="$(printf '%s' "$CMD" | sed -E 's/(\&\&|\|\|)/\n/g; s/[;|]/\n/g')"
while IFS= read -r line; do
  check_subcmd "$line"
done <<< "$SANITIZED"
IFS="$IFS_SAVE"

exit 0
