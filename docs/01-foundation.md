# Ward Zero: Foundation and M0 Tech Spike

**Goal:** Get from an empty repo to a web build on a static host that proves the riskiest part of the project, the pre-rendered background pipeline with correct occlusion, using the code skeleton every later milestone will build on.

**Ends when:** the M0 exit criteria in §10 are met and the measurements in §10.3 are recorded.

Read [`00-overview.md`](./00-overview.md) first, especially the engineering rules (§3) and ADRs (§4).

Sizing: **S** ≈ one work session, **M** ≈ 2–4 sessions, **L** ≈ 5 or more.

---

## 1. Task List

| ID | Task | Size | Depends on | Done when |
|---|---|---|---|---|
| F-01 | Create the `ward-zero` repo, set up LFS, `.gitignore`, README, move docs in | S | | §3 checklist complete |
| F-02 | Install and pin the toolchain, write it down in the README | S | F-01 | §2 table filled in with exact versions |
| F-03 | Godot project with baseline settings | S | F-02 | §4 settings applied and committed |
| F-04 | Folder structure and autoload stubs | S | F-03 | §5 tree exists. Autoloads load with no errors. |
| F-05 | Data schema `Resource` classes (v1) | M | F-04 | §6 classes exist, each with one example `.tres` |
| F-06 | Localization pipeline and lint | S | F-04 | §7 done. Switching language at runtime works on a test label. |
| F-07 | Test framework and first unit tests | S | F-04 | Test runner works headless. GameState and Seed tests pass. |
| F-08 | CI: lint, test, web export, size report, deploy | M | F-06, F-07 | §9 pipeline green on `main`. Build reachable at the playtest URL. |
| F-09 | Write the ADRs (001–007 from the Overview) | S | F-01 | `docs/adr/` committed |
| M0-01 | Blender test room: kitbash, light, 2 cameras | M | F-02 | §8.1 done |
| M0-02 | Render, paint over, export WebP plus proxy glTF | M | M0-01 | §8.2 and §8.3 done |
| M0-03 | Import pipeline: post-import script, occluder shader, backdrop | L | M0-02, F-04 | §8.4 occlusion check passes on both cameras |
| M0-04 | CameraDirector with trigger volumes and background swap | M | M0-03 | Cuts are clean, with no ping-pong at the boundary |
| M0-05 | PlayerController: click-to-move, double-click run, path kept across a cut | M | M0-03 | Walking from cam A's area into cam B's never flips the controls or stops the path |
| M0-06 | Placeholder character with idle/walk/run animation and a matched light rig | M | M0-05 | Character lighting reads as part of the render (side-by-side screenshot review) |
| M0-07 | One Interactable hotspot (examine, shows localized text) with cursor change | S | M0-05, F-06 | Click → walk → interact → text in EN and FR |
| M0-08 | Post-process look, first pass (LUT, grain, CA, vignette) | S | M0-03 | Applied to the background and the character together |
| M0-09 | Custom HTML shell: mobile/tablet block, WebGL 2 check | S | F-08 | Phone user agent sees the message, not a broken load |
| M0-10 | Web platform checks: perf, size, audio playback mode, IndexedDB persistence | M | M0-04…M0-08 | §10.3 measurements recorded in `production/m0_report.md` |
| M0-11 | *(Optional)* Resource-pack spike: download a `.pck` at runtime and load a scene from it | M | F-08 | Works in Chrome and Firefox from the static host |
| M0-12 | Write the pipeline doc `docs/pipeline/backgrounds.md` | S | M0-03 | Someone else could build a room from the doc alone |

---

## 2. Toolchain

Pin exact versions and record them in `README.md`. CI uses the same Godot version.

| Tool | Version policy | Notes |
|---|---|---|
| Godot | **4.7.2-stable** (latest at project start), plus matching export templates | Standard build. GDScript only (ADR-002). |
| Blender | Current LTS | Install the glTF exporter (bundled). Optional: Blender add-on in `tools/blender/` for the export conventions in §8.3. |
| Test runner | In-house, `tests/run_tests.gd` (ADR-008) | GUT couldn't be fetched from this environment, and a 150-line runner has no engine-version coupling |
| gdtoolkit (`gdlint`, `gdformat`) | Pinned in `tools/requirements.txt` | Run in CI and in a pre-commit hook |
| Python 3.11+ | | For localization lint, size report, WebP batch scripts |
| `cwebp` / ImageMagick | Any recent version | Background conversion, LUT application if done offline |
| AI paintover tool | Any. **Record the model, settings and strength per image** in `art-src/<room>/paintover.json`. | Low strength, masked edges (§8.2) |
| Audio editor (Audacity or Reaper) | Any | Tape processing chains saved as presets in `tools/audio/` |
| butler (itch.io) | Latest | Deploy target (Overview Q9) |

---

## 3. Repository Setup (F-01)

**Repo:** `ward-zero`, private. Trunk-based: `main` is always green and deployable. Short-lived feature branches `feat/<id>-<slug>` (e.g. `feat/m1-07-inventory`). Squash-merge through a PR, even when working solo, so CI runs on every change. Tag milestone exits `m0`, `m1`, and so on.

**Commit messages:** `<area>: <imperative summary>`, e.g. `puzzles: add P02 switchboard logic`. Areas: `core`, `rooms`, `puzzles`, `ui`, `loc`, `art`, `audio`, `ci`, `docs`, `tools`.

**Git LFS** tracks: `*.webp *.png *.jpg *.exr *.glb *.gltf *.bin *.fbx *.ogg *.wav *.ttf *.otf *.blend *.psd *.kra`.

**Large source art stays outside the repo.** GitHub LFS free quota is small. Commit only shipping assets (WebP, glb, ogg) and keep `.blend` files, raw renders and paintover layers in `art-src/`, which is git-ignored and backed up separately (cloud drive or a second LFS repo). `art-src/` mirrors `game/rooms/` so paths line up.

**`.gitignore`:** `.godot/`, `export/`, `build/`, `art-src/`, `*.tmp`, OS junk. **Commit the `*.import` files.** Godot 4 needs them for consistent imports.

**README sections:** what the project is, pinned versions, how to run, how to run tests, how to export for web locally, doc links.

Checklist:
- [ ] Repo created, LFS initialized, `.gitattributes` committed
- [ ] `docs/` moved in (Overview, Foundation, M1, GDD)
- [ ] Branch protection on `main`: PR required, CI must pass
- [ ] Pre-commit hook: `gdformat --check`, `gdlint`, localization lint

---

## 4. Godot Project Baseline (F-03)

| Setting | Value | Why |
|---|---|---|
| Renderer | **Compatibility** (WebGL 2) | §9.1 |
| Viewport size | 1920 × 1080 | Matches the background renders |
| Stretch mode / aspect | `canvas_items` / `keep` (letterbox) | **Required:** occluders sample the background by `SCREEN_UV`. Any aspect mismatch breaks the alignment. |
| Physics layers | 1 `floor`, 2 `walls`, 3 `hotspots`, 4 `camera_triggers`, 5 `player`, 6 `stalker`, 7 `hiding` | Name them in project settings so raycasts use names |
| Audio buses | `Master` → `Music`, `Ambience`, `SFX`, `Voice`, `UI` | Separate volume sliders. See the §10.3 note about bus effects on web. |
| Web audio playback type | `Sample` | §9.1. This cuts latency. Check the effect limitations in M0-10. |
| Web export: thread support | **Off** | No SharedArrayBuffer or COOP/COEP needed, so any static host works |
| Web export: VRAM compression | Desktop (S3TC/BPTC) on, ETC2/ASTC off | Desktop only (§9.5) |
| Web export: custom HTML shell | `export/web_shell.html` (M0-09) | Mobile block, WebGL 2 check, loading screen styled to match the game |
| Locales | `en`, `fr_CA`; fallback `en` | §11 |
| Default font | Sans-serif with full French coverage, set in the project theme | Check `é è ê ë à â ç î ï ô û ù ü ÿ œ Œ « »` and NBSP |
| Input map | See below | §3.2 |

**Input actions:** `move_click` (LMB), `cancel` (RMB), `run_modifier` (detected as a double-click in code, not an action), `open_inventory` (I), `open_files` (F), `open_map` (M), `pause` (Esc), `hold_breath` (Space). Use action names everywhere so rebinding (§12) works later without code changes.

---

## 5. Folder Structure and Autoload Stubs (F-04)

```
project.godot
game/
  autoload/          game_state.gd, save_system.gd, room_manager.gd, camera_director.gd,
                     stalker_director.gd, composure_system.gd, memory_shift_system.gd,
                     audio_director.gd, seed.gd, event_bus.gd
  core/              interactable/, actions/, conditions/, player/, puzzle_base/
  data/              items/, documents/, tapes/, puzzles/   (.tres instances)
  schemas/           room_data.gd, puzzle_data.gd, item_data.gd, document_data.gd, tape_data.gd
  rooms/<id>_<name>/ <id>.tscn, room_data.tres, proxy.glb, bg/<cam>.webp, bg_mem/<cam>.webp, audio/
  puzzles/<id>_<name>/ <id>.tscn, <id>.gd, closeup/*.webp
  characters/        mathieu/, man_in_white/
  ui/                inventory/, files/, map/, save_screen/, options/, subtitles/, cursor/, menus/
  shaders/           occluder.gdshader, backdrop.gdshader, post_look.gdshader
  localization/      ui.csv, items.csv, documents.csv, tapes.csv, puzzles.csv
  audio/             music/, sfx/, ambience/, tapes/en/, tapes/fr/
tests/               unit/, integration/
tools/               loc_lint.py, size_report.py, webp_batch.py, blender/, audio/
export/              web_shell.html, export_presets.cfg (committed), build output ignored
production/          time_log.csv, m0_report.md, voices.md
docs/                overview, foundation, milestone plans, adr/, pipeline/
```

**Autoload order and contract (stubs in Foundation, filled in from M1).** Each stub defines its public methods and signals with typed signatures and `push_error("not implemented")` bodies, so call sites can be written early.

| Autoload | Foundation scope | Main API (signals in *italics*) |
|---|---|---|
| `EventBus` | Complete | Global signals for things with no single owner: *noise_emitted(room_id, hops)*, *ui_opened(name)*, *ui_closed(name)* |
| `Seed` | **Complete** + tests | `set_seed(int)`, `derive_int(puzzle_id, field, min, max)`, `derive_choice(puzzle_id, field, array)`. Hash-based, stable across platforms and versions. Never use the global RNG for game content. |
| `GameState` | Stub + flags | `get_flag/set_flag` → *flag_changed*. Inventory, key pouch, fragments, room states, difficulty, composure value, stalker state. `to_dict()/from_dict()`. |
| `SaveSystem` | Stub | `save(slot)`, `load(slot)`, `list_slots()`, `export_string()`, `import_string()` |
| `RoomManager` | Working for M0 (load room, spawn player) | `go_to(room_id, from_exit)` → *room_entered(room_id)*. `set_timeline(present/memory)`. |
| `CameraDirector` | **Working** (M0-04) | `register_room(room)`, `cut_to(cam_id)` → *camera_cut(cam_id)* |
| `AudioDirector` | Stub | `play_ambience(room)`, `play_positional_cue(cue, side)`, music stingers |
| `StalkerDirector`, `ComposureSystem`, `MemoryShiftSystem` | Empty stubs with signals | Filled in during M1 and M2 |

Coding standards: static typing everywhere (`var x: int`, typed arrays). `class_name` on every schema and component. Signals use past-tense names (`solved`, `room_entered`). No `get_node` with absolute paths across scenes; use autoloads or exported NodePaths. Each file holds one responsibility.

---

## 6. Data Schemas v1 (F-05)

The schemas are the ones in §9.2. The **bold** fields are additions this plan needs. Every schema has a `schema_version: int`.

| Resource | Fields |
|---|---|
| `RoomData` | `id`, `name_key`, `cameras: Array[CameraDef]` (id, background, **memory_background**), `exits: Array[ExitDef]` (exit id, target room, target spawn, required key item id, **locked_message_key**), `access: open/scripted/never`, `has_memory_variant`, `hiding_spots: Array[NodePath]`, `map_rect: Rect2`, **`floor: ground/east/west/upper/basement`**, **`ambience_present`, `ambience_memory`**, **`safe_room: bool`** |
| `PuzzleData` | `id`, `room_id`, `params: Dictionary` keyed `easy/normal/hard`, `seed_fields: Array[SeedField]` (name, kind, range or choices), `fail_noise_hops`, `rewards: Array[Action]`, `prerequisite_flags`, **`pauses_on_observer: bool = true`**, **`solved_flag`** |
| `ItemData` | `id`, `name_key`, `desc_key`, `examine_model: PackedScene`, `examine_reveals: Array[ExamineReveal]` (view angle → flag or document), `combines_with: Dictionary[item_id → result_id]`, `storage: slot/key_pouch`, **`kind: normal/key/anchor/fragment/consumable/tool`**, **`droppable: bool`** (no for keys and anchors) |
| `DocumentData` | `id`, `title_key`, `body_key` (template), `fragment_id`, `placeholders: Dictionary[name → seed field or flag]`, **`style: typewriter/handwritten/print/notice`**, **`composure_delta`** |
| `TapeData` | `id`, `audio: Dictionary[locale → AudioStream]`, `subtitles: Dictionary[locale → Array[SubLine]]` (start, end, key), `fragment_id` |

**Actions and conditions** (used by Interactables, puzzle rewards and room scripts) are small `Resource` subclasses edited in the inspector:
- Conditions: `HasItem`, `FlagIs`, `PuzzleSolved`, `TimelineIs`, `Not`, `All`, `Any`
- Actions: `ShowText(key)`, `GiveItem(id)`, `RemoveItem(id)`, `SetFlag(name, value)`, `OpenPuzzle(id)`, `OpenDocument(id)`, `PlayTape(id)`, `GoToRoom(room, spawn)`, `PlaySfx(stream)`, `EmitNoise(hops)`, `StartScript(name)`

The set grows only as content needs it. Don't build a general scripting language.

**Save schema v1:** `{ "version": 1, "seed", "difficulty": {threat, puzzle}, "room", "spawn", "timeline", "flags", "inventory", "key_pouch", "bin", "fragments", "documents_read", "tapes_heard", "puzzles": {id: serialized}, "composure", "stalker", "play_time", "saved_at", "locale" }`. Migrations live in `save_system.gd` as `_migrate_v1_to_v2(dict)` and so on.

---

## 7. Localization Pipeline (F-06)

- **Format:** Godot CSV translation files, one per domain (§5). Columns: `keys,en,fr_CA`. Godot imports them as `.translation` files.
- **Key naming:** `<domain>.<id>.<field>` (Overview §9).
- **Runtime:** UI uses `tr()` or the auto-translated `text` property. Anything that renders a document listens for `NOTIFICATION_TRANSLATION_CHANGED` and re-renders from its key (§11).
- **Placeholders:** `{name}` syntax, filled with `tr(key).format(values)`. Values come from `Seed` or GameState and are never built by concatenation.
- **French typography:** Québec conventions. Use `« »` guillemets with NBSP inside, NBSP before `:`, apostrophe `’`. The writer owns this. The lint only checks that NBSP is there before `: ; ! ?` and inside guillemets, as warnings.
- **`tools/loc_lint.py`** (CI-blocking): every key has both languages filled in; EN and FR have identical placeholder sets (R4); no duplicate keys; every `*_key` referenced from a `.tres` exists. It also flags string literals assigned to `text` in `.tscn`/`.gd` (R3). Allowlist dev-only scenes.

---

## 8. Background Pipeline (M0-01 … M0-03, M0-12)

This makes §9.3 concrete. The steps below are the first draft of `docs/pipeline/backgrounds.md`. Correct them with what M0 actually finds.

### 8.1 Blender Scene (M0-01)
- Units are meters, +Y forward. The scene origin is the room origin in Godot.
- Collections: `ART` (beauty geometry, render only), `PROXY` (exported), `CAMS`, `LIGHTS`.
- Cameras: `cam_<a|b|c|d>`. Lock the sensor fit to **Vertical** so FOV maps cleanly to Godot's default `keep_height`. 16:9 at 1920×1080. Don't use lens shift (or, if you do, check that it survives glTF export).
- Pick the test room from M1 content. **G01 Dayroom is recommended** (2 cams), so M0 work carries straight into M1.

### 8.2 Render and Paintover (M0-02)
- One beauty pass per camera at 1920×1080. Optionally a depth pass (EXR) kept in `art-src/` for the depth-shader alternative.
- **Paintover rules:** low strength (record the value). **Mask a band of about 12 px around every foreground silhouette** that overlaps where the character walks. Never repaint inside the mask. Never add new foreground objects in paintover. Anything new that needs occlusion has to exist in the proxy.
- The LUT stack goes on in Godot at runtime (§8.5), **not** baked in, so backgrounds and the character get identical grading.
- Export: `cwebp -q 82` (tune it to land in 200–400 KB) to `game/rooms/<id>/bg/<cam>.webp`. Import in Godot as lossless or VRAM-uncompressed 2D textures. Never use mipmaps.

### 8.3 Proxy Export (M0-02)
Export the `PROXY` and `CAMS` collections as glTF binary (`proxy.glb`). Naming conventions are read by the post-import script:

| Prefix | Meaning | Becomes |
|---|---|---|
| `floor_` | Walkable floor | StaticBody (layer `floor`) + navmesh source + shadow receiver |
| `occ_` | Foreground occluder (furniture, door frames, pillars) | Mesh with `occluder.gdshader` + shadow receiver |
| `col_` | Wall or obstacle collision only | StaticBody (layer `walls`), not rendered |
| `shadow_` | Shadow catcher only | Mesh with a shadow-only material |
| `cam_` | Camera | Camera3D (with transform and FOV from glTF) |
| `spawn_` | Empty marking a door spawn point | Marker3D |

Hotspots, camera trigger volumes and hiding spots are **authored in Godot**, on top of the imported proxy. They change often and need the editor.

### 8.4 Godot Import and Occlusion (M0-03)
- **`tools/import/proxy_post_import.gd`** (an `EditorScenePostImport` script) applies the prefix table and sets every camera's `keep_aspect = KEEP_HEIGHT`.
- **Backdrop:** a fullscreen quad parented to the active camera, just inside the far plane, drawing the current camera's background. It's unshaded, with no depth write.
- **`occluder.gdshader`:** unshaded, opaque. `ALBEDO = texture(background, SCREEN_UV)`. It writes depth normally, so the 3D character is hidden wherever the occluder is in front of it. It receives the character's shadow with a multiply that's tuned to look like the render's shadows. The `background` uniform is updated on every camera cut.
- **Fallback (only if the proxy approach fails the check):** a depth-image shader using the EXR depth pass. Write down the reason in an ADR.

**Occlusion check procedure** (run for every camera of every room, and record the result in the Room DoD):
1. Turn on the debug overlay (F9): draws occluder outlines in magenta over the backdrop.
2. Any visible offset of more than 2 px between an outline and its painted silhouette fails.
3. Walk the character behind every occluder in the shot. No pop, no halo, no floating feet.
4. Screenshot each camera with the character half-occluded and save it to `production/occlusion/<room>_<cam>.png`.

### 8.5 Post-Process Look (M0-08)
`post_look.gdshader` on a top `CanvasLayer` `ColorRect` over the full viewport (Compatibility has no screen-space post-processing stack): a 3D LUT (32³ strip texture), film grain, slight chromatic aberration, vignette. Every effect has an intensity uniform that will later connect to the accessibility sliders (§12). Every background and the character pass through it. Lock the reference LUT at M0 exit (GDD risk: inconsistent art).

---

## 9. CI/CD (F-08)

GitHub Actions, using a container image pinned to the project's exact Godot version (with export templates).

| Job | Trigger | Steps | Blocking |
|---|---|---|---|
| `lint` | Every PR and push | `gdformat --check`, `gdlint`, `loc_lint.py` | Yes |
| `test` | Every PR and push | `godot --headless res://tests/run_tests.tscn` (`tests/unit`, `tests/integration`) | Yes |
| `export-web` | Every PR and push | Headless web export → `build/web/`. `size_report.py` posts compressed (gzip and brotli) and raw sizes for the `.wasm`, `.pck` and total to the job summary. | Fails if the compressed initial download is > 40 MB |
| `deploy` | Push to `main` | butler push to the itch.io restricted page (channel `web-dev`). Milestone tags push to `web-milestone`. | |

LFS: check out with `lfs: true`. Cache the LFS objects and the `.godot/imported` folder (keyed on the hash of `*.import`) to keep runs short.

---

## 10. M0 Exit

### 10.1 Exit Criteria (from §13.1, made measurable)
- [ ] Test room (G01 recommended) with 2 cameras, built entirely through the §8 pipeline, including the paintover
- [ ] Occlusion check (§8.4) passes on both cameras
- [ ] Click-to-move works across the camera cut: the path continues, controls never flip, no stall at the trigger boundary
- [ ] One hotspot: cursor change → walk to it → examine → localized text, EN and FR switchable at runtime
- [ ] Web build deployed through CI to the static host, and it loads in Chrome, Firefox and Edge
- [ ] **60 fps** (frame time p95 ≤ 16.7 ms over a 60-second walk) in Chrome and Firefox on an **integrated-GPU laptop**
- [ ] Phone user agent gets the block message
- [ ] `docs/pipeline/backgrounds.md` written. LUT locked.

### 10.2 Foundation Exit Criteria
- [ ] F-01 … F-09 done. CI green. ADRs committed.
- [ ] Unit tests: `Seed` determinism (same seed → same values, different fields → independent values), GameState flags and signals, schema `.tres` load
- [ ] Every autoload stub has typed signatures for the API in §5

### 10.3 Measurements to Record (`production/m0_report.md`)
| Measurement | Why it matters |
|---|---|
| Compressed and raw initial download (engine + test room) | Budget R10. If the engine alone takes most of 40 MB, plan a custom export template with unused modules disabled in M2. |
| fps and frame-time p95 per browser, plus the GPU model | R10 |
| **Hours per pipeline step for the test room** (blockout, kitbash, light, render, paintover, proxy, integrate) | First data point for the scope decision. M1 refines it over 6 rooms. |
| **Do audio bus effects work in web Sample mode?** (Test a low-pass on `Ambience`) | If not: bake memory-room muffling and tape effects into the assets, and keep ComposureSystem audio to volume layers |
| Audio latency, click to sound (subjective, Sample vs Stream) | §9.1 |
| Does a file in `user://` survive a hard reload and a browser restart in each browser? | SaveSystem relies on this |
| *(If M0-11 ran)* resource-pack download plus load time for a 20 MB pack | M2 planning |
| Any pipeline step that needed a workaround | Feeds the pipeline doc |

**If occlusion or performance fails:** stop. Write up the cause and try the depth-image fallback (§8.4) before starting M1. M1 assumes this pipeline works.
