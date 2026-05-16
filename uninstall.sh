#!/usr/bin/env bash
# uninstall.sh — Safely remove files installed by claude-workflow.
#
# Removes only files recorded in ~/.claude/.claude-workflow.lock whose current
# sha256 still matches the recorded checksum. Modified files are renamed to
# "<path>.local.bak" (never deleted), and the change is reported.
#
# Default is DRY-RUN. Use --commit to actually mutate the filesystem.
#
# Never touches *.local.md, settings.local.json, or entries marked
# "user-modified" in the lock.
#
# Flags:
#   --commit     Perform the deletions/backups. Without this, prints plan only.
#   --yes        Skip the confirmation prompt (still needs --commit to write).
#   --dry-run    Backwards-compat alias for "no --commit" (default behavior).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${CLAUDE_HOME:-$HOME/.claude}"
LOCK_FILE="$TARGET_DIR/.claude-workflow.lock"

COMMIT=0
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --commit) COMMIT=1 ;;
    --dry-run) COMMIT=0 ;;
    --yes|-y) ASSUME_YES=1 ;;
    -h|--help) awk 'NR>1 && /^#/{sub(/^# ?/,""); print; next} NR>1{exit}' "$0"; exit 0 ;;
    *) echo "Unknown flag: $arg" >&2; exit 2 ;;
  esac
done

mode_label() {
  if [[ "$COMMIT" == "1" ]]; then echo "COMMIT"; else echo "DRY-RUN"; fi
}

if [[ ! -f "$LOCK_FILE" ]]; then
  echo "[uninstall] No lock file at $LOCK_FILE — nothing to do."
  exit 0
fi

# Refuse to proceed if lock format is corrupt (no parseable lines)
if ! grep -qE '^[a-f0-9]+[[:space:]]+\S' "$LOCK_FILE"; then
  echo "[uninstall] ERROR: lock file has no parseable entries: $LOCK_FILE" >&2
  echo "[uninstall] Refusing to act. Inspect the file or reinstall to regenerate." >&2
  exit 1
fi

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo ""
  fi
}

echo "[uninstall] mode: $(mode_label)"
echo "[uninstall] lock: $LOCK_FILE"
echo "[uninstall] target: $TARGET_DIR"
echo

if [[ "$COMMIT" == "1" && "$ASSUME_YES" != "1" ]]; then
  read -r -p "About to MUTATE $TARGET_DIR. Continue? [y/N] " ans
  [[ "$ans" =~ ^[yY]$ ]] || { echo "aborted"; exit 1; }
fi

removed=0
preserved_user_mod=0
backed_up_modified=0
missing=0

while IFS= read -r line; do
  [[ "$line" =~ ^# ]] && continue
  [[ -z "$line" ]] && continue

  # Skip entries flagged user-modified at install time
  if [[ "$line" == *"user-modified"* ]]; then
    rel="$(echo "$line" | awk '{print $2}')"
    echo "  preserve (lock flag): $rel"
    preserved_user_mod=$((preserved_user_mod+1))
    continue
  fi

  recorded_hash="$(echo "$line" | awk '{print $1}')"
  rel="$(echo "$line" | awk '{print $2}')"
  [[ -z "$rel" ]] && continue
  target="$TARGET_DIR/$rel"

  if [[ ! -f "$target" ]]; then
    echo "  missing            : $rel"
    missing=$((missing+1))
    continue
  fi

  current_hash="$(sha256_of "$target")"
  if [[ -z "$current_hash" || -z "$recorded_hash" ]]; then
    echo "  no-checksum        : $rel (skipping for safety)"
    preserved_user_mod=$((preserved_user_mod+1))
    continue
  fi

  if [[ "$current_hash" != "$recorded_hash" ]]; then
    # File modified since install — back up, don't delete
    backup="$target.local.bak"
    echo "  MODIFIED -> backup : $rel  ->  $rel.local.bak"
    if [[ "$COMMIT" == "1" ]]; then
      mv "$target" "$backup"
    fi
    backed_up_modified=$((backed_up_modified+1))
    continue
  fi

  echo "  remove             : $rel"
  if [[ "$COMMIT" == "1" ]]; then
    rm -f "$target"
  fi
  removed=$((removed+1))
done < "$LOCK_FILE"

if [[ "$COMMIT" == "1" ]]; then
  # Move lock aside (not delete) so the previous state is recoverable
  mv "$LOCK_FILE" "$LOCK_FILE.removed-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

  # Clean up empty directories under the managed subtrees
  for sub in rules skills commands hooks agents; do
    d="$TARGET_DIR/$sub"
    [[ -d "$d" ]] && find "$d" -type d -empty -delete 2>/dev/null || true
  done
fi

echo
echo "[uninstall] summary ($(mode_label)):"
echo "  removed (clean)        : $removed"
echo "  backed up (modified)   : $backed_up_modified"
echo "  preserved (lock flag)  : $preserved_user_mod"
echo "  missing                : $missing"

if [[ "$COMMIT" != "1" ]]; then
  echo
  echo "[uninstall] DRY-RUN — no files were touched."
  echo "[uninstall] Re-run with --commit to apply."
fi
echo "[uninstall] note: settings.json merged entries are NOT auto-reverted — edit manually if needed"
