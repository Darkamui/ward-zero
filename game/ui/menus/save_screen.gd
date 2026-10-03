class_name SaveScreen
extends CanvasLayer
## Tape recorder save screen (GDD §8.1, §11). Opened by the recorder hotspot
## (OpenUi "save_screen"). Save to a slot, load, or export/import a save as text.

const UI_NAME := &"save_screen"

var _root: Control
var _slots: SlotList
var _text: TextEdit
var _message: Label
var _mode_load := false


func _ready() -> void:
	layer = 42
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.ui_requested.connect(_on_ui_requested)


func _on_ui_requested(ui_name: StringName) -> void:
	if ui_name == UI_NAME:
		open()


func is_open() -> bool:
	return _root != null


func open() -> void:
	if _root:
		return
	_root = Control.new()
	_root.theme = UiStyle.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.add_child(UiStyle.dimmer())
	var box := UiStyle.centered_panel(_root, Vector2(1400, 900))
	box.add_child(UiStyle.label("ui.save.title", 40, UiStyle.ACCENT))
	var modes := HBoxContainer.new()
	modes.add_child(UiStyle.button("ui.save.mode_save", _set_mode.bind(false)))
	modes.add_child(UiStyle.button("ui.save.mode_load", _set_mode.bind(true)))
	box.add_child(modes)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1300, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_slots = SlotList.new()
	_slots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slots.slot_chosen.connect(_on_slot)
	scroll.add_child(_slots)
	_message = UiStyle.label("", 24, UiStyle.ACCENT)
	_message.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.add_child(_message)
	box.add_child(UiStyle.label("ui.save.export_label", 24, UiStyle.INK_DIM))
	_text = TextEdit.new()
	_text.custom_minimum_size = Vector2(1300, 110)
	_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	box.add_child(_text)
	var row := HBoxContainer.new()
	row.add_child(UiStyle.button("ui.save.export", _on_export))
	row.add_child(UiStyle.button("ui.save.import", _on_import))
	row.add_child(UiStyle.button("ui.common.back", close))
	box.add_child(row)
	_set_mode(false)
	EventBus.ui_opened.emit(UI_NAME)


func close() -> void:
	if _root == null:
		return
	_root.queue_free()
	_root = null
	EventBus.ui_closed.emit(UI_NAME)


func _set_mode(load_mode: bool) -> void:
	_mode_load = load_mode
	_slots.allow_save = not load_mode
	_slots.refresh()


func _on_slot(slot: int) -> void:
	if _mode_load:
		_load(slot)
		return
	var err := SaveSystem.save(slot)
	_message.text = tr("ui.save.saved") if err == SaveSystem.SaveError.OK else tr(SaveSystem.error_key(err))
	_slots.refresh()


func _load(slot: int) -> void:
	var err := SaveSystem.load_slot(slot)
	if err != SaveSystem.SaveError.OK:
		_message.text = tr(SaveSystem.error_key(err))
		return
	close()
	SaveScreen.restart_game(get_tree())


func _on_export() -> void:
	_text.text = SaveSystem.export_string()
	DisplayServer.clipboard_set(_text.text)
	_message.text = tr("ui.save.exported")


func _on_import() -> void:
	var err := SaveSystem.import_string(_text.text)
	if err != SaveSystem.SaveError.OK:
		_message.text = tr(SaveSystem.error_key(err))
		return
	close()
	SaveScreen.restart_game(get_tree())


## Reloads the game scene so it starts from GameState (after a load or import).
static func restart_game(tree: SceneTree) -> void:
	tree.paused = false
	tree.change_scene_to_file("res://game/main/game.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if _root and (event.is_action_pressed(&"pause") or InventoryUi._is_right_click(event)):
		get_viewport().set_input_as_handled()
		close()
