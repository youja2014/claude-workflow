#!/usr/bin/env python3
"""Safely merge a partial settings.json into the user's settings.json.

Rules
-----
- Top-level scalar/dict keys in partial overwrite target ONLY if missing in target
  (never clobber user customization).
- ``hooks``: deep merge. For each event (PreToolUse/PostToolUse/UserPromptSubmit/etc.),
  hooks with the same ``matcher`` are merged by appending unique commands; identical
  commands are skipped (idempotent re-install).
- ``permissions`` and ``env``: shallow merge, partial keys win only if missing.
- Always writes valid JSON with trailing newline. Backs up the target to
  ``settings.json.bak`` before write.

Usage
-----
    python3 settings-merge.py --partial harness/settings.json --target ~/.claude/settings.json
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path
from typing import Any


def _load(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    if not text.strip():
        return {}
    return json.loads(text)


def _dump(path: Path, data: dict[str, Any]) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def _merge_hook_event(
    target_hooks: list[dict[str, Any]],
    partial_hooks: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """Merge a list of hook entries keyed by ``matcher``."""
    by_matcher: dict[str, dict[str, Any]] = {}
    for entry in target_hooks:
        m = entry.get("matcher", "")
        by_matcher[m] = {"matcher": m, "hooks": list(entry.get("hooks", []))}

    for entry in partial_hooks:
        m = entry.get("matcher", "")
        bucket = by_matcher.setdefault(m, {"matcher": m, "hooks": []})
        existing_cmds = {
            json.dumps(h, sort_keys=True) for h in bucket["hooks"]
        }
        for h in entry.get("hooks", []):
            key = json.dumps(h, sort_keys=True)
            if key not in existing_cmds:
                bucket["hooks"].append(h)
                existing_cmds.add(key)

    return list(by_matcher.values())


def _merge_hooks(target: dict[str, Any], partial: dict[str, Any]) -> dict[str, Any]:
    out: dict[str, Any] = dict(target)
    for event, partial_entries in partial.items():
        if not isinstance(partial_entries, list):
            continue
        target_entries = out.get(event, [])
        if not isinstance(target_entries, list):
            target_entries = []
        out[event] = _merge_hook_event(target_entries, partial_entries)
    return out


def merge(target: dict[str, Any], partial: dict[str, Any]) -> dict[str, Any]:
    out: dict[str, Any] = dict(target)
    for key, val in partial.items():
        if key == "hooks" and isinstance(val, dict):
            out["hooks"] = _merge_hooks(out.get("hooks", {}) or {}, val)
        elif key in ("permissions", "env") and isinstance(val, dict):
            existing = out.get(key, {}) or {}
            merged = dict(val)
            merged.update(existing)
            out[key] = merged
        elif key not in out:
            out[key] = val
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--partial", required=True, type=Path)
    parser.add_argument("--target", required=True, type=Path)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    partial = _load(args.partial)
    target = _load(args.target)
    merged = merge(target, partial)

    if args.dry_run:
        print(json.dumps(merged, indent=2, ensure_ascii=False))
        return 0

    if args.target.exists():
        backup = args.target.with_suffix(args.target.suffix + ".bak")
        shutil.copy2(args.target, backup)

    args.target.parent.mkdir(parents=True, exist_ok=True)
    _dump(args.target, merged)
    print(f"[settings-merge] wrote {args.target}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
