extends Control
## Illustrated front end; existing save and difficulty flows share the same backdrop.

const ENABLED_THREAT := ["observer", "patient", "committed"]
const ENABLED_PUZZLE := ["easy", "normal", "hard"]

var _threat := "patient"
var _puzzle := "normal"
var _ng_plus := false
var _panel: Control
var _options_panel: OptionsPanel
var _starting := false


func _ready() -> void:
	theme = UiStyle.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	MenuStyle.backdrop(self)
	MenuStyle.ambience(self)
	_main()
	MenuStyle.reveal(self)


func _clear() -> void:
	if _panel:
		_panel.hide()
		_panel.queue_free()
	_panel = Control.new()
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _main() -> void:
	_clear()
	MenuStyle.eyebrow(_panel, "ui.front.institute", Vector2(140, 125))
	var title := MenuStyle.label_at(_panel, "ui.title", Vector2(130, 192), 122)
	title.uppercase = true
	MenuStyle.rule(_panel, Vector2(140, 368), 90)
	MenuStyle.paragraph(_panel, "ui.front.tagline", Vector2(140, 395), 620, 25)
	var box := VBoxContainer.new()
	box.position = Vector2(140, 505)
	box.custom_minimum_size.x = 550
	box.add_theme_constant_override("separation", 4)
	_panel.add_child(box)
	var begin := MenuStyle.button("ui.menu.new_game", _begin.bind(false), true, 32)
	box.add_child(begin)
	if Profile.ng_plus_unlocked():
		box.add_child(MenuStyle.button("ui.menu.new_game_plus", _begin.bind(true)))
	var load_btn := MenuStyle.button("ui.menu.load", _load)
	load_btn.disabled = SaveSystem.list_slots().is_empty()
	box.add_child(load_btn)
	box.add_child(MenuStyle.button("ui.options.title", _options))
	box.add_child(MenuStyle.button("ui.menu.import", _import, false, 24))
	if not OS.has_feature("web"):
		box.add_child(MenuStyle.button("ui.menu.quit", func() -> void: get_tree().quit(), false, 24))
	MenuStyle.footer(_panel, "ui.front.headphones")
	begin.grab_focus.call_deferred()


func _begin(ng_plus: bool) -> void:
	_ng_plus = ng_plus
	_new_game()


func _new_game() -> void:
	_clear()
	MenuStyle.eyebrow(_panel, "ui.front.admission", Vector2(140, 115))
	MenuStyle.label_at(
		_panel, "ui.menu.new_game_plus" if _ng_plus else "ui.menu.new_game", Vector2(135, 166), 72
	)
	MenuStyle.paragraph(_panel, "ui.front.difficulty_hint", Vector2(140, 280), 800)
	MenuStyle.rule(_panel, Vector2(140, 350), 850)
	MenuStyle.eyebrow(_panel, "ui.difficulty.threat", Vector2(140, 390))
	var threat_row := _choice_row(GameState.THREAT_LEVELS, ENABLED_THREAT, "threat")
	threat_row.position = Vector2(140, 440)
	_panel.add_child(threat_row)
	MenuStyle.paragraph(_panel, "ui.difficulty.threat_%s" % _threat, Vector2(140, 520), 820, 24)
	MenuStyle.eyebrow(_panel, "ui.difficulty.puzzle", Vector2(140, 630))
	var puzzle_row := _choice_row(GameState.PUZZLE_LEVELS, ENABLED_PUZZLE, "puzzle")
	puzzle_row.position = Vector2(140, 675)
	_panel.add_child(puzzle_row)
	MenuStyle.paragraph(_panel, "ui.difficulty.puzzle_%s" % _puzzle, Vector2(140, 755), 820, 24)
	var begin := MenuStyle.button("ui.menu.start", _start, true, 30)
	begin.position = Vector2(140, 860)
	begin.size.x = 320
	_panel.add_child(begin)
	var back := MenuStyle.button("ui.common.back", _main)
	back.position = Vector2(500, 860)
	_panel.add_child(back)
	MenuStyle.footer(_panel, "ui.front.headphones")
	begin.grab_focus.call_deferred()


func _choice_row(levels: Array, enabled: Array, which: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for level in levels:
		var b := MenuStyle.button("ui.difficulty.%s" % level, _choose.bind(which, level))
		b.custom_minimum_size.x = 250
		b.toggle_mode = true
		b.button_pressed = level == (_threat if which == "threat" else _puzzle)
		b.disabled = not enabled.has(level)
		row.add_child(b)
	return row


func _choose(which: String, level: String) -> void:
	if which == "threat":
		_threat = level
	else:
		_puzzle = level
	_new_game()
	for b in _panel.find_children("*", "Button", true, false):
		if b.text == "ui.difficulty.%s" % level:
			b.grab_focus.call_deferred()


func _start() -> void:
	if _starting:
		return
	_starting = true
	NewGame.start(_threat, _puzzle, -1, _ng_plus)
	get_tree().change_scene_to_file("res://game/main/act1_intro.tscn")


func _load() -> void:
	_clear()
	var box := UiStyle.centered_panel(_panel, Vector2(1300, 800))
	box.add_child(UiStyle.label("ui.menu.load", 40, UiStyle.ACCENT))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1200, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var slots := SlotList.new()
	slots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots.slot_chosen.connect(_on_load_slot)
	scroll.add_child(slots)
	slots.refresh()
	box.add_child(UiStyle.button("ui.common.back", _main))


func _on_load_slot(slot: int) -> void:
	if SaveSystem.load_slot(slot) == SaveSystem.SaveError.OK:
		SaveScreen.restart_game(get_tree())


func _import() -> void:
	_clear()
	var box := UiStyle.centered_panel(_panel, Vector2(1300, 600))
	box.add_child(UiStyle.label("ui.menu.import", 40, UiStyle.ACCENT))
	box.add_child(UiStyle.label("ui.save.export_label", 24, UiStyle.INK_DIM))
	var text := TextEdit.new()
	text.custom_minimum_size = Vector2(1200, 200)
	text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	box.add_child(text)
	var msg := UiStyle.label("", 24, UiStyle.ACCENT)
	msg.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.add_child(msg)
	var row := HBoxContainer.new()
	row.add_child(UiStyle.button("ui.save.import", _on_import.bind(text, msg)))
	row.add_child(UiStyle.button("ui.common.back", _main))
	box.add_child(row)


func _on_import(text: TextEdit, msg: Label) -> void:
	var err := SaveSystem.import_string(text.text)
	if err == SaveSystem.SaveError.OK:
		SaveScreen.restart_game(get_tree())
	else:
		msg.text = tr(SaveSystem.error_key(err))


func _options() -> void:
	if is_instance_valid(_options_panel):
		return
	_panel.hide()
	_options_panel = OptionsPanel.new()
	_options_panel.closed.connect(_main)
	add_child(_options_panel)


func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(_options_panel):
		return
	if event.is_action_pressed(&"pause") or InventoryUi._is_right_click(event):
		get_viewport().set_input_as_handled()
		_main()
