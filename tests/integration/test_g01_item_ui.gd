extends TestCase
## Exercise reader input and the supplied wristband's one-time, seeded inside-face reveal.

var _tree: SceneTree
var _reader: DocumentViewer
var _inventory: InventoryUi
var _locale: String


func before_each() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	Seed.set_seed(12345)
	_reader = DocumentViewer.new()
	_inventory = InventoryUi.new()
	_tree.root.add_child(_inventory)
	_tree.root.add_child(_reader)
	GameState.give_item("item_dictaphone")
	GameState.give_item("item_wristband")


func after_each() -> void:
	_reader.close()
	_inventory.close()
	_reader.queue_free()
	_inventory.queue_free()
	TranslationServer.set_locale(_locale)


func test_seeded_clue_live_locale_and_hard_variant() -> void:
	_reader.open(&"doc_quiet_hours")
	var frequency := "%d kHz" % PuzzleValues.value(&"P01", &"frequency")
	assert_true(_reader.shown_text().contains(frequency))
	var english := _reader.shown_text()
	TranslationServer.set_locale("fr_CA")
	await _tree.process_frame
	assert_ne(_reader.shown_text(), english)
	assert_true(
		_reader.shown_text().replace("\u00a0", " ").contains(frequency),
		"translation does not reroll the station"
	)
	GameState.set_difficulty("patient", "hard")
	_reader.open(&"doc_quiet_hours")
	assert_false(_reader.shown_text().contains(frequency), "hard mode retains its indirect clue")
	assert_true(_reader.shown_text().contains(str(PuzzleValues.value(&"P01", &"riddle_a"))))
	assert_true(GameState.documents_read.has("doc_quiet_hours"))


func test_reader_wheel_click_and_keyboard_enlargement() -> void:
	_reader.open(&"doc_quiet_hours")
	await _settle()
	var at := Vector2(900, 450)
	_mouse(at, MOUSE_BUTTON_LEFT, true)
	_mouse(at, MOUSE_BUTTON_LEFT, false)
	assert_true(_reader.is_open(), "clicking paper does not dismiss it")
	for i in 4:
		_key(KEY_PLUS)
	await _settle()
	assert_eq(_reader._body.get_theme_font_size("font_size"), 44)
	assert_true(_reader._scroll.get_v_scroll_bar().max_value > _reader._scroll.size.y)
	_mouse(at, MOUSE_BUTTON_WHEEL_DOWN, true)
	await _settle()
	assert_true(_reader.is_open(), "scrolling does not dismiss it")
	assert_true(_reader._scroll.scroll_vertical > 0, "wheel reaches overflow text")
	_key(KEY_PAGEDOWN)
	assert_true(_reader._scroll.scroll_vertical > 100, "keyboard pages through the text")
	_key(KEY_MINUS)
	assert_eq(_reader._body.get_theme_font_size("font_size"), 40)
	_mouse(at, MOUSE_BUTTON_RIGHT, true)
	assert_false(_reader.is_open())


func test_wristband_keyboard_reveal_matches_physical_print_and_fires_once() -> void:
	_inventory.open()
	_inventory._select("item_wristband")
	_inventory._on_examine()
	await _settle()
	var view := _inventory._examine
	var printed := view._pivot.get_child(0).get_node("InsidePrint") as Label3D
	var date := str(PuzzleValues.value(&"P03", &"birthdate"))
	assert_true(printed.text.contains(date))
	assert_false(_reader.is_open(), "front face does not reveal the hidden date")
	for i in 22:
		if _reader.is_open():
			break
		_key(KEY_RIGHT)
	assert_true(_reader.is_open(), "keyboard turning discovers the inside")
	assert_true(_reader.shown_text().contains(date))
	assert_true(GameState.documents.has("doc_wristband_note"))
	_reader.close()
	await _settle()
	assert_true(view.has_focus(), "reader returns focus to the examined item")
	_inventory._close_examine()
	_inventory._on_examine()
	await _settle()
	_inventory._examine.rotate_by(Vector2(PI, 0))
	assert_false(_reader.is_open(), "already discovered note does not reopen automatically")


func test_examine_mouse_rotation_zoom_and_back() -> void:
	_inventory.open()
	_inventory._select("item_dictaphone")
	_inventory._on_examine()
	await _settle()
	var view := _inventory._examine
	var at := Vector2(1390, 530)
	_mouse(at, MOUSE_BUTTON_LEFT, true)
	var motion := InputEventMouseMotion.new()
	motion.position = at + Vector2(80, 0)
	motion.relative = Vector2(80, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	_tree.root.push_input(motion, true)
	_mouse(motion.position, MOUSE_BUTTON_LEFT, false)
	assert_true(absf(view._pivot.rotation.y) > 0.5, "mouse turn: %s" % view._pivot.rotation)
	_mouse(at, MOUSE_BUTTON_WHEEL_UP, true)
	assert_true(view._camera.position.z < 2.2, "wheel zoom: %s" % view._camera.position.z)
	_key(KEY_HOME)
	assert_eq(view._camera.position.z, 2.2)
	assert_eq(view._pivot.rotation, Vector3.ZERO)
	_mouse(at, MOUSE_BUTTON_RIGHT, true)
	assert_true(_inventory.is_open(), "right click returns from examine to inventory")
	assert_true(_inventory._examine == null, "right click closes the examine panel")


func _settle() -> void:
	for i in 4:
		await _tree.process_frame


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	_tree.root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	_tree.root.push_input(event, true)


func _mouse(at: Vector2, button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = button
	event.pressed = pressed
	_tree.root.push_input(event, true)
