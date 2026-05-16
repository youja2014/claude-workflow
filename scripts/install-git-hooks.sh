#!/usr/bin/env bash
# install-git-hooks.sh — Point this repo's git config to .githooks/.
#
# After running, 'git push' will execute .githooks/pre-push, which runs
# 'make verify'. This is the vendor-neutral substitute for a CI job —
# works identically on any developer machine, no minutes consumed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

if [[ ! -d .git ]]; then
  echo "ERROR: not a git repo: $ROOT_DIR" >&2
  exit 1
fi

if [[ ! -d .githooks ]]; then
  echo "ERROR: .githooks/ not found at $ROOT_DIR/.githooks" >&2
  exit 1
fi

# Make hook scripts executable (lost on some Windows filesystems)
chmod +x .githooks/* 2>/dev/null || true

git config core.hooksPath .githooks
echo "[install-git-hooks] core.hooksPath -> .githooks"
echo "[install-git-hooks] active hooks:"
for h in .githooks/*; do
  [[ -f "$h" ]] && echo "  - $(basename "$h")"
done
echo
echo "Test it:  git push --dry-run    (will execute pre-push without sending)"
