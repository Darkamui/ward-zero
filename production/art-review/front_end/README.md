# Front end art pass

The existing title menu and options panel were modified in place. The new Act I card sits between the existing difficulty selection and `game.tscn`; loaded/imported saves continue straight into gameplay. All text is rendered by Godot and localized in English and Québec French.

## Artwork

- `assets/art/menus/title_corridor.png`: generated institutional corridor, used by the title, difficulty selection and options.
- `assets/art/menus/act1_dictaphone.png`: generated dictaphone and wristband still life, used by the chapter card.
- Built-in `image_gen` was used for both images. Exact production prompts and reused assets are in [generation.json](generation.json). No text is baked into either image. The chapter still life is atmospheric artwork, not a replacement for the Dayroom render or gameplay props.
- Existing IBM Plex Sans, Courier Prime, UI click and Dayroom ambience are reused. Sources retain the credits in `production/credits.md`.

## Behavior

Options are grouped into Audio, Display & comfort, and Language & subtitles. Six audio buses have sliders with percentages; subtitle size/background have a live preview. Changes apply and save immediately using the existing Settings autoload. Keyboard focus survives rebuilds and Escape closes options before the underlying pause menu. Display exposes the existing fullscreen, skip-door and gentle-memory-transition settings.

Act I is player-paced. Enter/click continues; Escape skips. A short fade leads to the existing Dayroom, where the existing first-entry trigger plays Claire's tape. Difficulty, seed, inventory and autosave behavior remain in NewGame.

## Review and validation

Local previews: [Main menu](en_main_1080.png), [Options](en_options_audio_1080.png), [Act I](en_intro_1080.png), [French subtitles settings](fr_CA_options_accessibility_1080.png).

`tools/smoke/front_end_screens.gd` captures both languages through the actual Godot controls at 1920×1080 and 1280×720. Output PNGs are local review artifacts and intentionally ignored by Git. Run using `tools/run_tool.tscn` with a graphical renderer.

`tests/integration/test_front_end_ui.gd` covers keyboard volume persistence, French/subtitle focus, nested options sizing, pause/Escape routing and title return. `tools/smoke/front_end_flow.gd` exercises New Game → Act I → Dayroom with isolated save slots and checks that the opening tape, seed, difficulty and items survive.

Validation used the installed Godot 4.7.1 standard build; this workspace documents 4.7.2 as its pin. Script compile and the four front-end integration tests pass, as does the scene-flow smoke check. Godot reports resource leaks on shutdown, also seen in the pre-existing compile check. Localization lint reports two existing wristband text-literal errors and three existing French typography warnings; no new localization errors were introduced.
