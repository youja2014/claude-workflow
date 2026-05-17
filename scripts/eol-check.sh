#!/usr/bin/env bash
# eol-check.sh — Poll endoflife.date for runtime versions tracked by this project.
#
# Usage:
#   bash scripts/eol-check.sh                # default: warn if <180 days to EOL
#   WARN_DAYS=90 bash scripts/eol-check.sh   # override warning threshold
#
# Exit code:
#   0 — all tracked assets within safe window
#   1 — at least one asset past EOL or within WARN_DAYS
#   2 — internal error (network, jq missing, etc.)
#
# Why this exists:
#   Phase 4 of 2026-05-17 self-adoption (docs/plans/exec-plans/...).
#   Addresses gap #1 (Drift): runtime EOL was discovered only when the user
#   pointed it out (Node 20 EOL on 2026-04-30). This script makes drift
#   detection mechanical.

set -uo pipefail

WARN_DAYS="${WARN_DAYS:-180}"

# Resolve jq portably (same pattern as hooks/format-on-save.sh).
JQ_BIN="${CLAUDE_JQ:-}"
if [[ -z "$JQ_BIN" || ! -x "$JQ_BIN" ]]; then
  CANDIDATE="${HOME:-$USERPROFILE}/.claude/hooks/jq.exe"
  if [[ -x "$CANDIDATE" ]]; then
    JQ_BIN="$CANDIDATE"
  else
    JQ_BIN="$(command -v jq || true)"
  fi
fi

if [[ -z "$JQ_BIN" ]]; then
  echo "ERROR: jq not found. Install jq or set CLAUDE_JQ env var." >&2
  exit 2
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl not found." >&2
  exit 2
fi

# Tracked assets: pipe-separated tuple (display-name | endoflife.date-id | current major version).
# Keep this list in sync with:
#   - rules/python/docker.md, rules/typescript/docker.md
#   - templates/*/Dockerfile
#   - ~/.claude/CLAUDE.md "Developer Profile"
ASSETS=(
  "node|nodejs|22"
  "python|python|3.12"
)

today_epoch="$(date +%s)"
has_warning=0

printf '%-10s %-10s %-12s %-12s %s\n' "System" "Current" "EOL" "Days Left" "Status"
printf '%-10s %-10s %-12s %-12s %s\n' "------" "-------" "---" "---------" "------"

for entry in "${ASSETS[@]}"; do
  IFS='|' read -r name eolid current <<<"$entry"
  url="https://endoflife.date/api/${eolid}/${current}.json"

  resp="$(curl -fsSL --max-time 10 "$url" 2>/dev/null)"
  if [[ -z "$resp" ]]; then
    printf '%-10s %-10s %-12s %-12s %s\n' "$name" "$current" "?" "?" "FETCH_FAILED"
    has_warning=1
    continue
  fi

  eol="$(printf '%s' "$resp" | "$JQ_BIN" -r '.eol // empty')"

  # Some cycles use boolean `false` to mean "no scheduled EOL".
  if [[ -z "$eol" || "$eol" == "false" || "$eol" == "null" ]]; then
    printf '%-10s %-10s %-12s %-12s %s\n' "$name" "$current" "(no eol)" "—" "PERPETUAL"
    continue
  fi

  eol_epoch="$(date -d "$eol" +%s 2>/dev/null)"
  if [[ -z "$eol_epoch" ]]; then
    printf '%-10s %-10s %-12s %-12s %s\n' "$name" "$current" "$eol" "?" "DATE_PARSE_FAIL"
    has_warning=1
    continue
  fi

  days_left=$(( (eol_epoch - today_epoch) / 86400 ))

  if (( days_left < 0 )); then
    status="EOL_PASSED"
    has_warning=1
  elif (( days_left < WARN_DAYS )); then
    status="EXPIRING_SOON"
    has_warning=1
  else
    status="OK"
  fi

  printf '%-10s %-10s %-12s %-12s %s\n' "$name" "$current" "$eol" "$days_left" "$status"
done

echo
if (( has_warning )); then
  echo "⚠ One or more assets past EOL or expiring within ${WARN_DAYS} days."
  echo "  Update rules/python/docker.md, rules/typescript/docker.md, templates/*/Dockerfile."
  exit 1
else
  echo "✓ All tracked assets within safe window (>${WARN_DAYS} days to EOL)."
  exit 0
fi
