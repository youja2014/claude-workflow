#!/usr/bin/env bash
# scaffold.sh — Create a new project from a template.
#
# Called by /new-project command or directly:
#   bash scripts/scaffold.sh --stack <cli|fastapi|nestjs|vite-react> --name <project> [--dest <dir>] [--desc "..."]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$ROOT_DIR/templates"

STACK=""
NAME=""
DEST=""
DESC=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stack) STACK="$2"; shift 2 ;;
    --name)  NAME="$2";  shift 2 ;;
    --dest)  DEST="$2";  shift 2 ;;
    --desc)  DESC="$2";  shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,8p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$STACK" ]] && { echo "ERROR: --stack required (cli|fastapi|nestjs|vite-react)" >&2; exit 2; }
[[ -z "$NAME"  ]] && { echo "ERROR: --name required" >&2; exit 2; }

case "$STACK" in
  cli)         TEMPLATE_DIR="$TEMPLATES_DIR/python-cli"; LANG="python" ;;
  fastapi)     TEMPLATE_DIR="$TEMPLATES_DIR/python-fastapi"; LANG="python" ;;
  nestjs)      TEMPLATE_DIR="$TEMPLATES_DIR/ts-nestjs"; LANG="ts" ;;
  vite-react)  TEMPLATE_DIR="$TEMPLATES_DIR/ts-vite-react"; LANG="ts" ;;
  nx-monorepo) TEMPLATE_DIR="$TEMPLATES_DIR/ts-nx"; LANG="ts" ;;
  *) echo "ERROR: unknown --stack $STACK (cli|fastapi|nestjs|vite-react|nx-monorepo)" >&2; exit 2 ;;
esac

[[ -d "$TEMPLATE_DIR" ]] || { echo "ERROR: template not found: $TEMPLATE_DIR" >&2; exit 1; }

DEST="${DEST:-$(pwd)/$NAME}"
[[ -e "$DEST" ]] && { echo "ERROR: destination exists: $DEST" >&2; exit 1; }

# Compute package/identifier names from project name
# python: snake_case, ts: kebab-case (npm name)
sanitize_snake() { echo "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '_' | sed 's/__*/_/g; s/^_//; s/_$//'; }
sanitize_kebab() { echo "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed 's/--*/-/g; s/^-//; s/-$//'; }

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
    ( cd "$DEST" && command -v pre-commit >/dev/null && pre-commit install -q || \
        uvx --quiet pre-commit install || \
        echo "[scaffold] pre-commit install skipped (run: uvx pre-commit install)" ) 2>/dev/null || true
    ;;
  ts)
    echo "[scaffold] typescript post-init"
    if [[ -f "$DEST/package.json" ]]; then
      ( cd "$DEST" && corepack enable 2>/dev/null; yarn install --silent || echo "[scaffold] yarn install skipped (run manually)" )
      ( cd "$DEST" && yarn run prepare 2>/dev/null || echo "[scaffold] husky prepare skipped (run: yarn run prepare)" )
    fi
    ;;
esac

echo
echo "[scaffold] done. next steps:"
echo "  cd $DEST"
case "$LANG" in
  python) echo "  make doctor && make test" ;;
  ts)     echo "  yarn doctor && yarn test" ;;
esac
