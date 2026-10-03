extends TestCase
## Validate the artwork layouts through the real inventory/files input flows.

var _tree: SceneTree
var _inventory: InventoryUi
var _files: FilesUi
var _reader: DocumentViewer
var _locale: String


func before_each() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	_locale = TranslationServer.get_locale()
	_inventory = InventoryUi.new()
	_files = FilesUi.new()
	_reader = DocumentViewer.new()
	_tree.root.add_child(_inventory)
	_tree.root.add_child(_files)
	_tree.root.add_child(_reader)
	Seed.set_seed(12345)


func after_each() -> void:
	_reader.close()
	_inventory.close()
	_files.close()
	_reader.queue_free()
	_inventory.queue_free()
	_files.queue_free()
	TranslationServer.set_locale(_locale)


func test_satchel_six_and_eight_slots_fit_and_keep_keyboard_focus() -> void:
	TranslationServer.set_locale("fr_CA")
	GameState.give_item("item_music_box_crank")
	_inventory.open()
	await _settle()
	assert_eq(_inventory._slots.get_child_count(), 6)
	var artwork := _inventory._root.get_child(1) as TextureRect
	assert_eq(artwork.size, Vector2(930, 620), "satchel respects its display size")
	var first := _inventory._slots.get_child(0) as Button
	first.grab_focus()
	_key(KEY_ENTER)
	await _settle()
	assert_eq(_inventory.selected, "item_music_box_crank")
	assert_true(_inventory._slots.get_child(0).has_focus(), "selection keeps keyboard navigation alive")
	GameState.set_slot_count(8)
	for i in 7:
		GameState.give_item("item_sedatives")
	await _settle()
	assert_eq(_inventory._slots.get_child_count(), 8)
	for button in _inventory._slots.get_children():
		assert_true(Rect2(200, 280, 600, 390).encloses(button.get_global_rect()), "slot stays on the lining")
	assert_true(_inventory._capacity.text.contains("8 / 8"))
	assert_true(_inventory._name.text.contains("Manivelle"))
	TranslationServer.set_locale("en")
	await _settle()
	assert_true(_inventory._name.text.contains("Crank"))
	assert_eq(_inventory.selected, "item_music_box_crank")


func test_bin_buttons_transfer_and_regular_reopen_is_safe() -> void:
	GameState.give_item("item_music_box_crank")
	_inventory.open(true)
	_inventory._select("item_music_box_crank")
	await _settle()
	var store_button: Button
	for button in _inventory._actions.get_children():
		if button.text == "ui.bin.store":
			store_button = button
	assert_true(store_button != null)
	_click(store_button.get_global_rect().get_center())
	await _settle()
	assert_false(GameState.has_item("item_music_box_crank"))
	assert_eq(GameState.bin, ["item_music_box_crank"])
	_click(_inventory._take.get_global_rect().get_center())
	await _settle()
	assert_true(GameState.has_item("item_music_box_crank"))
	assert_true(GameState.bin.is_empty())
	_inventory.close()
	await _settle()
	_inventory.open()
	_inventory._select("item_music_box_crank")
	await _settle()
	assert_true(_inventory._bin == null, "closed storage list cannot leak into regular inventory")
	assert_true(_inventory.is_open())


func test_full_satchel_does_not_lose_bin_item() -> void:
	for i in 6:
		GameState.give_item("item_sedatives")
	GameState.bin.append("item_fuse")
	_inventory.open(true)
	await _settle()
	var messages: Array[String] = []
	var on_text := func(key: String) -> void: messages.append(key)
	EventBus.text_requested.connect(on_text)
	_click(_inventory._take.get_global_rect().get_center())
	EventBus.text_requested.disconnect(on_text)
	assert_eq(GameState.bin, ["item_fuse"])
	assert_eq(GameState.free_slots(), 0)
	assert_eq(messages, ["ui.inventory.full"])


func test_files_preview_then_keyboard_read_and_locale_switch() -> void:
	TranslationServer.set_locale("en")
	GameState.add_document("doc_quiet_hours")
	GameState.add_document("doc_wristband_note")
	_files.open()
	await _settle()
	_click(_files._list.global_position + _files._list.get_item_rect(1).get_center())
	assert_false(_reader.is_open(), "single click selects a preview")
	assert_eq(_files._selected_id, "doc_wristband_note")
	var date := str(PuzzleValues.value(&"P03", &"birthdate"))
	assert_true(_files._preview_body.text.contains(date))
	assert_false(GameState.documents_read.has("doc_wristband_note"))
	TranslationServer.set_locale("fr_CA")
	await _settle()
	assert_eq(_files._selected_id, "doc_wristband_note")
	assert_true(_files._preview_body.text.contains("Date de naissance"))
	assert_true(_files._preview_body.text.contains(date))
	_files._list.grab_focus()
	_key(KEY_ENTER)
	await _settle()
	assert_true(_reader.is_open())
	assert_eq(_reader.doc.id, &"doc_wristband_note")
	assert_true(GameState.documents_read.has("doc_wristband_note"))
	_reader.close()
	await _settle()
	assert_true(_files._list.has_focus())
	assert_false(_files._list.get_item_text(1).begins_with("\u2022"), "opened note loses unread marker")


func test_files_tabs_and_tape_play_once() -> void:
	GameState.add_tape("tape_01_claire")
	GameState.add_document("doc_f01_admission_file")
	_files.open()
	await _settle()
	_click(_files._tabs[1].get_global_rect().get_center())
	await _settle()
	assert_eq(_files.tab, FilesUi.Tab.TAPES)
	var played: Array[StringName] = []
	var on_tape := func(id: StringName) -> void: played.append(id)
	EventBus.tape_requested.connect(on_tape)
	_files._list.grab_focus()
	_key(KEY_ENTER)
	EventBus.tape_requested.disconnect(on_tape)
	assert_eq(played, [&"tape_01_claire"], "one activation requests one playback")
	_click(_files._tabs[2].get_global_rect().get_center())
	assert_eq(_files.entries(), ["doc_f01_admission_file"])
	assert_true(_files._list.get_item_text(0).contains("F01"))


func test_empty_files_and_right_click_never_open_document() -> void:
	_files.open()
	await _settle()
	assert_true(_files._empty.visible)
	assert_false(_files._open_entry.visible)
	GameState.add_document("doc_quiet_hours")
	_files._refresh()
	await _settle()
	_click(_files._list.global_position + Vector2(80, 20), MOUSE_BUTTON_RIGHT)
	assert_false(_reader.is_open())
	assert_false(_files.is_open())


func _settle() -> void:
	for i in 4:
		await _tree.process_frame


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		_tree.root.push_input(event, true)


func _click(at: Vector2, button := MOUSE_BUTTON_LEFT) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.button_index = button
		event.pressed = pressed
		_tree.root.push_input(event, true)
