extends TestCase
## Real keyboard routing and persisted settings, with the user's config restored.

var _tree: SceneTree
var _nodes: Array[Node] = []
var _settings: Dictionary
var _config: PackedByteArray
var _config_existed: bool
var _locale: String


func before_each() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	_settings = Settings.values.duplicate(true)
	_locale = TranslationServer.get_locale()
	_config_existed = FileAccess.file_exists(Settings.PATH)
	if _config_existed:
		_config = FileAccess.get_file_as_bytes(Settings.PATH)


func after_each() -> void:
	_tree.paused = false
	for node in _nodes:
		if is_instance_valid(node):
			node.queue_free()
	Settings.values = _settings
	Settings.apply_all()
	TranslationServer.set_locale(_locale)
	if _config_existed:
		var file := FileAccess.open(Settings.PATH, FileAccess.WRITE)
		file.store_buffer(_config)
		file.close()
	elif FileAccess.file_exists(Settings.PATH):
		DirAccess.remove_absolute(Settings.PATH)


func test_front_end_options_slider_keyboard_persists() -> void:
	var options := OptionsPanel.new()
	_nodes.append(options)
	_tree.root.add_child(options)
	await _settle()
	var slider := options.find_child("volume_Music", true, false) as HSlider
	slider.value = 0.5
	slider.grab_focus()
	_key(KEY_RIGHT)
	await _settle()
	assert_eq(Settings.get_value("volume_Music"), 0.55)
	var config := ConfigFile.new()
	assert_eq(config.load(Settings.PATH), OK)
	assert_eq(config.get_value("settings", "volume_Music"), 0.55)
	assert_true(slider.has_focus(), "changing volume does not rebuild the control")


func test_front_end_locale_and_subtitles_keep_focus() -> void:
	var options := OptionsPanel.new()
	_nodes.append(options)
	_tree.root.add_child(options)
	options._select_tab("accessibility")
	await _settle()
	var french := options.find_child("locale_fr_CA", true, false) as Button
	french.grab_focus()
	_key(KEY_ENTER)
	await _settle()
	assert_eq(TranslationServer.get_locale(), "fr_CA")
	assert_eq(_tree.root.gui_get_focus_owner().name, &"locale_fr_CA")
	var large := options.find_child("subtitle_size_large", true, false) as Button
	large.grab_focus()
	_key(KEY_ENTER)
	await _settle()
	assert_eq(Settings.subtitle_font_size(), 38)
	assert_eq(_tree.root.gui_get_focus_owner().name, &"subtitle_size_large")
	var subtitles := options.find_child("subtitles", true, false) as Button
	var before := subtitles.button_pressed
	subtitles.grab_focus()
	_key(KEY_ENTER)
	await _settle()
	assert_eq(Settings.get_value("subtitles"), not before)
	assert_eq(_tree.root.gui_get_focus_owner().name, &"subtitles")


func test_front_end_options_escape_does_not_unpause_underneath() -> void:
	var pause := PauseMenu.new()
	_nodes.append(pause)
	_tree.root.add_child(pause)
	pause.open()
	pause._on_options()
	await _settle()
	_key(KEY_ESCAPE)
	await _settle()
	assert_true(_tree.paused, "first Escape closes options only")
	assert_true(pause.is_open())
	assert_eq(pause._root.find_children("*", "OptionsPanel", true, false).size(), 0)
	_key(KEY_ESCAPE)
	await _settle()
	assert_false(_tree.paused, "second Escape resumes")
	assert_false(pause.is_open())


func test_front_end_difficulty_and_options_return() -> void:
	var title: Control = load("res://game/main/title.tscn").instantiate()
	_nodes.append(title)
	_tree.root.add_child(title)
	title._begin(false)
	title._choose("threat", "committed")
	title._choose("puzzle", "hard")
	await _settle()
	assert_eq(title._threat, "committed")
	assert_eq(title._puzzle, "hard")
	assert_eq(_tree.root.gui_get_focus_owner().text, "ui.difficulty.hard")
	title._main()
	title._options()
	await _settle()
	assert_false(title._panel.visible)
	assert_eq(title._options_panel.size, title.size, "nested options artwork fills its host")
	_key(KEY_ESCAPE)
	await _settle()
	assert_true(title._panel.visible)
	assert_eq(_tree.root.gui_get_focus_owner().text, "ui.menu.new_game")


func _settle() -> void:
	await _tree.process_frame
	await _tree.process_frame
	await _tree.process_frame


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	_tree.root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	_tree.root.push_input(event)
