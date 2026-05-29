#!/usr/bin/env bash
# install.sh — Deploy harness/global/ contents to ~/.claude/
#   (harness/project/ is NOT deployed globally — it is per-project assets
#    consumed by scripts/scaffold.sh during project scaffolding/adoption.)
#
# Behavior:
#   - Copies (not symlinks) for Windows compatibility
#   - Tracks original checksums in ~/.claude/.claude-workflow.lock
#   - NEVER touches *.local.md or settings.local.json
#   - Merges settings.json via scripts/settings-merge.py (no duplicate hooks)
#   - Interactive conflict resolution (k/o/d/b) by default
#
# Flags:
#   --yes        Non-interactive — overwrite all conflicts
#   --dry-run    Print planned actions without writing
#   --no-merge   Skip settings.json merge

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$SCRIPT_DIR/harness/global"
TARGET_DIR="${CLAUDE_HOME:-$HOME/.claude}"
LOCK_FILE="$TARGET_DIR/.claude-workflow.lock"
BACKUP_DIR="$TARGET_DIR/backups/claude-workflow-$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
ASSUME_YES=0
SKIP_MERGE=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --no-merge) SKIP_MERGE=1 ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) echo "Unknown flag: $arg" >&2; exit 2 ;;
  esac
done

if [[ ! -d "$HARNESS_DIR" ]]; then
  echo "ERROR: harness/global/ directory not found at $HARNESS_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"

log()  { printf '%s\n' "$*"; }
info() { printf '[install] %s\n' "$*"; }
warn() { printf '[install] WARN: %s\n' "$*" >&2; }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    warn "No sha256 tool found; checksums will be empty"
    echo ""
  fi
}

# Files we manage. Special-case settings.json (merged) and *.local* (never touched).
is_local_file() {
  case "$1" in
    *.local.md|*.local.json|CLAUDE.local.md|settings.local.json) return 0 ;;
    *) return 1 ;;
  esac
}

# Returns 0 if path requires special merge handling.
is_merge_target() {
  case "$1" in
    settings.json) return 0 ;;
    *) return 1 ;;
  esac
}

prompt_conflict() {
  local src="$1" dst="$2"
  if [[ "$ASSUME_YES" == "1" ]]; then echo "o"; return; fi
  echo "" >&2
  echo "  Conflict: $dst" >&2
  echo "    Source : $src" >&2
  echo "  [k]eep current  [o]verwrite  [d]iff  [b]ackup&replace  [s]kip remaining" >&2
  read -r -p "  Choice [k]: " choice
  echo "${choice:-k}"
}

ensure_dir() {
  local dir="$1"
  if [[ "$DRY_RUN" == "1" ]]; then
    [[ -d "$dir" ]] || info "[dry] mkdir -p $dir"
  else
    mkdir -p "$dir"
  fi
}

backup_file() {
  local src="$1"
  local rel="${src#$TARGET_DIR/}"
  local dest="$BACKUP_DIR/$rel"
  ensure_dir "$(dirname "$dest")"
  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry] backup $src -> $dest"
  else
    cp -p "$src" "$dest"
  fi
}

write_file() {
  local src="$1" dst="$2"
  ensure_dir "$(dirname "$dst")"
  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry] cp $src -> $dst"
  else
    cp -p "$src" "$dst"
  fi
}

remove_file() {
  local path="$1"
  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry] rm $path (orphan)"
  else
    rm -f "$path"
    # Drop the parent dir if it is now empty (e.g. a removed skill's folder).
    rmdir "$(dirname "$path")" 2>/dev/null || true
  fi
}

# tmp lock to write atomically at end
TMP_LOCK="$(mktemp)"
echo "# claude-workflow installed files. Format: <sha256>  <relative-path>" > "$TMP_LOCK"
echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$TMP_LOCK"
# Record source directory so find-workflow-home.sh can locate the clone later.
echo "# source_dir=$SCRIPT_DIR" >> "$TMP_LOCK"

# Iterate harness files
mapfile -t SRC_FILES < <(cd "$HARNESS_DIR" && find . -type f | sed 's|^\./||' | sort)

DEFERRED_SETTINGS=""

for rel in "${SRC_FILES[@]}"; do
  src="$HARNESS_DIR/$rel"
  dst="$TARGET_DIR/$rel"
  base="$(basename "$rel")"

  if is_local_file "$base"; then
    info "skip (local-owned): $rel"
    continue
  fi

  if is_merge_target "$base"; then
    DEFERRED_SETTINGS="$rel"
    continue
  fi

  src_hash="$(sha256_of "$src")"

  if [[ ! -e "$dst" ]]; then
    info "install: $rel"
    write_file "$src" "$dst"
    echo "$src_hash  $rel" >> "$TMP_LOCK"
    continue
  fi

  dst_hash="$(sha256_of "$dst")"
  if [[ "$src_hash" == "$dst_hash" ]]; then
    info "ok    : $rel (unchanged)"
    echo "$src_hash  $rel" >> "$TMP_LOCK"
    continue
  fi

  choice="$(prompt_conflict "$src" "$dst")"
  case "$choice" in
    k|K)
      info "keep  : $rel (user choice)"
      echo "$dst_hash  $rel  # user-modified, not from claude-workflow" >> "$TMP_LOCK"
      ;;
    o|O)
      info "overwrite: $rel"
      write_file "$src" "$dst"
      echo "$src_hash  $rel" >> "$TMP_LOCK"
      ;;
    d|D)
      diff -u "$dst" "$src" || true
      # Re-prompt
      choice2="$(prompt_conflict "$src" "$dst")"
      case "$choice2" in
        o|O)
          write_file "$src" "$dst"
          echo "$src_hash  $rel" >> "$TMP_LOCK"
          ;;
        b|B)
          backup_file "$dst"; write_file "$src" "$dst"
          echo "$src_hash  $rel" >> "$TMP_LOCK"
          ;;
        *)
          info "keep  : $rel"
          echo "$dst_hash  $rel  # user-modified" >> "$TMP_LOCK"
          ;;
      esac
      ;;
    b|B)
      info "backup&replace: $rel (backup -> $BACKUP_DIR)"
      backup_file "$dst"
      write_file "$src" "$dst"
      echo "$src_hash  $rel" >> "$TMP_LOCK"
      ;;
    s|S)
      info "stopping at user request"
      break
      ;;
    *)
      info "keep  : $rel"
      echo "$dst_hash  $rel  # user-modified" >> "$TMP_LOCK"
      ;;
  esac
done

# Handle settings.json merge
# Locate a usable Python (avoid Microsoft Store stub on Windows)
find_python() {
  if command -v uv >/dev/null 2>&1 && uv run --no-project python -c '' >/dev/null 2>&1; then
    echo "uv run --no-project python"; return
  fi
  if command -v py >/dev/null 2>&1 && py -3 -c '' >/dev/null 2>&1; then
    echo "py -3"; return
  fi
  for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c '' >/dev/null 2>&1; then
      echo "$candidate"; return
    fi
  done
  echo ""
}

if [[ -n "$DEFERRED_SETTINGS" && "$SKIP_MERGE" != "1" ]]; then
  partial="$HARNESS_DIR/$DEFERRED_SETTINGS"
  target="$TARGET_DIR/settings.json"
  info "merge: $DEFERRED_SETTINGS -> $target"
  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry] python $SCRIPT_DIR/scripts/settings-merge.py --partial $partial --target $target"
  else
    PYTHON_CMD="$(find_python)"
    if [[ -n "$PYTHON_CMD" ]]; then
      $PYTHON_CMD "$SCRIPT_DIR/scripts/settings-merge.py" --partial "$partial" --target "$target"
    else
      warn "python not found — skipping settings.json merge"
    fi
  fi
fi

# --- Orphan prune ---------------------------------------------------------
# Remove files a previous install wrote but that this version no longer ships.
# Safety: only prune when the target still matches the checksum we recorded
# (i.e. unchanged since we installed it). User-modified or drifted files are
# preserved with a warning. settings.json and *.local.* are never in the lock,
# so they can never be pruned here.
declare -A CURRENT_MANAGED=()
for rel in "${SRC_FILES[@]}"; do
  b="$(basename "$rel")"
  is_local_file "$b" && continue
  is_merge_target "$b" && continue
  CURRENT_MANAGED["$rel"]=1
done

ORPHANS_REMOVED=0
if [[ -f "$LOCK_FILE" ]]; then
  while IFS= read -r line; do
    [[ "$line" =~ ^# ]] && continue
    [[ -z "${line// /}" ]] && continue
    rec_hash="$(awk '{print $1}' <<< "$line")"
    rec_path="$(awk '{print $2}' <<< "$line")"
    [[ -z "$rec_path" ]] && continue
    [[ -n "${CURRENT_MANAGED[$rec_path]+x}" ]] && continue   # still shipped
    dst="$TARGET_DIR/$rec_path"
    [[ ! -e "$dst" ]] && continue                            # already gone
    if [[ "$line" == *"user-modified"* ]]; then
      warn "orphan (user-modified, preserved): $rec_path"
      continue
    fi
    cur_hash="$(sha256_of "$dst")"
    if [[ -n "$rec_hash" && "$cur_hash" == "$rec_hash" ]]; then
      info "prune orphan: $rec_path"
      remove_file "$dst"
      ORPHANS_REMOVED=$((ORPHANS_REMOVED + 1))
    else
      warn "orphan (changed since install, preserved): $rec_path"
    fi
  done < "$LOCK_FILE"
fi
[[ "$ORPHANS_REMOVED" -gt 0 ]] && info "pruned $ORPHANS_REMOVED orphan file(s)"

# Atomic lock write
if [[ "$DRY_RUN" != "1" ]]; then
  [[ -f "$LOCK_FILE" ]] && cp -p "$LOCK_FILE" "$LOCK_FILE.bak"
  mv "$TMP_LOCK" "$LOCK_FILE"
else
  rm -f "$TMP_LOCK"
fi

info "done. lock: $LOCK_FILE"
if [[ -d "$BACKUP_DIR" ]]; then
  info "backups: $BACKUP_DIR"
fi
