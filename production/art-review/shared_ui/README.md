# Shared satchel and Files UI

Reuses the supplied satchel, folder, slot-state SVGs and interface icons. All labels and document previews remain live localized text. Art keeps its original aspect ratio; artwork sizing disables texture minimum size before assigning the texture.

The satchel supports six slots and the eight-slot upgrade, a separate key pouch, item previews and the existing examine/use/combine/drop actions. Actions wrap for longer French labels. The effects bin has an explicit Take button as well as double-click/Enter activation. Keyboard focus survives inventory refreshes, and closing the bin clears its transient controls before ordinary inventory reopens.

Files shows a scrollable index on the left and the selected document or tape on the right. A single click selects a preview; Read/Play, Enter or double-click activates it. Previewing does not mark a document read. Full documents open in the paper reader with its scrolling/enlargement controls; closing restores focus to Files. Tabs retain documents, tapes and truth fragments, and document entries retain unread markers and fragment IDs. Right-click closes without activating an entry.

## Review captures

- [Starting satchel](en_starting_satchel_1080.png)
- [French six-slot effects bin](fr_CA_six_slots_bin_1080.png)
- [French eight-slot satchel at 720p](fr_CA_eight_slots_720.png)
- [Stored item ready to retrieve](en_stored_item_1080.png)
- [French document index at 720p](fr_CA_files_documents_720.png)
- [Truth fragments](fr_CA_files_fragments_1080.png)
- [Tape tab](en_files_tapes_1080.png)
- [Full reader over Files](fr_CA_files_reader_720.png)

The capture script produces 40 images across English/French and 1080p/720p: starting inventory, six filled slots, bin transfer, eight filled slots, examine, empty Files, document index, full reader, tapes and fragments. It populates all 41 documents to exercise scrolling and repeats some slot items to fill eight slots. It writes no saves or settings.

## Validation and reproduction

Six `test_shared_asset_ui` integration tests pass: actual texture bounds, six/eight-slot bounds, keyboard focus, bin transfer/reopen, full-inventory rejection without item loss, preview versus reading, language changes with seeded values, reader focus restoration, one tape request per activation, fragment tabs, empty state and right-click dismissal. The four existing `test_g01_item_ui` tests also pass. Formatting and lint pass for the five scripts in this group.

```powershell
godot --headless --editor --import --quit
godot --headless res://tests/run_tests.tscn -- --filter=test_shared_asset_ui
godot --headless res://tests/run_tests.tscn -- --filter=test_g01_item_ui
godot --audio-driver Dummy --resolution 1920x1080 res://tools/run_tool.tscn -- res://tools/smoke/shared_ui_screens.gd
godot --audio-driver Dummy --resolution 1280x720 res://tools/run_tool.tscn -- res://tools/smoke/shared_ui_screens.gd
```

Validated with Godot 4.7.2 and OpenGL compatibility rendering. The previously documented resource cleanup warnings remain at engine shutdown; no input/runtime errors occurred during these checks. Items outside G01 still use their existing art or text fallback. Map, title, endings and other puzzle presentation remain outside this focused pass. Characters are the next asset group.
