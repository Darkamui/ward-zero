# Ward Zero — asset library

## Current project status

This folder preserves the supplied starter pack and later character references. G01 now uses selected UI artwork, radio components, props and starter effects from this library. Current integration status is tracked in [the production queue](../production/g01_asset_progress.md); the original pack notes below describe its delivery state, not the current game.

Unused stock, concepts and previews are retained for future work but excluded from Web export in `export_presets.cfg`. When integrating one of those assets, remove its matching export exclusion and verify the exported build. Keep import settings with retained runtime assets. Shared folder, paper and satchel originals live only in `art/ui/`.

The JSON documents and voice scripts in `data/` are historical starter examples. Authoritative narrative and puzzle bindings live in `game/localization/` and `game/data/`. `data/asset-manifest.json` inventories the current library sources, excluding Godot import sidecars, caches and itself.

## Original starter-pack notes

Scope: shared UI for Act 1, not a playable game or completed room art.

## Included
- Three independently generated RGBA artwork components: empty patient folder, satchel lining, blank document paper. Generated with the built-in image tool. Preserve aspect ratio; do not stretch with nine-patch slicing. Alpha channels are present; check soft edge halos against your actual game background.
- 16 original editable SVG interface symbols in ivory, dark ink and focus amber (48 files). SVGs use a 32×32 viewBox. Import at 32 or 64 pixels; keep button hit areas at least 44×44 logical pixels.
- Empty, hover, selected and disabled inventory slot frames, plus a subtitle panel.
- Bilingual Act 1 document templates with named bindings. These are authored starter content, not final difficulty-balanced puzzle rules.
- Machine-readable UI palette and layout recommendations.

## Layering
Inventory: dimmed game → satchel artwork → independent 3×2 slot grid → item thumbnails → focus frame → localized labels. Put key-pouch control over the right pocket. Never place critical instructions in the canvas texture.

Files: dimmed game → folder artwork → selectable file list on left → paper artwork and independently rendered text on right. Use a separate full-page reader for long documents.

Keep all text, numbers, tabs, buttons and puzzle answers separate from the bitmap. Use the same seeded puzzle data to fill a clue and evaluate its answer. Switching language must not regenerate those values.

Document text should be dark ink on the light paper, starting around 24 px at 1920×1080; provide enlargement/scrolling. Menu text should use a clear sans-serif; typewriter styling is optional for headings. Validate œ, Œ, é, è, ê, à, ç, ù and curly apostrophes in the selected font.

## Icons
eye=examine, hand=take/use, exit=leave, lock=locked, key=key pouch, folder=files, map=map, cassette=tapes/save, play/pause/stop=tape controls, back/close=screen controls, settings=options, sound=sound-direction toggle, combine=combine items.
These are symbols; cursor hotspot coordinates still need defining in Godot. Use eye center for examine and fingertip for hand. Do not rely on amber alone for focus: also use an outline/selection marker.

## Act 1 asset queue
1. G01 Dayroom: two Blender-rendered camera backgrounds and matching proxy geometry; radio close-up with separate knob/needle; door-chain state; wristband and dictaphone models.
2. G06 Chapel: same camera geometry across present and 1976; separate hymn number tiles; music-box crank model.
3. G02–G05: remaining eight present-day camera backgrounds, switchboard/card-catalog/safe interfaces, Photograph anchor, Choleric key.
4. Two character models plus idle/walk/run/interaction animations and scripted Lobby→Dayroom chase.

Final Act 1 background target: 12 present-day + 2 Chapel memory renders. This package contains no room renders, character models, sound recordings or downloaded third-party assets.

## Free sourcing shortlist
- https://polyhaven.com/models — CC0. Candidate names: Drawer Cabinet, Wooden Chair 01, Painted Wooden Bench, Vintage Cabinet 01, Office Notepads, Vintage Radio Transceiver. Inspect period suitability before adoption; the radio needs customized gameplay controls.
- https://ambientcg.com/ — CC0 surface materials.
- https://kenney.nl/assets/input-prompts — CC0 keyboard/mouse glyphs.
- https://kenney.nl/assets/cursor-pack — CC0 alternative cursors.
- https://www.mixamo.com/ — free Adobe-ID access; characters/animations usable in games under Adobe terms, not CC0. https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html

Links and licensing checked 2026-10-02. No third-party files redistributed in this package. Custom SVGs and templates were created for this project.

## Verification status
PNG dimensions/alpha, SVG XML and JSON syntax checked. Artwork visually reviewed. Not yet integrated or tested in Godot; no performance, cursor alignment or accessibility certification implied.
