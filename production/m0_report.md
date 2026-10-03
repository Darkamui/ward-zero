# M0 Report (greybox pass)

M0 was run against a **greybox** G01 Dayroom: geometry built by `tools/greybox/build_g01.gd` and clay-rendered in Godot (`tools/greybox/render_room.gd`) instead of Blender. That retires the engine-side risk (occlusion, camera cuts, click-to-move, web export). The Blender + AI paintover half of the pipeline still has to be run on a real room (see "Still open").

## Exit criteria status

| Criterion (docs/01-foundation.md §10.1) | Status | Evidence |
|---|---|---|
| Test room with 2 cameras through the pipeline | ✅ greybox, ⏳ Blender/paintover | `game/rooms/g01_dayroom/`, `bg/cam_a.webp`, `bg/cam_b.webp` |
| Occlusion check on both cameras | ✅ | `screens/m0_02_cam_a_behind_pillar.png` (half-hidden behind pillar), `m0_04_cam_b_behind_chair.png`, `m0_03_cam_a_debug_proxies.png` (proxy tint aligns pixel-for-pixel) |
| Click-to-move across the cut, no stall, no flip | ✅ | `tools/smoke/m0_screens.gd`, `tests/integration/test_room_g01.gd::test_walk_across_cut_arrives` (one cut, arrives in ~3 s) |
| One hotspot with cursor change and localized text | ✅ | 6 hotspots in G01, EN/FR strings in `rooms.csv`, `test_examine_hotspot_shows_text` |
| Web build on a static host, loads in Chrome/Firefox/Edge | ✅ Chromium (headless, SwiftShader), ⏳ Firefox/Edge, ⏳ itch.io | `tools/smoke/web_smoke.cjs`, `screens/web_desktop.png` |
| 60 fps on an integrated-GPU laptop | ⏳ | Needs real hardware. SwiftShader numbers are meaningless. |
| Phone user agent gets the block message | ✅ | `screens/web_phone.png` |
| Pipeline doc written, LUT locked | ✅ doc, ⏳ LUT | `docs/pipeline/backgrounds.md`. `post_look.gdshader` supports a 32³ LUT; no LUT chosen yet. |

## Measurements

| Measurement | Value |
|---|---|
| Web release export, raw | 40.4 MB (wasm 39.5 MB) |
| Web release export, gzip | **10.7 MB** (budget 40 MB, so ~29 MB left for Act 1) |
| Boot time, headless Chromium, localhost | 3.5 s to engine start |
| Greybox background size | 26–35 KB per WebP (clay renders compress far better than final art will) |
| Greybox build + render + import time | ~40 s per room on CPU rendering |

## Findings that changed the code

1. **Area enter events are unreliable for camera cuts** after teleports/spawns (the first event depends on where the body was before). Cuts now use a per-frame containment check with hysteresis (`CameraDirector.zone_camera_for`).
2. **Re-assigning a baked NavigationMesh object is a no-op**: bake into a fresh mesh, then assign (`Room._bake_navigation`).
3. **Furniture tops became walkable islands**: the bake is clipped to floor height with `filter_baking_aabb`.
4. **Navmesh sits ~0.2 m above the floor** (voxel rounding), and NavigationAgent3D distances are 3D, so `path_desired_distance` must exceed that or the agent stalls.
5. The content test caught the radio table blocking the door's approach point. Content validation pays off immediately.
6. Godot `--script` mode has no autoloads, so tools run through `tools/run_tool.tscn`.

## Still open (do on real hardware)

- Run one room through Blender → render → AI paintover → glTF proxy (§8.1–8.3), and repeat the occlusion check. Log hours per step in `time_log.csv`.
- fps / frame-time p95 in Chrome and Firefox on an integrated GPU.
- Does a low-pass on the `Ambience` bus work in web Sample playback mode?
- `user://` persistence across hard reload and browser restart in each browser (testable once SaveSystem has UI, M1).
- Choose and lock the LUT.
