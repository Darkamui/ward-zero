# G01 items and documents

The two starting items now use the supplied 3D models: dictaphone and patient wristband. Wrapper scenes in `game/items/` center and scale them for the existing examine camera. Private material overrides correct the kit's color-space mismatch; the source GLBs remain unchanged. Both inventory icons are transparent Godot renders of the corresponding examine models.

The wristband has an institution label on the front and the name/date on its inner face. The date comes from `puzzle:P03.birthdate`, exactly like the existing wristband document. Turning it over triggers the existing one-time document reveal. The readable note uses print typography. No answer is baked into a texture or icon.

Examine controls support mouse drag or arrows to rotate, wheel or +/− to zoom, Home to reset, and Back/right-click/Esc to return. The opaque backing prevents inventory text showing through. Selecting another item closes the previous examine view, and repeatedly clicking Examine does not stack views.

The paper reader reuses `assets/art/ui/paper.png` at its original aspect ratio. Document content remains live localized text from `DocumentRenderer`, including the hard-mode radio clue. Mouse wheel and Page Up/Down scroll; buttons or +/− enlarge text. Clicking the paper no longer dismisses it. Back/right-click/Esc closes it, restoring focus to the examined item when appropriate. The supplied starter templates were not used as gameplay text: they contain different wording and MHz instead of the game's kHz.

## Review

- [Dictaphone](en_item_dictaphone_1080.png)
- [Wristband inner face](en_wristband_inside_1080.png)
- [Quiet Hours in French](fr_CA_quiet_hours_normal_1080.png)
- [Enlarged hard clue, scrolled to its end](fr_CA_quiet_hours_hard_large_end_1080.png)

The capture tool exercises both languages, both G01 items, the wristband reveal, and normal/hard radio notices at ordinary and enlarged text sizes. Run at 1920×1080 and 1280×720; filenames include the output height. It writes no save or settings.

## Validation and reproduction

Four `test_g01_item_ui` integration tests cover live language changes without rerolling clues, normal/hard clue selection, reading/scrolling/enlargement/closing via actual input, keyboard wristband discovery, matching printed and readable dates, one-time discovery after reopening, focus restoration, and mouse item rotation/zoom/reset/back. Nine existing document tests cover localization and seeded clue consistency across many seeds and difficulties. All pass.

```powershell
godot --headless --editor --import --quit
godot --audio-driver Dummy --resolution 1920x1080 res://tools/run_tool.tscn -- res://tools/render_g01_item_icons.gd
godot --headless --editor --import --quit
godot --headless res://tests/run_tests.tscn -- --filter=test_g01_item_ui
godot --headless res://tests/run_tests.tscn -- --filter=test_documents
godot --audio-driver Dummy --resolution 1920x1080 res://tools/run_tool.tscn -- res://tools/smoke/g01_item_screens.gd
godot --audio-driver Dummy --resolution 1280x720 res://tools/run_tool.tscn -- res://tools/smoke/g01_item_screens.gd
```

Validated with Godot 4.7.2 and the OpenGL compatibility renderer. The previously documented engine resource cleanup warnings remain at shutdown. The models are the supplied simple geometry; this pass does not claim a photorealistic character/prop finish. Satchel and Files folder artwork were subsequently integrated in the [shared-UI pass](../shared_ui/README.md).
