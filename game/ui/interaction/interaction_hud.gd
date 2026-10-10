class_name InteractionHud
extends CanvasLayer
## Discoverable room controls and action labels, hidden while a modal owns input.

signal inventory_requested
signal files_requested
signal map_requested
signal pause_requested

var controller: InteractionController
var _root: Control
var _hint: Label
var _prompt: Label
var _markers: Dictionary[Interactable, Button] = {}
var _room: Room


func _ready() -> void:
	layer = 5
	_root = Control.new()
	_root.theme = UiStyle.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var toolbar := HBoxContainer.new()
	toolbar.position = Vector2(28, 22)
	toolbar.add_theme_constant_override("separation", 10)
	_root.add_child(toolbar)
	toolbar.add_child(UiStyle.button("ui.interaction.inventory", _request.bind(inventory_requested), 22))
	toolbar.add_child(UiStyle.button("ui.interaction.files", _request.bind(files_requested), 22))
	toolbar.add_child(UiStyle.button("ui.interaction.map", _request.bind(map_requested), 22))
	toolbar.add_child(UiStyle.button("ui.interaction.pause", _request.bind(pause_requested), 22))
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 28
	panel.offset_right = -28
	panel.offset_top = -112
	panel.offset_bottom = -16
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(panel)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)
	_prompt = UiStyle.label("", 24, UiStyle.ACCENT)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_prompt)
	_hint = UiStyle.label("", 22)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_hint)
	EventBus.ui_opened.connect(_on_ui_opened)
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _on_ui_opened(_ui_name: StringName) -> void:
	_root.hide()


func _request(request: Signal) -> void:
	if not controller.is_blocked():
		request.emit()


func _refresh() -> void:
	_root.visible = is_instance_valid(controller) and not controller.is_blocked()
	if not _root.visible:
		return
	if _room != RoomManager.current:
		_rebuild_markers()
	var hint_key := "ui.interaction.items"
	if GameState.current_room == "G01":
		hint_key = (
			"ui.interaction.dayroom_done" if GameState.is_puzzle_solved("P01") else "ui.interaction.dayroom"
		)
	_hint.text = tr(hint_key)
	var hotspot := controller.pick_hotspot(_root.get_global_mouse_position())
	if controller.held_item != &"":
		var item := ContentDB.get_item(controller.held_item)
		_prompt.text = tr("ui.interaction.held").format({"item": tr(item.name_key) if item else ""})
	elif hotspot:
		_prompt.text = tr("ui.interaction.click").format({"action": action_text(hotspot)})
	elif controller.player.is_moving():
		_prompt.text = tr("ui.interaction.walking")
	else:
		_prompt.text = tr("ui.interaction.move")
	var camera := CameraDirector.active_camera()
	var occupied: Array[Rect2] = []
	for target in _markers:
		var button := _markers[target]
		button.visible = target.is_active() and not camera.is_position_behind(target.global_position)
		if not button.visible:
			continue
		var at := camera.unproject_position(target.global_position)
		var viewport_size := _root.get_viewport_rect().size
		button.visible = Rect2(Vector2(0, 100), viewport_size - Vector2(0, 260)).has_point(at)
		button.text = action_text(target)
		button.reset_size()
		button.position = Vector2(
			clampf(at.x - button.size.x * 0.5, 16, viewport_size.x - button.size.x - 16),
			at.y - button.size.y - 18
		)
		# Longer translations must not cover another object's click target.
		for placed in occupied:
			if button.get_rect().intersects(placed.grow(8)):
				button.position.y = placed.end.y + 12
		if button.visible:
			occupied.append(button.get_rect())


func _rebuild_markers() -> void:
	for button in _markers.values():
		button.queue_free()
	_markers.clear()
	_room = RoomManager.current
	if not is_instance_valid(_room):
		return
	for node in _room.find_children("*", "Interactable", true, false):
		var hotspot := node as Interactable
		if hotspot.prompt_key.is_empty():
			continue
		var button := UiStyle.button(hotspot.prompt_key, _activate.bind(hotspot), 22)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_root.add_child(button)
		_markers[hotspot] = button


func _activate(hotspot: Interactable) -> void:
	controller.interact_with(hotspot)


func action_text(hotspot: Interactable) -> String:
	if GameState.current_room == "G01" and hotspot.name == &"hs_radio" and GameState.is_puzzle_solved("P01"):
		return tr("ui.interaction.radio_done")
	if hotspot.kind == Interactable.Kind.EXIT and hotspot.is_locked():
		return tr("ui.interaction.locked")
	if not hotspot.prompt_key.is_empty():
		return tr(hotspot.prompt_key)
	match hotspot.kind:
		Interactable.Kind.TAKE:
			return tr("ui.interaction.take")
		Interactable.Kind.USE:
			return tr("ui.interaction.use")
		Interactable.Kind.EXIT:
			return tr("ui.interaction.exit")
	return tr("ui.interaction.examine")
