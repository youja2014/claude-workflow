#!/usr/bin/env bash
# scaffold.sh — Scaffold a new project (default) or adopt an existing one (--mode=existing).
#
# New mode (default):
#   bash scripts/scaffold.sh --stack <cli|fastapi|nx-monorepo> --name <project> [--dest <dir>] [--desc "..."]
#
# Existing mode (inject claude-workflow components into a pre-existing repo):
#   bash scripts/scaffold.sh --mode=existing --components=<comma> [--dest <dir>]
#   Components (B.1): githooks-universal, install-script
#   --dest must contain .git/ (defaults to current dir).
#   Conflict policy: skip if destination file already exists (idempotent).
#   The slash command is responsible for prompting users about overwrites.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$ROOT_DIR/templates"
PROJECT_OVERLAY="$ROOT_DIR/harness/project"

MODE=""
STACK=""
NAME=""
DEST=""
DESC=""
COMPONENTS=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)         MODE="$2"; shift 2 ;;
    --mode=*)       MODE="${1#*=}"; shift ;;
    --components)   COMPONENTS="$2"; shift 2 ;;
    --components=*) COMPONENTS="${1#*=}"; shift ;;
    --stack)        STACK="$2"; shift 2 ;;
    --stack=*)      STACK="${1#*=}"; shift ;;
    --name)         NAME="$2"; shift 2 ;;
    --name=*)       NAME="${1#*=}"; shift ;;
    --dest)         DEST="$2"; shift 2 ;;
    --dest=*)       DEST="${1#*=}"; shift ;;
    --desc)         DESC="$2"; shift 2 ;;
    --desc=*)       DESC="${1#*=}"; shift ;;
    --dry-run)      DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,13p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

# ============================================================
# Helpers shared by both modes
# ============================================================
sanitize_snake() { echo "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '_' | sed 's/__*/_/g; s/^_//; s/_$//'; }
sanitize_kebab() { echo "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/--*/-/g; s/^-//; s/-$//'; }

# Auto-detect stack from existing project files. Prints stack name or returns 1.
detect_stack() {
  local d="$1"
  local has_py=0 has_ts=0
  [[ -f "$d/pyproject.toml" ]] && has_py=1
  [[ -f "$d/package.json" ]]   && has_ts=1
  if [[ $has_py -eq 1 && $has_ts -eq 1 ]]; then
    echo "ERROR: both pyproject.toml and package.json found — pass --stack to disambiguate" >&2
    return 1
  fi
  if [[ $has_py -eq 1 ]]; then
    if grep -qE '(^|[^a-zA-Z_])fastapi([^a-zA-Z0-9_]|$)' "$d/pyproject.toml" 2>/dev/null; then
      echo "fastapi"
    else
      echo "cli"
    fi
    return 0
  fi
  if [[ $has_ts -eq 1 ]]; then
    echo "nx-monorepo"
    return 0
  fi
  return 1
}

# Extract project name from pyproject.toml or package.json. Best-effort.
detect_project_name() {
  local d="$1"
  if [[ -f "$d/pyproject.toml" ]]; then
    grep -E '^[[:space:]]*name[[:space:]]*=' "$d/pyproject.toml" 2>/dev/null \
      | head -1 \
      | sed -E 's/.*=[[:space:]]*"([^"]+)".*/\1/'
  elif [[ -f "$d/package.json" ]]; then
    grep -E '"name"[[:space:]]*:' "$d/package.json" 2>/dev/null \
      | head -1 \
      | sed -E 's/.*"name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
  fi
}

resolve_template_dir() {
  case "$1" in
    cli)         echo "$TEMPLATES_DIR/python-cli" ;;
    fastapi)     echo "$TEMPLATES_DIR/python-fastapi" ;;
    nx-monorepo) echo "$TEMPLATES_DIR/ts-nx" ;;
    *) return 1 ;;
  esac
}

# ============================================================
# MODE: existing (adopt claude-workflow into existing repo)
# ============================================================
if [[ "$MODE" == "existing" ]]; then
  [[ -z "$COMPONENTS" ]] && { echo "ERROR: --components required in existing mode" >&2; exit 2; }
  DEST="${DEST:-$(pwd)}"
  [[ -d "$DEST/.git" ]] || { echo "ERROR: --dest must contain .git/ (got: $DEST)" >&2; exit 1; }

  # Detect which components need stack/name resolution
  IFS=',' read -ra COMP_LIST <<< "$COMPONENTS"
  needs_stack=0
  needs_name=0
  for comp in "${COMP_LIST[@]}"; do
    case "$comp" in
      githooks-stack)   needs_stack=1 ;;
      makefile)         needs_stack=1; needs_name=1 ;;
      docs-skeleton)    needs_stack=1 ;;
      claude-md)        needs_stack=1; needs_name=1 ;;
    esac
  done

  if [[ $needs_stack -eq 1 ]]; then
    if [[ -z "$STACK" ]]; then
      STACK="$(detect_stack "$DEST")" \
        || { echo "ERROR: stack auto-detect failed; pass --stack <cli|fastapi|nx-monorepo>" >&2; exit 1; }
      echo "[scaffold-existing] detected stack: $STACK"
    fi
    TEMPLATE_DIR="$(resolve_template_dir "$STACK")" \
      || { echo "ERROR: unknown --stack $STACK (cli|fastapi|nx-monorepo)" >&2; exit 2; }
    [[ -d "$TEMPLATE_DIR" ]] || { echo "ERROR: template not found: $TEMPLATE_DIR" >&2; exit 1; }
  fi

  if [[ $needs_name -eq 1 ]]; then
    if [[ -z "$NAME" ]]; then
      NAME="$(detect_project_name "$DEST" 2>/dev/null || true)"
      [[ -n "$NAME" ]] && echo "[scaffold-existing] detected project name: $NAME"
    fi
    NAME="${NAME:-existing-project}"
    PKG_SNAKE="$(sanitize_snake "$NAME")"
    PKG_KEBAB="$(sanitize_kebab "$NAME")"
  fi

  installed=()
  skipped=()

  install_file() {
    local src="$1" dst="$2"
    if [[ ! -f "$src" ]]; then
      echo "ERROR: source not found: $src" >&2
      exit 1
    fi
    if [[ -e "$dst" ]]; then
      skipped+=("$dst")
      return
    fi
    mkdir -p "$(dirname "$dst")"
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "[dry] install: $dst <- $src"
    else
      cp -p "$src" "$dst"
    fi
    installed+=("$dst")
  }

  install_file_subst() {
    local src="$1" dst="$2"
    if [[ ! -f "$src" ]]; then
      echo "ERROR: source not found: $src" >&2
      exit 1
    fi
    if [[ -e "$dst" ]]; then
      skipped+=("$dst")
      return
    fi
    mkdir -p "$(dirname "$dst")"
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "[dry] install (subst): $dst <- $src"
    else
      sed -e "s|__package__|$PKG_SNAKE|g" \
          -e "s|__project_kebab__|$PKG_KEBAB|g" \
          -e "s|__project_name__|$NAME|g" \
          -e "s|__description__|${DESC:-$NAME}|g" \
          "$src" > "$dst"
    fi
    installed+=("$dst")
  }

  # Recursively copy a directory tree, calling install_file per regular file.
  # Per-file conflict policy (skip-if-exists) is inherited from install_file.
  install_dir() {
    local src_dir="$1" dst_dir="$2"
    if [[ ! -d "$src_dir" ]]; then
      echo "ERROR: source dir not found: $src_dir" >&2
      exit 1
    fi
    while IFS= read -r -d '' src_file; do
      local rel="${src_file#$src_dir/}"
      install_file "$src_file" "$dst_dir/$rel"
    done < <(find "$src_dir" -type f -print0)
  }

  for comp in "${COMP_LIST[@]}"; do
    case "$comp" in
      githooks-universal)
        install_file "$PROJECT_OVERLAY/.githooks/commit-msg" "$DEST/.githooks/commit-msg"
        install_file "$PROJECT_OVERLAY/.githooks/pre-push"   "$DEST/.githooks/pre-push"
        chmod +x "$DEST/.githooks/commit-msg" "$DEST/.githooks/pre-push" 2>/dev/null || true
        ;;
      install-script)
        install_file "$PROJECT_OVERLAY/scripts/install-git-hooks.sh" "$DEST/scripts/install-git-hooks.sh"
        chmod +x "$DEST/scripts/install-git-hooks.sh" 2>/dev/null || true
        ;;
      githooks-stack)
        install_file "$TEMPLATE_DIR/.githooks/pre-commit" "$DEST/.githooks/pre-commit"
        chmod +x "$DEST/.githooks/pre-commit" 2>/dev/null || true
        ;;
      makefile)
        install_file_subst "$TEMPLATE_DIR/Makefile" "$DEST/Makefile"
        ;;
      docs-skeleton)
        install_dir "$TEMPLATE_DIR/docs" "$DEST/docs"
        ;;
      claude-md)
        install_file_subst "$TEMPLATE_DIR/CLAUDE.md" "$DEST/CLAUDE.md"
        ;;
      *)
        echo "ERROR: unknown component: $comp" >&2
        echo "Available: githooks-universal, githooks-stack, install-script, makefile, docs-skeleton, claude-md" >&2
        exit 2
        ;;
    esac
  done

  echo "[scaffold-existing] installed: ${#installed[@]}"
  for p in "${installed[@]}"; do echo "  + $p"; done
  if [[ ${#skipped[@]} -gt 0 ]]; then
    echo "[scaffold-existing] skipped (already exists): ${#skipped[@]}"
    for p in "${skipped[@]}"; do echo "  = $p"; done
  fi
  exit 0
fi

# ============================================================
# MODE: new (default) — original behavior
# ============================================================
[[ -z "$STACK" ]] && { echo "ERROR: --stack required (cli|fastapi|nx-monorepo)" >&2; exit 2; }
[[ -z "$NAME"  ]] && { echo "ERROR: --name required" >&2; exit 2; }

case "$STACK" in
  cli)         TEMPLATE_DIR="$TEMPLATES_DIR/python-cli"; LANG="python" ;;
  fastapi)     TEMPLATE_DIR="$TEMPLATES_DIR/python-fastapi"; LANG="python" ;;
  nx-monorepo) TEMPLATE_DIR="$TEMPLATES_DIR/ts-nx"; LANG="ts" ;;
  *) echo "ERROR: unknown --stack $STACK (cli|fastapi|nx-monorepo)" >&2; exit 2 ;;
esac

[[ -d "$TEMPLATE_DIR" ]] || { echo "ERROR: template not found: $TEMPLATE_DIR" >&2; exit 1; }

DEST="${DEST:-$(pwd)/$NAME}"
[[ -e "$DEST" ]] && { echo "ERROR: destination exists: $DEST" >&2; exit 1; }

# Compute package/identifier names from project name
# python: snake_case, ts: kebab-case (npm name). Helpers defined near top.
PKG_SNAKE="$(sanitize_snake "$NAME")"
PKG_KEBAB="$(sanitize_kebab "$NAME")"

echo "[scaffold] stack=$STACK name=$NAME"
echo "[scaffold] dest=$DEST"
echo "[scaffold] package(snake)=$PKG_SNAKE  package(kebab)=$PKG_KEBAB"

if [[ "$DRY_RUN" == "1" ]]; then
  echo
  echo "[scaffold] DRY RUN — listing files that would be created:"
  ( cd "$TEMPLATE_DIR" && find . -type f \
      ! -path './node_modules/*' ! -path './.venv/*' ! -path './__pycache__/*' ! -path './dist/*' \
      | sed "s|^\./|$DEST/|" \
      | sed "s|__package__|$PKG_SNAKE|g" \
      | sort )
  echo
  echo "[scaffold] DRY RUN complete — no files written. Re-run without --dry-run to scaffold."
  exit 0
fi

# Rollback on failure: if anything below errors out, remove the partial dest.
cleanup_on_fail() {
  local ec=$?
  if [[ "$ec" -ne 0 && -d "$DEST" ]]; then
    echo "[scaffold] FAILED (exit=$ec); removing partial dest: $DEST" >&2
    rm -rf "$DEST"
  fi
  exit "$ec"
}
trap cleanup_on_fail EXIT

# 1. Copy template (preserve permissions, skip VCS dirs)
mkdir -p "$DEST"
( cd "$TEMPLATE_DIR" && tar cf - --exclude=node_modules --exclude=.venv --exclude=__pycache__ --exclude=dist . ) | ( cd "$DEST" && tar xf - )

# 1b. Overlay harness/project/ — stack-agnostic per-project assets shared across
# all 3 stacks (commit-msg, pre-push, install-git-hooks.sh). Stack-specific
# hooks (pre-commit) stay in templates/<stack>/.githooks/.
PROJECT_OVERLAY="$ROOT_DIR/harness/project"
if [[ -d "$PROJECT_OVERLAY" ]]; then
  ( cd "$PROJECT_OVERLAY" && tar cf - . ) | ( cd "$DEST" && tar xf - )
  # Ensure overlay scripts/hooks remain executable
  chmod +x "$DEST"/.githooks/* 2>/dev/null || true
  [[ -f "$DEST/scripts/install-git-hooks.sh" ]] && chmod +x "$DEST/scripts/install-git-hooks.sh"
fi

# 2. Rename __package__ directory if present (Python templates)
if [[ -d "$DEST/src/__package__" ]]; then
  mv "$DEST/src/__package__" "$DEST/src/$PKG_SNAKE"
fi

# Find a usable Python interpreter (avoid Microsoft Store stub on Windows).
find_python() {
  if command -v uv >/dev/null 2>&1; then
    if uv run --no-project python -c '' >/dev/null 2>&1; then
      echo "uv run --no-project python"
      return
    fi
  fi
  if command -v py >/dev/null 2>&1; then
    if py -3 -c '' >/dev/null 2>&1; then
      echo "py -3"
      return
    fi
  fi
  for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
      if "$candidate" -c 'import sys; sys.exit(0)' >/dev/null 2>&1; then
        echo "$candidate"
        return
      fi
    fi
  done
  echo ""
}

PYTHON_CMD="$(find_python)"
if [[ -z "$PYTHON_CMD" ]]; then
  echo "ERROR: no usable Python interpreter found (need uv, py, or python3)" >&2
  exit 1
fi

# 3. Substitute placeholders in text files
substitute_in() {
  local f="$1"
  $PYTHON_CMD - "$f" "$PKG_SNAKE" "$PKG_KEBAB" "$NAME" "$DESC" <<'PYEOF'
import sys, pathlib
path, snake, kebab, name, desc = sys.argv[1:]
p = pathlib.Path(path)
try:
    text = p.read_text(encoding="utf-8")
except (UnicodeDecodeError, IsADirectoryError):
    sys.exit(0)
replacements = {
    "__package__": snake,
    "__project_name__": name,
    "__project_kebab__": kebab,
    "__description__": desc or name,
}
new = text
for k, v in replacements.items():
    new = new.replace(k, v)
if new != text:
    p.write_text(new, encoding="utf-8")
PYEOF
}

# Iterate files (skip binaries and node_modules/.venv if present)
while IFS= read -r -d '' f; do
  case "$f" in
    *.png|*.jpg|*.jpeg|*.gif|*.ico|*.pdf|*.zip|*.gz|*.exe|*.lock) continue ;;
  esac
  substitute_in "$f"
done < <(find "$DEST" -type f -print0)

# 4. Write version stamp so the scaffolded project knows which claude-workflow it came from
WORKFLOW_REV="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
WORKFLOW_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > "$DEST/.claude-workflow-version" <<EOF
# This file records the version of claude-workflow that scaffolded this project.
# Update it manually when you cherry-pick changes from the upstream templates.
stack=$STACK
workflow_rev=$WORKFLOW_REV
scaffolded_at=$WORKFLOW_DATE
EOF

# 5. git init
( cd "$DEST" && git init -q && git add -A && git commit -q -m "chore: scaffold $STACK from claude-workflow" || true )

# 6. Stack-specific post-init
case "$LANG" in
  python)
    echo "[scaffold] python post-init"
    ( cd "$DEST" && uv sync --quiet || echo "[scaffold] uv sync skipped (run manually)" )
    ;;
  ts)
    echo "[scaffold] typescript post-init"
    if [[ -f "$DEST/package.json" ]]; then
      ( cd "$DEST" && corepack enable 2>/dev/null; yarn install --silent || echo "[scaffold] yarn install skipped (run manually)" )
    fi
    ;;
esac

# Install local git hooks (vendor-neutral, applies to all stacks)
if [[ -f "$DEST/scripts/install-git-hooks.sh" ]]; then
  ( cd "$DEST" && bash scripts/install-git-hooks.sh >/dev/null 2>&1 \
    || echo "[scaffold] git hooks install skipped (run: bash scripts/install-git-hooks.sh)" )
fi

echo
echo "[scaffold] done. next steps:"
echo "  cd $DEST"
case "$LANG" in
  python) echo "  make doctor && make test" ;;
  ts)     echo "  yarn doctor && yarn test" ;;
esac
