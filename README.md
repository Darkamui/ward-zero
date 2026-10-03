# Ward Zero / Aile Zéro

Psychological survival-horror escape room for desktop browsers: fixed-camera, pre-rendered rooms in the style of classic Resident Evil. Godot 4 web export, English and Québec French.

Design: [`docs/GDD.md`](docs/GDD.md). Plan: [`docs/README.md`](docs/README.md).

## Pinned versions

| Tool | Version |
|---|---|
| Godot | **4.7.2-stable** (standard build, GDScript only) plus matching export templates |
| gdtoolkit | 4.5.0 (`pip install -r tools/requirements.txt`) |
| Python | 3.11+ |
| Blender | current LTS (art pipeline, see `docs/pipeline/backgrounds.md`) |

Don't upgrade Godot mid-milestone (ADR-001).

## Commands

Run from this folder.

| What | Command |
|---|---|
| First import (generates `.godot/` and translations) | `godot --headless --import` |
| Re-apply project settings (input map, autoloads, layers) | `godot --headless --script res://tools/setup_project.gd` |
| Run the game | `godot` (or open in the editor and press F5) |
| Unit tests | `godot --headless res://tests/run_tests.tscn` (filter: append `-- --filter=seed`) |
| Lint + format check | `gdformat --line-length 110 --check game tests tools && gdlint game tests tools` |
| Localization lint | `python3 tools/loc_lint.py` |
| Web export | `godot --headless --export-release Web build/web/index.html` |
| Web size report | `python3 tools/size_report.py build/web` |
| Serve the web build locally | `python3 -m http.server -d build/web 8000` |

Install the pre-commit hook: `cp tools/pre-commit ../.git/hooks/pre-commit` (or `.git/hooks/` once this is its own repo).

## Layout

`game/` holds everything shipped (autoloads, schemas, core components, rooms, puzzles, UI, localization). `tests/` holds the test runner and unit tests. `tools/` holds lint, setup and pipeline scripts. `production/` holds time logs and reports. See `docs/01-foundation.md` §5.

## Localization

All user-facing text goes through keys in `game/localization/*.csv` (`keys,en,fr_CA`). No string literals in scenes or scripts (rule R3). Placeholders like `{frequency}` must appear in both languages (rule R4). `tools/loc_lint.py` enforces both.
