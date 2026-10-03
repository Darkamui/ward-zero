# P01 radio close-up

Integrated the supplied blank radio housing with separate needle and rotating knob SVGs. The plate and controls share the image's 1536 × 1024 coordinate space, positioned within the game's 1920 × 1080 canvas. The second knob is centered on the actual socket at (1315, 638), correcting the starter anchor file's (1276, 639).

The left knob tunes at 4 kHz per horizontal pixel; the right provides 1 kHz fine adjustment. The scale supports direct pointing and dragging. All three controls update the same existing P01 logic and persist changes immediately. Keyboard arrows adjust 1 kHz, Page Up/Down adjust 10, Home/End reach the endpoints, and Tab moves focus. Releasing a tuning key, mouse button or mouse-wheel step checks the station; Enter or Space also confirms the current setting. Solving locks the controls and uses the existing rewards and automatic close behavior.

Numbers, labels, meter, needle position and the easy-mode target marker are runtime elements. Normal and hard modes do not display the answer. The original seeded frequency, tolerance and document-clue logic are unchanged. Static and radio voice sourcing/integration remain queued with audio.

## Review captures

- [English, normal, 1080p](en_normal_1080.png)
- [French, easy, 1080p](fr_CA_easy_1080.png)
- [English, normal, 720p](en_normal_720.png)
- [French, normal, 720p](fr_CA_normal_720.png)

All eight combinations of EN/fr_CA, normal/easy and 1080p/720p are included. The smoke scene uses the actual PuzzleHost without writing saves or settings.

## Validation

Godot 4.7.2. Six `test_radio_ui` integration tests exercise actual viewport GUI input: keyboard persistence/reopen/bounds, both knobs and synchronized values, pointer solve-on-release with exactly one reward, seeded easy marker, Tab navigation and keyboard solve, and dragging/releasing outside the scale. All pass.

The four Act 1 critical-path tests and fifteen puzzle-logic tests also pass: 25 tests total, zero failures. Formatting, lint and `git diff --check` pass for the changes.

GPU captures use the OpenGL compatibility renderer. Labels, French accents, scale, needle and controls were visually reviewed at both resolutions. The engine still reports the previously documented resource leaks during shutdown, after tests and captures complete successfully.

Reproduce from the project root (substitute the installed Godot executable):

```powershell
godot --headless --editor --import --quit
godot --headless res://tests/run_tests.tscn -- --filter=test_radio_ui
godot --headless res://tests/run_tests.tscn -- --filter=test_act1_critical_path
godot --headless res://tests/run_tests.tscn -- --filter=test_puzzles_logic
godot --audio-driver Dummy --resolution 1920x1080 res://tools/run_tool.tscn -- res://tools/smoke/p01_art_screens.gd
godot --audio-driver Dummy --resolution 1280x720 res://tools/run_tool.tscn -- res://tools/smoke/p01_art_screens.gd
```
