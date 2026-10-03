#!/usr/bin/env python3
"""Reports raw, gzip and brotli sizes of a web export and enforces the first-download
budget (GDD §9.4: 40 MB). Usage: size_report.py <build dir> [--budget-mb 40] [--summary FILE]
Brotli is reported only if the `brotli` module is installed; the budget uses the
smaller compressed size available (what a CDN would serve).
"""
from __future__ import annotations

import argparse
import gzip
import sys
from pathlib import Path

try:
    import brotli  # type: ignore
except ImportError:  # pragma: no cover
    brotli = None

INITIAL_EXTS = {".wasm", ".pck", ".js", ".html", ".png", ".ico", ".svg"}


def mb(n: int) -> str:
    return f"{n / 1_000_000:.2f} MB"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("build_dir", type=Path)
    ap.add_argument("--budget-mb", type=float, default=40.0)
    ap.add_argument("--summary", type=Path, help="append a Markdown table here (e.g. $GITHUB_STEP_SUMMARY)")
    args = ap.parse_args()

    rows = []
    total_raw = total_best = 0
    for path in sorted(args.build_dir.iterdir()):
        if not path.is_file() or path.suffix not in INITIAL_EXTS:
            continue
        data = path.read_bytes()
        gz = len(gzip.compress(data, compresslevel=9))
        br = len(brotli.compress(data, quality=11)) if brotli else None
        best = min(gz, br) if br is not None else gz
        rows.append((path.name, len(data), gz, br))
        total_raw += len(data)
        total_best += best

    lines = ["| File | Raw | Gzip | Brotli |", "|---|---|---|---|"]
    for name, raw, gz, br in rows:
        lines.append(f"| {name} | {mb(raw)} | {mb(gz)} | {mb(br) if br is not None else 'n/a'} |")
    ok = total_best <= args.budget_mb * 1_000_000
    lines.append(f"| **Total** | {mb(total_raw)} | | best compressed **{mb(total_best)}** |")
    lines.append("")
    lines.append(f"First-download budget {args.budget_mb:.0f} MB: {'OK' if ok else 'OVER BUDGET'}")
    report = "\n".join(lines)
    print(report)
    if args.summary:
        with args.summary.open("a", encoding="utf-8") as f:
            f.write("## Web build size\n\n" + report + "\n")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
