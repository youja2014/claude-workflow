#!/usr/bin/env bash
# doctor.sh — Verify host environment for claude-workflow.
set -uo pipefail

PASS=0
FAIL=0
WARN=0

check() {
  local name="$1" cmd="$2" required="$3"
  if eval "$cmd" >/dev/null 2>&1; then
    local ver
    ver=$(eval "$cmd" 2>&1 | head -n1 | tr -d '\r')
    printf '  [OK]   %-20s %s\n' "$name" "$ver"
    PASS=$((PASS+1))
  else
    if [[ "$required" == "required" ]]; then
      printf '  [FAIL] %-20s not found (required)\n' "$name"
      FAIL=$((FAIL+1))
    else
      printf '  [WARN] %-20s not found (optional)\n' "$name"
      WARN=$((WARN+1))
    fi
  fi
}

echo "claude-workflow doctor — host environment check"
echo

echo "Core tooling:"
check "git"          "git --version"               required
check "bash"         "bash --version"              required
check "python3"      "python3 --version"           required
check "uv"           "uv --version"                required
check "node"         "node --version"              required
check "yarn"         "yarn --version"              required
check "docker"       "docker --version"            required
check "docker compose" "docker compose version"    required

echo
echo "Optional/dev tooling:"
check "pre-commit"   "pre-commit --version"        optional
check "jq"           "jq --version"                optional
check "gh"           "gh --version"                optional
check "make"         "make --version"              optional
check "ruff"         "uvx ruff --version"          optional
check "pyright"      "uvx pyright --version"       optional

echo
echo "Versions of interest:"
if command -v python3 >/dev/null 2>&1; then
  py_ver=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
  if [[ "$(printf '%s\n' "3.12" "$py_ver" | sort -V | head -n1)" == "3.12" ]]; then
    echo "  [OK]   python>=3.12 ($py_ver)"
  else
    echo "  [WARN] python < 3.12 ($py_ver) — uv-managed 3.12 recommended"
    WARN=$((WARN+1))
  fi
fi

if command -v node >/dev/null 2>&1; then
  node_ver=$(node --version | sed 's/^v//')
  node_major=$(echo "$node_ver" | cut -d. -f1)
  if [[ "$node_major" -ge 20 ]]; then
    echo "  [OK]   node>=20 ($node_ver)"
  else
    echo "  [WARN] node < 20 ($node_ver) — LTS recommended"
    WARN=$((WARN+1))
  fi
fi

echo
echo "Summary: $PASS pass, $WARN warn, $FAIL fail"
[[ "$FAIL" -gt 0 ]] && exit 1 || exit 0
