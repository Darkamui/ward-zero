extends TestCase
## Follow visible controls with real pointer/key input, including walking to the radio.

var _tree: SceneTree
var _game: Node
var _hud: InteractionHud
var _locale: String


func before_each() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	_locale = TranslationServer.get_locale()
	NewGame.start("patient", "normal")
	GameState.set_flag("intro.done")
	_game = load("res://game/main/game.tscn").instantiate()
	_tree.root.add_child(_game)
	_hud = _game.interaction_hud


func after_each() -> void:
	TranslationServer.set_locale(_locale)
	CameraDirector.set_physics_process(true)
	CameraDirector.unregister_room()
	RoomManager.setup(null, null)
	_game.queue_free()


func test_visible_inventory_button_and_shortcut() -> void:
	await _tree.create_timer(0.8).timeout
	var toolbar := _hud._root.get_child(0)
	var inventory_button := toolbar.get_child(0) as Button
	_click(inventory_button)
	assert_true(_game.inventory.is_open(), "visible Inventory button opens the satchel")
	assert_false(_hud._root.visible, "room labels hide immediately under a modal")
	_key(KEY_I)
	assert_false(_game.inventory.is_open(), "I closes inventory")
	await _tree.process_frame
	_key(KEY_I)
	assert_true(_game.inventory.is_open(), "I opens inventory")
	_game.inventory.close()
	await _tree.process_frame
	EventBus.text_requested.emit("rooms.g01.couch.examine")
	assert_false(_hud._root.visible)
	_key(KEY_SPACE)
	assert_false((_game.get_node("TextBox") as TextBox).is_open())
	await _tree.process_frame
	assert_true(_hud._root.visible, "dismissing text restores room controls")


func test_radio_label_walks_to_tuning_controls() -> void:
	await _tree.create_timer(0.8).timeout
	# The player starts on the west side. Show the radio-side camera to click its label.
	CameraDirector.cut_to(&"cam_b")
	await _tree.process_frame
	await _tree.process_frame
	var radio := RoomManager.current.get_node("Hotspots/hs_radio") as Interactable
	var button := _hud._markers[radio]
	assert_true(button.visible, "radio has a visible action target")
	_click(button)
	assert_true(_game.player.is_moving(), "label uses the normal walking interaction")
	for i in 600:
		if _game.puzzle_host.is_open():
			break
		await _tree.physics_frame
	assert_true(_game.puzzle_host.is_open(), "arrival opens the actual radio, not an examine message")
	if not _game.puzzle_host.is_open():
		return
	await _tree.process_frame
	assert_eq(_game.puzzle_host.current._controls.size(), 3, "needle and both knobs are available")
	assert_false(_hud._root.visible)
	_game.puzzle_host.close()
	GameState.mark_puzzle_solved("P01")
	await _tree.process_frame
	assert_eq(_hud.action_text(radio), _hud.tr("ui.interaction.radio_done"))


func test_labels_stay_separate_and_clear_on_room_change() -> void:
	await _tree.create_timer(0.8).timeout
	CameraDirector.set_physics_process(false)
	for locale in ["en", "fr_CA"]:
		TranslationServer.set_locale(locale)
		for camera in [&"cam_a", &"cam_b"]:
			CameraDirector.cut_to(camera)
			await _tree.process_frame
			await _tree.process_frame
			var occupied: Array[Rect2] = []
			for button in _hud._markers.values():
				if not button.visible:
					continue
				for rect in occupied:
					assert_false(rect.intersects(button.get_rect()), "labels remain clickable in " + locale)
				occupied.append(button.get_rect())
	_hud.controller.held_item = &"item_wristband"
	await _tree.process_frame
	await _tree.process_frame
	assert_true(
		_hud._prompt.text.contains(_hud.tr("item.wristband.name")),
		"held-item prompt names the selected item: " + _hud._prompt.text
	)
	RoomManager.load_room_now(ContentDB.get_room(&"G02"), &"spawn_from_g01")
	await _tree.process_frame
	await _tree.process_frame
	assert_eq(_hud._markers.size(), 0, "Dayroom labels are removed on leaving the room")


func _click(button: Button) -> void:
	var event := InputEventMouseButton.new()
	event.position = button.get_global_rect().get_center()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	_tree.root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	_tree.root.push_input(event, true)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	_tree.root.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	_tree.root.push_input(event, true)
