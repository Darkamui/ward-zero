#!/usr/bin/env python3
"""Localization lint (docs/01-foundation.md §7, rules R3 and R4).

Errors (exit 1):
  - CSV header is not exactly keys,en,fr_CA
  - empty translation, duplicate key, malformed key
  - EN and FR placeholder sets differ
  - a *_key / key reference in a .tres or .tscn points to a missing key
  - a user-facing string literal assigned to `text` in game scenes/scripts
Warnings:
  - French typography: missing NBSP before : ; ! ? or inside « »
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOC_DIR = ROOT / "game" / "localization"
GAME_DIR = ROOT / "game"
HEADER = ["keys", "en", "fr_CA"]
KEY_RE = re.compile(r"^[a-z0-9_]+(\.[a-z0-9_]+)+$")
PLACEHOLDER_RE = re.compile(r"\{([a-zA-Z0-9_]+)\}")
# Paths (relative to game/) where literals are allowed.
LITERAL_ALLOW = ("debug/",)
NBSP_CHARS = (" ", " ")


def load_keys(errors: list[str], warnings: list[str]) -> set[str]:
    keys: set[str] = set()
    for path in sorted(LOC_DIR.glob("*.csv")):
        rel = path.relative_to(ROOT)
        with path.open(newline="", encoding="utf-8") as f:
            rows = list(csv.reader(f))
        if not rows or rows[0] != HEADER:
            errors.append(f"{rel}: header must be {','.join(HEADER)}")
            continue
        if len([r for r in rows[1:] if r and any(c.strip() for c in r)]) == 0:
            errors.append(f"{rel}: no rows (every domain listed in setup_project.gd needs at least one)")
        for line_no, row in enumerate(rows[1:], start=2):
            if not row or all(not c.strip() for c in row):
                continue
            where = f"{rel}:{line_no}"
            if len(row) != 3:
                errors.append(f"{where}: expected 3 columns, got {len(row)}")
                continue
            key, en, fr = row
            if not KEY_RE.match(key):
                errors.append(f"{where}: malformed key '{key}'")
            if key in keys:
                errors.append(f"{where}: duplicate key '{key}'")
            keys.add(key)
            if not en.strip():
                errors.append(f"{where}: '{key}' missing en")
            if not fr.strip():
                errors.append(f"{where}: '{key}' missing fr_CA")
            if set(PLACEHOLDER_RE.findall(en)) != set(PLACEHOLDER_RE.findall(fr)):
                errors.append(
                    f"{where}: '{key}' placeholders differ: en {sorted(set(PLACEHOLDER_RE.findall(en)))}"
                    f" vs fr {sorted(set(PLACEHOLDER_RE.findall(fr)))}"
                )
            check_french_typography(where, key, fr, warnings)
    return keys


def check_french_typography(where: str, key: str, fr: str, warnings: list[str]) -> None:
    # Strip placeholders and URLs so "{a}:" or "https:" do not trigger.
    text = PLACEHOLDER_RE.sub("", re.sub(r"https?://\S+", "", fr))
    for i, ch in enumerate(text):
        if ch in ":;!?" and i > 0:
            prev = text[i - 1]
            if prev == " ":
                warnings.append(f"{where}: '{key}' use NBSP (not a space) before '{ch}'")
            elif ch == ":" and prev not in NBSP_CHARS and not prev.isdigit():
                warnings.append(f"{where}: '{key}' missing NBSP before ':'")
    if "«" in text and not re.search("«[  ]", text):
        warnings.append(f"{where}: '{key}' missing NBSP after «")
    if "»" in text and not re.search("[  ]»", text):
        warnings.append(f"{where}: '{key}' missing NBSP before »")


KEY_REF_RES = [
    re.compile(r'^\s*(\w*_key|key)\s*=\s*"([^"]*)"', re.M),
]
TEXT_LITERAL_TSCN = re.compile(r'^\s*(text|tooltip_text|placeholder_text|title)\s*=\s*"([^"]+)"', re.M)
TEXT_LITERAL_GD = re.compile(r'\.(text|tooltip_text|placeholder_text)\s*=\s*"([^"]+)"')


def check_references(keys: set[str], errors: list[str]) -> None:
    for path in sorted(GAME_DIR.rglob("*")):
        if path.suffix not in (".tres", ".tscn", ".gd"):
            continue
        rel = path.relative_to(ROOT)
        rel_game = path.relative_to(GAME_DIR).as_posix()
        text = path.read_text(encoding="utf-8", errors="replace")
        if path.suffix in (".tres", ".tscn"):
            for rx in KEY_REF_RES:
                for m in rx.finditer(text):
                    value = m.group(2)
                    if value and value not in keys:
                        errors.append(f"{rel}: {m.group(1)} references missing key '{value}'")
        if rel_game.startswith(LITERAL_ALLOW):
            continue
        rx = TEXT_LITERAL_TSCN if path.suffix == ".tscn" else TEXT_LITERAL_GD
        if path.suffix == ".tres":
            continue
        for m in rx.finditer(text):
            value = m.group(2)
            if KEY_RE.match(value):
                if value not in keys:
                    errors.append(f"{rel}: {m.group(1)} uses missing key '{value}'")
                continue
            if value.strip() and not value.startswith(("res://", "%")):
                errors.append(f"{rel}: user-facing literal in {m.group(1)}: \"{value}\" (use a translation key)")


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []
    keys = load_keys(errors, warnings)
    check_references(keys, errors)
    for w in warnings:
        print(f"warning: {w}")
    for e in errors:
        print(f"error: {e}")
    print(f"loc_lint: {len(keys)} keys, {len(errors)} errors, {len(warnings)} warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
