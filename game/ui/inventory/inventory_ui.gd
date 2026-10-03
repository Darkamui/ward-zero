class_name InventoryUi
extends CanvasLayer
## Satchel inventory (GDD §3.4, §11): main slots, key pouch, and actions on the selected
## item: Examine (3D), Use (enters use-item mode on the next hotspot clicked), Combine
## (then pick the other item), Drop (droppable items only; leaves a pickup, 1-hop noise).
## Also hosts the Effects Bin transfer view when opened from a safe room.

const UI_NAME := &"inventory"
const DROP_NOISE_HOPS := 1

var selected := ""
var _open := false
var _bin_mode := false
var _combine_from := ""
var _root: Control
var _slots: GridContainer
var _pouch: ItemList
var _bin: ItemList
var _name: Label
var _desc: Label
var _actions: HBoxContainer
var _examine: ExamineView


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.ui_requested.connect(_on_ui_requested)
	GameState.inventory_changed.connect(_refresh)
	GameState.key_pouch_changed.connect(_refresh)
	GameState.bin_changed.connect(_refresh)


func _on_ui_requested(ui_name: StringName) -> void:
	if ui_name == &"effects_bin":
		open(true)


func is_open() -> bool:
	return _open


func open(bin_mode := false) -> void:
	if _open:
		return
	_open = true
	_bin_mode = bin_mode
	selected = ""
	_combine_from = ""
	_build()
	_refresh()
	EventBus.ui_opened.emit(UI_NAME)


func close() -> void:
	if not _open:
		return
	_open = false
	_root.queue_free()
	_examine = null
	EventBus.ui_closed.emit(UI_NAME)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"open_inventory"):
		if _open:
			close()
		elif not _ui_busy():
			open()
		get_viewport().set_input_as_handled()
	elif _open and (event.is_action_pressed(&"pause") or _is_right_click(event)):
		if _examine:
			_close_examine()
		else:
			close()
		get_viewport().set_input_as_handled()


func _ui_busy() -> bool:
	var controller := get_tree().get_first_node_in_group(&"interaction_controller") as InteractionController
	return controller != null and controller.is_blocked()


static func _is_right_click(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT


# --- Layout -------------------------------------------------------------------


func _build() -> void:
	_root = Control.new()
	_root.theme = UiStyle.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.add_child(UiStyle.dimmer())
	var title := UiStyle.label("ui.inventory.title", 44, UiStyle.ACCENT)
	title.position = Vector2(120, 70)
	_root.add_child(title)
	_slots = GridContainer.new()
	_slots.columns = 4
	_slots.position = Vector2(120, 160)
	_slots.add_theme_constant_override("h_separation", 16)
	_slots.add_theme_constant_override("v_separation", 16)
	_root.add_child(_slots)
	var pouch_label := UiStyle.label("ui.inventory.key_pouch", 30, UiStyle.ACCENT)
	pouch_label.position = Vector2(120, 520)
	_root.add_child(pouch_label)
	_pouch = ItemList.new()
	_pouch.position = Vector2(120, 570)
	_pouch.size = Vector2(760, 360)
	_pouch.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_pouch.item_selected.connect(func(i: int) -> void: _select(String(_pouch.get_item_metadata(i))))
	_root.add_child(_pouch)
	_name = UiStyle.label("", 36, UiStyle.ACCENT)
	_name.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_name.position = Vector2(1000, 160)
	_root.add_child(_name)
	_desc = UiStyle.label("", 28)
	_desc.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.position = Vector2(1000, 220)
	_desc.size = Vector2(800, 200)
	_root.add_child(_desc)
	_actions = HBoxContainer.new()
	_actions.position = Vector2(1000, 440)
	_actions.add_theme_constant_override("separation", 14)
	_root.add_child(_actions)
	if _bin_mode:
		var bin_label := UiStyle.label("ui.bin.title", 30, UiStyle.ACCENT)
		bin_label.position = Vector2(1000, 520)
		_root.add_child(bin_label)
		_bin = ItemList.new()
		_bin.position = Vector2(1000, 570)
		_bin.size = Vector2(760, 360)
		_bin.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		_bin.item_activated.connect(func(i: int) -> void: GameState.take_from_bin(i))
		_root.add_child(_bin)
		var hint := UiStyle.label("ui.bin.hint", 24, UiStyle.INK_DIM)
		hint.position = Vector2(1000, 940)
		_root.add_child(hint)


func _refresh() -> void:
	if not _open:
		return
	for c in _slots.get_children():
		c.queue_free()
	for i in GameState.slot_count():
		var item_id := GameState.inventory[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(170, 150)
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 22)
		if item_id != "":
			b.text = _item_name(item_id)
			b.pressed.connect(_on_slot.bind(i))
			if item_id == selected:
				b.text = "▶ " + b.text
		else:
			b.text = "—"
			b.disabled = true
		_slots.add_child(b)
	_pouch.clear()
	for item_id in GameState.key_pouch:
		var idx := _pouch.add_item(("▶ " if item_id == selected else "") + _item_name(item_id))
		_pouch.set_item_metadata(idx, item_id)
	if _bin:
		_bin.clear()
		for item_id in GameState.bin:
			_bin.add_item(_item_name(item_id))
	_refresh_detail()


func _refresh_detail() -> void:
	for c in _actions.get_children():
		c.queue_free()
	if selected == "" or not GameState.has_item(selected):
		_name.text = ""
		_desc.text = tr("ui.inventory.combine_pick") if _combine_from != "" else ""
		return
	var item: ItemData = ContentDB.get_item(selected)
	_name.text = _item_name(selected)
	_desc.text = tr(item.desc_key) if item else ""
	if _combine_from != "":
		_desc.text = tr("ui.inventory.combine_pick")
	_actions.add_child(UiStyle.button("ui.inventory.examine", _on_examine))
	_actions.add_child(UiStyle.button("ui.inventory.use", _on_use))
	if item and item.storage == ItemData.Storage.SLOT:
		_actions.add_child(UiStyle.button("ui.inventory.combine", _on_combine))
		if item.droppable:
			_actions.add_child(UiStyle.button("ui.inventory.drop", _on_drop))
		if _bin_mode:
			_actions.add_child(UiStyle.button("ui.bin.store", _on_store))


static func _item_name(item_id: String) -> String:
	var item: ItemData = ContentDB.get_item(item_id)
	return TranslationServer.translate(item.name_key) if item else item_id


# --- Actions ------------------------------------------------------------------


func _on_slot(slot: int) -> void:
	_select(GameState.inventory[slot])


func _select(item_id: String) -> void:
	if _combine_from != "" and item_id != _combine_from:
		combine(_combine_from, item_id)
		_combine_from = ""
		return
	selected = item_id
	_refresh()


## Combines two held items. Returns false (with a message) if they don't combine.
func combine(a: String, b: String) -> bool:
	var ia: ItemData = ContentDB.get_item(a)
	var ib: ItemData = ContentDB.get_item(b)
	var result: StringName = &""
	if ia and ia.combines_with.has(StringName(b)):
		result = ia.combines_with[StringName(b)]
	elif ib and ib.combines_with.has(StringName(a)):
		result = ib.combines_with[StringName(a)]
	if result == &"":
		EventBus.text_requested.emit("ui.inventory.no_combine")
		return false
	var slot := GameState.inventory.find(a)
	GameState.remove_item(b)
	GameState.replace_slot(slot, String(result))
	selected = String(result)
	_refresh()
	return true


func _on_combine() -> void:
	_combine_from = selected
	_refresh_detail()


func _on_use() -> void:
	var controller := get_tree().get_first_node_in_group(&"interaction_controller") as InteractionController
	if controller:
		controller.held_item = StringName(selected)
	close()


func _on_drop() -> void:
	drop(selected)


## Drops a droppable slot item at the player's feet. Returns false if it can't.
func drop(item_id: String) -> bool:
	var item: ItemData = ContentDB.get_item(item_id)
	if item == null or not item.droppable or RoomManager.current == null or RoomManager.player == null:
		return false
	if not GameState.remove_item(item_id):
		return false
	RoomManager.current.add_dropped_item(item_id, RoomManager.player.global_position)
	EventBus.noise_emitted.emit(StringName(GameState.current_room), DROP_NOISE_HOPS)
	selected = ""
	_refresh()
	return true


func _on_store() -> void:
	var slot := GameState.inventory.find(selected)
	if slot != -1:
		GameState.move_to_bin(slot)
	selected = ""
	_refresh()


func _on_examine() -> void:
	var item: ItemData = ContentDB.get_item(selected)
	if item == null:
		return
	_examine = ExamineView.new()
	_examine.position = Vector2(960, 120)
	_examine.size = Vector2(860, 820)
	_root.add_child(_examine)
	_examine.setup(item)
	var hint := UiStyle.label("ui.inventory.examine_hint", 24, UiStyle.INK_DIM)
	hint.position = Vector2(0, 780)
	_examine.add_child(hint)


func _close_examine() -> void:
	_examine.queue_free()
	_examine = null
