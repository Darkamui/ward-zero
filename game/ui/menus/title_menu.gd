extends Control
## Title screen: New Game (difficulty selectors, GDD §8), Load, Import save code, Options.
## M1 enables Patient threat and Normal puzzles only; the others arrive in M2.

const ENABLED_THREAT := ["patient"]
const ENABLED_PUZZLE := ["normal"]

var _threat := "patient"
var _puzzle := "normal"
var _panel: Control


func _ready() -> void:
	theme = UiStyle.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.025)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_main()


func _clear() -> void:
	if _panel:
		_panel.queue_free()
	_panel = Control.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)


func _main() -> void:
	_clear()
	var title := UiStyle.label("ui.title", 96, UiStyle.INK)
	title.position = Vector2(160, 200)
	_panel.add_child(title)
	var box := VBoxContainer.new()
	box.position = Vector2(170, 460)
	box.add_theme_constant_override("separation", 16)
	_panel.add_child(box)
	box.add_child(UiStyle.button("ui.menu.new_game", _new_game, 32))
	var load_btn := UiStyle.button("ui.menu.load", _load, 32)
	load_btn.disabled = SaveSystem.list_slots().is_empty()
	box.add_child(load_btn)
	box.add_child(UiStyle.button("ui.menu.import", _import, 32))
	box.add_child(UiStyle.button("ui.options.title", _options, 32))
	if not OS.has_feature("web"):
		box.add_child(UiStyle.button("ui.menu.quit", func() -> void: get_tree().quit(), 32))


func _new_game() -> void:
	_clear()
	var box := UiStyle.centered_panel(_panel, Vector2(1100, 700))
	box.add_child(UiStyle.label("ui.menu.new_game", 40, UiStyle.ACCENT))
	box.add_child(UiStyle.label("ui.difficulty.threat", 28))
	box.add_child(_choice_row(GameState.THREAT_LEVELS, ENABLED_THREAT, "threat"))
	box.add_child(UiStyle.label("ui.difficulty.threat_%s" % _threat, 22, UiStyle.INK_DIM))
	box.add_child(UiStyle.label("ui.difficulty.puzzle", 28))
	box.add_child(_choice_row(GameState.PUZZLE_LEVELS, ENABLED_PUZZLE, "puzzle"))
	box.add_child(UiStyle.label("ui.difficulty.puzzle_%s" % _puzzle, 22, UiStyle.INK_DIM))
	box.add_child(UiStyle.label("ui.difficulty.coming", 20, UiStyle.INK_DIM))
	var row := HBoxContainer.new()
	row.add_child(UiStyle.button("ui.menu.start", _start, 32))
	row.add_child(UiStyle.button("ui.common.back", _main, 32))
	box.add_child(row)


func _choice_row(levels: Array, enabled: Array, which: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	for level in levels:
		var b := UiStyle.button("ui.difficulty.%s" % level, _choose.bind(which, level))
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


func _start() -> void:
	NewGame.start(_threat, _puzzle)
	get_tree().change_scene_to_file("res://game/main/game.tscn")


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
	var o := OptionsPanel.new()
	o.closed.connect(_main)
	add_child(o)
