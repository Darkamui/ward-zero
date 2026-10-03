# Asset List and Sourcing

Every asset the greybox build still needs, with the recommended source for each. Counts come from the current build: 33 rooms, 70 present-day backgrounds, 15 memory backgrounds, 22 close-ups, 30 items, 41 documents, 6 tapes.

**How to read the Source column.** "Free" means a free library. "AI" means generated. "Make" means it's quicker or better to make it yourself. Check the licence of every downloaded file and log it in `production/credits.md`. Avoid NC (non-commercial) and ND (no-derivatives) licences.

## Licence rules

| Rule | Why |
|---|---|
| Prefer CC0 (Poly Haven, ambientCG, Kenney, Quaternius, Sonniss). | No attribution to track. |
| CC-BY is fine. Credit it in the game's credits. | Freesound, Sketchfab, incompetech, game-icons.net |
| For AI images, use models whose licence allows commercial use: **SDXL** (Open RAIL++-M) or **FLUX.1 [schnell]** (Apache 2.0). Avoid FLUX.1 [dev] unless you've checked its terms. | Licence terms for model outputs differ. |
| For AI tools sold as a service (Meshy, Tripo, ElevenLabs, Suno, Udio), you need a **paid tier** for commercial rights. | Free tiers are usually personal use only, or require attribution. |
| Steam requires an AI-content disclosure. itch.io asks you to tag AI-generated assets. | Store rules. |
| AI music is still under legal dispute. Use it for placeholders, or replace it before release if in doubt. | Risk |

---

## 1. Pre-rendered backgrounds (the biggest job)

85 images in all: 70 present-day plus 15 memory variants. They follow the pipeline in `docs/pipeline/backgrounds.md`: Blender scene → beauty render → light AI paintover → WebP.

| Asset | Qty | Source | Notes |
|---|---|---|---|
| Generic furniture (beds, chairs, desks, cabinets, shelves, lockers, tables) | ~60 models | **Free:** Poly Haven (CC0), BlenderKit (free tier, royalty-free), Sketchfab (CC0/CC-BY filter) | Tip: the paintover hides mismatched styles. |
| Period hospital props (gurneys, hydrotherapy tubs, morgue drawers, treatment chair, switchboard, 1970s radio, slide projector, boiler and pipes, card catalog, hymn board, dumbwaiter) | ~30 models | **AI:** Meshy or Tripo (paid tier), or Hunyuan3D-2 run locally (check its regional licence terms). **Free** fallback: Sketchfab. | AI topology problems don't matter because the props are only rendered, never shown live. |
| Hero puzzle props (grandfather clock, wall safe, balance scale, music box, rocking horse, chalkboard, Director's desk) | ~12 models | AI 3D, then **Make** the moving parts by hand in Blender | The interactive parts must be separate objects so close-ups can animate them. |
| Materials (peeling paint, terrazzo, tile, linoleum, wood floor, rusted metal, concrete) | ~25 | **Free:** ambientCG (CC0), Poly Haven (CC0) | |
| Grime and water-stain decals | ~20 | **Free:** ambientCG decals (CC0) | |
| Paintover | 85 images | **AI:** ComfyUI with SDXL img2img plus a ControlNet depth model | Use low denoise and keep the occluder edge mask (pipeline §4). Present day: decay. 1976: warm, clean, lived-in. |
| Lighting environments | 3–4 | **Free:** Poly Haven HDRIs (CC0) | Overcast, night, warm interior |

## 2. Puzzle close-ups

| Asset | Qty | Source | Notes |
|---|---|---|---|
| Close-up background plates | 22 | Blender render of the hero prop + AI paintover (as for backgrounds) | |
| Interactive pieces (dials, wheels, cables, pills, drawings, slides, books, keys, weights, clock hands, drawers) | ~150 sprites | **Make:** render from the same Blender models | Rendered from the same models, they always line up with the plate. |

## 3. Characters (3D, live in the scene)

| Asset | Qty | Source | Notes |
|---|---|---|---|
| Mathieu (adult patient: pyjamas, coat over the top) | 1 rigged | **Free:** MakeHuman (CC0 export) + clothing in Blender, auto-rigged on Mixamo | |
| The Man in White (orderly in a white uniform, featureless face) | 1 rigged | MakeHuman/Mixamo base + **Make** the uniform and mask | Can be simpler; he is often half-seen. |
| Animations: idle, walk, run, interact, crouch-hide, caught, stalker search and grab | ~14 | **Free:** Mixamo (royalty-free in games) | Retarget in Blender, export as glTF. |
| Claire (6), young Mathieu (9), the Director | stills only | **AI** images | Used only in memory text, the photograph and endings |

## 4. Items and documents

| Asset | Qty | Source | Notes |
|---|---|---|---|
| Item models for the 3D examine view | 30 | **AI:** Meshy or Tripo. **Free:** Sketchfab | Keys ×6, cassette, dictaphone, fuse, valve wheel, crank, cylinder, ribbon, satchel, wristband, sedatives… |
| Inventory icons | 30 | **Make:** render from the item models | Consistent lighting comes for free. |
| The Photograph (Claire and Mathieu, 1976) | 1 | **AI** (fictional people) + film-grain pass | |
| Crayon drawings (F04, Drawing anchor, P09 set of 6) | 8 | **Make:** draw with real crayons and scan. Or AI. | Real crayon reads far better. |
| Newspaper clipping, admission file, registry, prescription, lecture slide | ~10 layouts | **Make:** Inkscape or Affinity, with the bundled fonts | The seeded values are filled in at runtime, so these are templates. |
| Paper and folder textures | ~6 | **Free:** ambientCG (CC0) | |

## 5. UI and presentation

| Asset | Qty | Source |
|---|---|---|
| Cursors (eye, hand, arrow, lock) | 4 | **Make**, or **Free:** Kenney cursor pack (CC0) |
| Title key art and logo | 1 + 1 | **AI** key art + **Make** the logotype |
| Map paper texture | 1 | **Free:** ambientCG |
| Ending stills (Relapse, Discharge, Claire; 4–6 each, slow pans) | ~15 | **AI** + paintover. Cheaper than video. |
| Menu sounds | ~8 | **Free:** Kenney UI audio (CC0) |

## 6. Audio

| Asset | Qty | Source | Notes |
|---|---|---|---|
| Room ambience loops (ground floor, wards, upper floor, basement, boiler, Ward Zero) plus warm "1976" variants | ~12 | **Free:** Sonniss GDC bundles (royalty-free, no attribution), Freesound (CC0/CC-BY) | Layer and loop in Audacity or Reaper. |
| Random one-shots (pipes, far doors, creaks, drips) | ~30 | Sonniss, Freesound | |
| Stalker footsteps (hard soles on tile, wood, concrete), doors | ~20 | Sonniss | He makes no vocal sounds. |
| Player footsteps per surface | ~12 | Sonniss, Freesound | |
| Composure: heartbeat, tinnitus, phantom sounds | ~8 | Freesound + **Make** (a sine tone for tinnitus) | |
| Puzzle SFX (radio static and tuning, switchboard plugs and ring, safe clicks, drawers, chalk, water pour, boiler whistle, scale clink, projector whirr, clock tick and chime, morgue drawer, key turns) | ~40 | Sonniss, Freesound. **AI** for gaps: ElevenLabs sound effects (paid) | |
| Music box notes C D E G A + crank | 6 | Freesound, or **Make** (sample a real music box) | P11's melody is seeded, so it's played note by note at runtime. |
| Hummed notes C D E G A for the P11 tape | 5 | **Make:** record a voice humming each note | The tape assembles the seeded melody from these. |
| Knocks for P12 (5 doors) | 5 | Sonniss, Freesound | |
| Music: safe-room theme, chase cue, memory-shift stinger, title, 3 ending themes, credits | ~8 | **AI:** Suno, Udio or ElevenLabs Music (paid; placeholder) → replace with **commissioned** music or incompetech (CC-BY) | The safe-room theme matters most; worth paying for. |

## 7. Voice (tapes)

6 tapes, 17 subtitle lines in total, each in EN and fr_CA, plus the opening "Mathieu… viens me chercher."

| Voice | Source | Notes |
|---|---|---|
| Dr. Hélène Bouchard (warm, 40s, Québécoise) | **AI:** Azure Neural TTS `fr-CA-SylvieNeural` for FR. ElevenLabs for EN. | The GDD plans TTS + tape processing. |
| Adult Mathieu (31) | Azure `fr-CA-AntoineNeural` / `fr-CA-JeanNeural` for FR. ElevenLabs for EN. | Same voice in both languages helps. |
| The Director (older man, 1976) | Azure `fr-CA-ThierryNeural` / ElevenLabs | |
| Claire (girl, 6) | **AI:** ElevenLabs Voice Design | Hardest voice to get right; keep her lines short. |
| Radio voice (P01) | Any TTS + radio EQ | |
| Tape processing (hiss, wobble, band-pass) | **Make:** an Audacity chain or a Godot bus effect | Hides the artificial quality of TTS. |

## 8. Needs a person (not an asset store)

Québec French review of all strings, real-GPU performance checks, playtests, and the final mix.

## Suggested order

1. Furniture, materials, and the paintover recipe for **one room** (G01). Lock the look before scaling up.
2. Mathieu, the Man in White and their Mixamo animations.
3. Act 1 rooms and close-ups → itch.io build.
4. Audio (ambience, stalker, puzzle SFX), so the slice plays as horror.
5. Remaining acts, voices, music, endings.

Keep the web budget in mind: 40 MB compressed. WebP backgrounds at q≈80 average about 150–250 KB each, so 85 backgrounds come to about 17 MB. Use Ogg Vorbis for audio, and mono for SFX.
