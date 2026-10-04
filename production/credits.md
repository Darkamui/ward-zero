# Asset sources

## Front end screens — 2026-10-03

`assets/art/menus/title_corridor.png` and `assets/art/menus/act1_dictaphone.png` are original generated background plates produced with the built-in `image_gen` tool. Exact prompts are retained in `production/art-review/front_end/generation.json`. They contain no interface text; labels and controls are localized Godot elements. These are generated assets, not CC0 library photographs. Menu ambience and clicks reuse the previously credited G01 audio, and typography uses the existing bundled fonts.

## G01 first camera art study — 2026-10-03

| Asset | Author / source | Licence | Usage |
|---|---|---|---|
| [Peeling Painted Wall](https://polyhaven.com/a/peeling_painted_wall) | Dimitrios Savva / Poly Haven | [CC0-1.0](https://polyhaven.com/license) | 2K diffuse, displacement and roughness maps. Recoloured in Blender shaders for cream plaster and sage paint. Source images are unchanged. |
| [Painted Wooden Chair 01](https://polyhaven.com/a/painted_wooden_chair_01) | Kuutti Siitonen / Poly Haven | [CC0-1.0](https://polyhaven.com/license) | Ready-made 724-triangle model with 2K textures. Uniformly fitted within the existing chair footprint; original geometry and surface maps retained. Included in both backgrounds and the material-free runtime occluder. |
| Furniture and small props in `assets/models/` | User-supplied Ward Zero procedural prop kit; see `assets/source/build_models.py` | Existing project assets; no new third-party licence asserted | Two side tables, effects bin, radio and dictaphone. Materials replaced for the room render. The starter chair was replaced by the downloaded model above. |
| Dayroom shell, couch, door detailing, lamp, radiator, pipes, surface shaders and dressing | Authored for Ward Zero in `tools/blender/build_dayroom.py` | Project source | Built around the existing G01 layout. |

Poly Haven's licence page was checked on 2026-10-03. No attribution is required under CC0; the source is recorded here for provenance.

Download URLs and SHA-256 hashes are recorded in `production/art-review/g01_dayroom/material-sources.json` and `prop-sources.json`. Source maps and the packed Blender scene live in ignored `art-src/`; the fetch and build scripts reproduce them. This art pass uses no AI paintover. The existing concept image is used as visual direction only.

## P01 radio close-up — 2026-10-03

Reused the user-supplied `assets/art/puzzle-bases/radio-housing.png`, `assets/puzzles/radio-knob.svg` and `assets/puzzles/radio-needle.svg` unchanged. These are existing project assets; no new third-party licence is asserted. The housing is supplied generated artwork and the controls are project SVGs. No additional media was generated or downloaded for this pass. Scale marks, localized labels, frequency readout, focus indicators and signal strength are drawn by Godot at runtime.

## G01 door-chain states — 2026-10-03

Extended the existing Blender chain geometry into locked and released states, with frame anchors and a padlock, in `tools/blender/build_dayroom.py`. This small, layout-specific assembly reuses the room's steel/brass materials. No additional downloaded or generated media was required. Both states use the same room assets and CC0 sources listed above.

## G01 items and reader — 2026-10-03

Reused `assets/models/dictaphone.glb` and `assets/models/patient_wristband.glb` from the supplied procedural kit. The original files remain unchanged. Godot wrapper scenes center/scale the models and correct the kit's sRGB palette exported as linear glTF factors, using private material copies. Wristband printing is runtime text, with the birth date resolved from P03. Transparent inventory icons are Godot renders of these same models, reproducible with `tools/render_g01_item_icons.gd`.

The reader uses supplied generated blank artwork at `assets/art/ui/paper.png`, preserving its aspect ratio. All document text remains in the existing localization/seed-binding system; the starter SVG/JSON document wording was not substituted. Fonts remain the project's bundled fonts. No new third-party assets or AI media were obtained for this pass.

## Shared satchel and Files UI — 2026-10-03

Reused supplied generated artwork `assets/art/ui/satchel.png` and `assets/art/ui/folder.png` unchanged, preserving aspect ratio. Slot backgrounds use the four supplied `assets/controls/slot-*.svg` states as sliced Godot styles. Buttons and lists reuse the supplied ivory/ink SVG icons in `assets/icons/`, with localized text labels retained. These are existing project assets; no new third-party licence is asserted. No media was generated or downloaded for this pass.

## G01 and shared audio — 2026-10-03

| Source | Author | Licence | Selected use |
|---|---|---|---|
| [Interface Sounds](https://kenney.nl/assets/interface-sounds) | Kenney | CC0 | `click_001.ogg`, shared button activation |
| [RPG Audio](https://kenney.nl/assets/rpg-audio) | Kenney | CC0 | `handleSmallLeather.ogg`, `bookOpen.ogg`, `doorClose_1.ogg`: satchel, Files folder and room-transition door |
| [Sound Effects Pack](https://opengameart.org/content/sound-effects-pack) | OwlishMedia / owlstorm | CC0 | `pageturn1.wav` and `hard-footstep1.wav` through `hard-footstep4.wav` |
| [The Shop, free samples](https://opengameart.org/content/the-shop) | LEGIT Audio | CC0 for the OpenGameArt free files | `TheShopCollection_convenience_store_drinks_fridge_drone.wav`, adapted as subdued dayroom electrical room tone |
| [80 CC0 RPG SFX](https://opengameart.org/node/86018) | rubberduck | CC0 | `chain_01.ogg`, chain release |

The source pages and Kenney's bundled licence files were checked on 2026-10-03. Selected recordings are converted to mono, resampled to 48 kHz where needed, trimmed with small fades and normalized with headroom. Room tone has a one-second wrap crossfade and is encoded as Ogg Vorbis. `tools/prepare_g01_audio.py` records the exact selected filenames and processing; download URLs/archive SHA-256 hashes are in `production/art-review/g01_audio/sources.json`. Only selected prepared clips ship under `game/audio/g01/`; full source packs remain in ignored `art-src/audio/`.

Radio static, tuning detent and cassette transport reuse the supplied synthesized starter effects in `assets/audio/`, created by `assets/source/build_audio.py`. No new audio was synthesized or AI-generated. These three starter effects and the overall mix remain subject to listening review. Voice recordings and music are not supplied by this pass.

## G01 voice and safe-room music candidates — 2026-10-03

- **Safe Space (loop)** by **Tsorthan Grove / TsorthanGrove**, [OpenGameArt source](https://opengameart.org/content/safe-space-0), **CC0-1.0**. The composer supplies the 148.314-second stereo loop specifically as a late-1990s survival-horror safe-room theme. Full loop retained, gain lowered and converted from FLAC to Ogg Vorbis; no AI music generation. Exact download and source hash: `art-review/g01_voice_music/music-source.json`.
- **Claire and P01 radio, English and French:** original fictional voice candidates generated through the **fal** plugin, endpoint `google/gemini-3.8-flash-tts`, prebuilt voices **Leda** and **Sulafat**. No real-person recording, voice cloning or imitation reference supplied. Five original WAVs, exact prompts, request IDs and output URLs are retained under `art-review/g01_voice_music/`; `generation.json` is the generation record. These are AI service outputs, not CC0 library recordings. Performance, character age, continuity and Québec accent remain subject to listening review.
- Voice post-processing is project code in `tools/prepare_g01_voice_music.py`: mono 48 kHz, modest filtering/saturation, low-level deterministic hiss, padding and fades. No pitch shifting or time compression. Cassette and chain effects retain the preceding pass's source credits. Runtime outputs total approximately 1.54 MB including the music.

Source pages checked on 2026-10-03: OpenGameArt explicitly lists CC0 for the music; [fal's endpoint page](https://fal.ai/models/google/gemini-3.8-flash-tts) labels the voice model for commercial use. Published generation pricing was $0.045 per 1,000 characters; this is a rate record, not an account invoice.
