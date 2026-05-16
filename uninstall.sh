#!/usr/bin/env bash
# uninstall.sh — Remove files installed by claude-workflow
#
# Removes only files recorded in ~/.claude/.claude-workflow.lock.
# Does NOT touch *.local.md, settings.local.json, or files marked "user-modified".
#
# Flags:
#   --yes        Skip confirmation
#   --dry-run    Print planned removals

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${CLAUDE_HOME:-$HOME/.claude}"
LOCK_FILE="$TARGET_DIR/.claude-workflow.lock"

DRY_RUN=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    *) echo "Unknown flag: $arg" >&2; exit 2 ;;
  esac
done

if [[ ! -f "$LOCK_FILE" ]]; then
  echo "[uninstall] No lock file at $LOCK_FILE — nothing to remove."
  exit 0
fi

if [[ "$ASSUME_YES" != "1" ]]; then
  echo "This will remove files listed in $LOCK_FILE."
  read -r -p "Continue? [y/N] " ans
  [[ "$ans" =~ ^[yY]$ ]] || { echo "aborted"; exit 1; }
fi

removed=0
preserved=0

while IFS= read -r line; do
  [[ "$line" =~ ^# ]] && continue
  [[ -z "$line" ]] && continue

  # Skip lines marked as user-modified
  if [[ "$line" == *"user-modified"* ]]; then
    rel="$(echo "$line" | awk '{print $2}')"
    echo "[uninstall] preserve (user-modified): $rel"
    preserved=$((preserved+1))
    continue
  fi

  rel="$(echo "$line" | awk '{print $2}')"
  [[ -z "$rel" ]] && continue
  target="$TARGET_DIR/$rel"

  if [[ -f "$target" ]]; then
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "[dry] rm $target"
    else
      rm -f "$target"
    fi
    removed=$((removed+1))
  fi
done < "$LOCK_FILE"

if [[ "$DRY_RUN" != "1" ]]; then
  rm -f "$LOCK_FILE"
fi

# Clean up empty directories under the managed subtrees
for sub in rules skills commands hooks agents; do
  d="$TARGET_DIR/$sub"
  [[ -d "$d" ]] && find "$d" -type d -empty -delete 2>/dev/null || true
done

echo "[uninstall] removed: $removed, preserved: $preserved"
echo "[uninstall] note: settings.json merged entries are NOT auto-reverted — edit manually if needed"
