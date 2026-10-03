"""Helpers for scripts that add rows to game/localization/*.csv.

fr() applies Québec French typography: NBSP before : ; ! ? and inside « ».
add() appends rows whose keys are not present yet (never overwrites edits).
"""
import csv
import re
from pathlib import Path

NB = " "
LOC = Path(__file__).resolve().parent.parent.parent / "game" / "localization"


def fr(text: str) -> str:
    text = re.sub(r" ([:;!?])", NB + r"\1", text)
    text = re.sub(r"(\d) (h|A|kHz)\b", r"\1" + NB + r"\2", text)
    text = text.replace("« ", "«" + NB).replace(" »", NB + "»")
    return text


def add(domain: str, rows):
    path = LOC / f"{domain}.csv"
    existing = list(csv.reader(path.open(encoding="utf-8")))
    keys = {r[0] for r in existing}
    for key, en, fr_text in rows:
        if key not in keys:
            existing.append([key, en, fr(fr_text)])
            keys.add(key)
    with path.open("w", newline="", encoding="utf-8") as f:
        csv.writer(f, lineterminator="\n").writerows(existing)
