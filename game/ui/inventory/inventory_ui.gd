class_name InventoryUi
extends CanvasLayer
## Satchel inventory (GDD §3.4, §11): main slots, key pouch, and actions on the selected
## item: Examine (3D), Use (enters use-item mode on the next hotspot clicked), Combine
## (then pick the other item), Drop (droppable items only; leaves a pickup, 1-hop noise).
## Also hosts the Effects Bin transfer view when opened from a safe room.

const UI_NAME := &"inventory"
const DROP_NOISE_HOPS := 1
const SATCHEL := preload("res://assets/art/ui/satchel.png")
const SLOT_EMPTY := preload("res://assets/controls/slot-empty.svg")
const SLOT_HOVER := preload("res://assets/controls/slot-hover.svg")
const SLOT_SELECTED := preload("res://assets/controls/slot-selected.svg")
const SLOT_DISABLED := preload("res://assets/controls/slot-disabled.svg")

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
var _actions: HFlowContainer
var _preview: TextureRect
var _capacity: Label
var _take: Button
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
	_bin = null
	_take = null
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
	var dimmer := UiStyle.dimmer()
	dimmer.gui_input.connect(_on_surface_input)
	_root.add_child(dimmer)
	_root.add_child(UiStyle.artwork(SATCHEL, Vector2(80, 145), Vector2(930, 620)))
	var title := UiStyle.label("ui.inventory.title", 44, UiStyle.ACCENT)
	title.position = Vector2(120, 70)
	_root.add_child(title)
	_capacity = UiStyle.label("", 24, UiStyle.INK)
	_capacity.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_capacity.position = Vector2(215, 235)
	_root.add_child(_capacity)
	_slots = GridContainer.new()
	_slots.position = Vector2(215, 290)
	_slots.add_theme_constant_override("h_separation", 16)
	_slots.add_theme_constant_override("v_separation", 16)
	_root.add_child(_slots)
	var pocket := UiStyle.button("ui.inventory.key_pouch", _focus_pouch, 22)
	pocket.position = Vector2(818, 350)
	pocket.size = Vector2(146, 130)
	pocket.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pocket.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pocket.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	_root.add_child(pocket)
	var pouch_label := UiStyle.label("ui.inventory.key_pouch", 28, UiStyle.ACCENT)
	pouch_label.position = Vector2(135, 724)
	_root.add_child(pouch_label)
	_pouch = ItemList.new()
	_pouch.position = Vector2(135, 766)
	_pouch.size = Vector2(780, 194)
	_pouch.fixed_icon_size = Vector2i(56, 56)
	_pouch.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_pouch.item_selected.connect(func(i: int) -> void: _select(String(_pouch.get_item_metadata(i))))
	_pouch.gui_input.connect(_on_surface_input)
	_root.add_child(_pouch)
	var details := Panel.new()
	details.position = Vector2(1020, 155)
	details.size = Vector2(800, 805)
	details.gui_input.connect(_on_surface_input)
	_root.add_child(details)
	_name = UiStyle.label("", 36, UiStyle.ACCENT)
	_name.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name.position = Vector2(1060, 185)
	_name.size = Vector2(720, 85)
	_root.add_child(_name)
	_desc = UiStyle.label("", 28)
	_desc.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.position = Vector2(1060, 280)
	_desc.size = Vector2(720, 145)
	_root.add_child(_desc)
	_actions = HFlowContainer.new()
	_actions.position = Vector2(1060, 445)
	_actions.size = Vector2(720, 140)
	_actions.add_theme_constant_override("h_separation", 12)
	_actions.add_theme_constant_override("v_separation", 12)
	_root.add_child(_actions)
	_preview = UiStyle.artwork(null, Vector2(1200, 585), Vector2(430, 330))
	_root.add_child(_preview)
	if _bin_mode:
		var bin_label := UiStyle.label("ui.bin.title", 28, UiStyle.ACCENT)
		bin_label.position = Vector2(1060, 600)
		_root.add_child(bin_label)
		_bin = ItemList.new()
		_bin.position = Vector2(1060, 645)
		_bin.size = Vector2(720, 210)
		_bin.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		_bin.item_activated.connect(_take_from_bin)
		_bin.item_selected.connect(func(_i: int) -> void: _take.disabled = false)
		_bin.gui_input.connect(_on_surface_input)
		_root.add_child(_bin)
		_take = UiStyle.button("ui.bin.take", _take_selected, 24)
		_take.position = Vector2(1060, 880)
		_root.add_child(_take)
	var back := UiStyle.button("ui.common.back", close)
	back.position = Vector2(120, 990)
	_root.add_child(back)
	back.grab_focus.call_deferred()


func _on_surface_input(event: InputEvent) -> void:
	if _is_right_click(event):
		get_viewport().set_input_as_handled()
		if _examine:
			_close_examine()
		else:
			close()


func _focus_pouch() -> void:
	_pouch.grab_focus()
	if _pouch.item_count > 0:
		_pouch.select(0)
		_select(String(_pouch.get_item_metadata(0)))


static func _slot_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 8
	style.texture_margin_right = 8
	style.texture_margin_top = 8
	style.texture_margin_bottom = 8
	style.set_content_margin_all(12)
	return style


func _refresh() -> void:
	if not _open:
		return
	var focus := get_viewport().gui_get_focus_owner()
	var focused_slot := int(focus.get_meta("slot", -1)) if focus else -1
	var bin_selection := _bin.get_selected_items() if _bin else PackedInt32Array()
	for child in _slots.get_children():
		_slots.remove_child(child)
		child.queue_free()
	var expanded := GameState.slot_count() > 6
	_slots.columns = 4 if expanded else 3
	_capacity.text = tr("ui.inventory.capacity").format(
		{"used": GameState.slot_count() - GameState.free_slots(), "total": GameState.slot_count()}
	)
	for i in GameState.slot_count():
		var item_id := GameState.inventory[i]
		var button := Button.new()
		button.set_meta("slot", i)
		button.custom_minimum_size = Vector2(128, 160) if expanded else Vector2(168, 168)
		button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 20 if expanded else 22)
		button.add_theme_stylebox_override(
			"normal", _slot_style(SLOT_SELECTED if item_id != "" and item_id == selected else SLOT_EMPTY)
		)
		button.add_theme_stylebox_override("hover", _slot_style(SLOT_HOVER))
		button.add_theme_stylebox_override("pressed", _slot_style(SLOT_SELECTED))
		button.add_theme_stylebox_override("focus", _slot_style(SLOT_SELECTED))
		button.add_theme_stylebox_override("disabled", _slot_style(SLOT_DISABLED))
		button.gui_input.connect(_on_surface_input)
		if item_id != "":
			button.text = _item_name(item_id)
			button.tooltip_text = button.text
			var data := ContentDB.get_item(item_id)
			if data and data.icon:
				button.icon = data.icon
				button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
				button.add_theme_constant_override("icon_max_width", 64)
			button.pressed.connect(_on_slot.bind(i))
		else:
			button.text = str(i + 1)
			button.disabled = true
		_slots.add_child(button)
		if i == focused_slot and not button.disabled:
			button.grab_focus()
	var pouch_scroll := _pouch.get_v_scroll_bar().value
	_pouch.clear()
	for item_id in GameState.key_pouch:
		var item := ContentDB.get_item(item_id)
		var fallback := "key" if item and item.kind == ItemData.Kind.KEY else "hand"
		if item and item.kind == ItemData.Kind.FRAGMENT:
			fallback = "folder"
		var icon := item.icon if item and item.icon else UiStyle.ICONS[fallback] as Texture2D
		var idx := _pouch.add_item(_item_name(item_id), icon)
		_pouch.set_item_metadata(idx, item_id)
		if item_id == selected:
			_pouch.select(idx)
	_pouch.get_v_scroll_bar().set_value_no_signal(pouch_scroll)
	if _bin:
		_bin.clear()
		for item_id in GameState.bin:
			_bin.add_item(_item_name(item_id))
		_take.disabled = _bin.item_count == 0
		if _bin.item_count > 0:
			_bin.select(mini(bin_selection[0], _bin.item_count - 1) if not bin_selection.is_empty() else 0)
	_refresh_detail()


func _refresh_detail() -> void:
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()
	_preview.visible = false
	if selected == "" or not GameState.has_item(selected):
		_name.text = ""
		_desc.text = tr("ui.inventory.combine_pick") if _combine_from != "" else tr("ui.inventory.select")
		return
	var item: ItemData = ContentDB.get_item(selected)
	_name.text = _item_name(selected)
	_desc.text = tr(item.desc_key) if item else ""
	if _combine_from != "":
		_desc.text = tr("ui.inventory.combine_pick")
	_actions.add_child(UiStyle.button("ui.inventory.examine", _on_examine, 24))
	_actions.add_child(UiStyle.button("ui.inventory.use", _on_use, 24))
	if item and item.storage == ItemData.Storage.SLOT:
		_actions.add_child(UiStyle.button("ui.inventory.combine", _on_combine, 24))
		if item.droppable:
			_actions.add_child(UiStyle.button("ui.inventory.drop", _on_drop, 24))
		if _bin_mode:
			_actions.add_child(UiStyle.button("ui.bin.store", _on_store, 24))
	if not _bin_mode and item and item.icon:
		_preview.texture = item.icon
		_preview.visible = true


func _take_selected() -> void:
	var indices := _bin.get_selected_items()
	if not indices.is_empty():
		_take_from_bin(indices[0])


func _take_from_bin(index: int) -> void:
	if not GameState.take_from_bin(index):
		EventBus.text_requested.emit("ui.inventory.full")


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _open and is_instance_valid(_pouch):
		_refresh()


static func _item_name(item_id: String) -> String:
	var item: ItemData = ContentDB.get_item(item_id)
	return TranslationServer.translate(item.name_key) if item else item_id


# --- Actions ------------------------------------------------------------------


func _on_slot(slot: int) -> void:
	_select(GameState.inventory[slot])


func _select(item_id: String) -> void:
	if _examine:
		_close_examine()
	if _combine_from != "" and item_id != _combine_from:
		var from := _combine_from
		_combine_from = ""
		combine(from, item_id)
		_refresh_detail()
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
	if consume(selected):
		return
	var controller := get_tree().get_first_node_in_group(&"interaction_controller") as InteractionController
	if controller:
		controller.held_item = StringName(selected)
	close()


## Uses up a consumable (e.g. Sedatives). Returns false if the item isn't one.
func consume(item_id: String) -> bool:
	var item: ItemData = ContentDB.get_item(item_id)
	if item == null or item.kind != ItemData.Kind.CONSUMABLE or item.use_actions.is_empty():
		return false
	GameState.remove_item(item_id)
	Action.run_all(item.use_actions)
	selected = ""
	_refresh()
	return true


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
	if _examine:
		return
	var item: ItemData = ContentDB.get_item(selected)
	if item == null:
		return
	_examine = ExamineView.new()
	_examine.position = Vector2(960, 120)
	_examine.size = Vector2(860, 820)
	_root.add_child(_examine)
	_examine.setup(item)
	_examine.close_requested.connect(_close_examine)
	var heading := UiStyle.label(item.name_key, 30, UiStyle.ACCENT)
	heading.position = Vector2(24, 18)
	_examine.add_child(heading)
	var hint := UiStyle.label("ui.inventory.examine_hint", 24, UiStyle.INK_DIM)
	hint.position = Vector2(24, 700)
	hint.size = Vector2(800, 60)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_examine.add_child(hint)
	var back := UiStyle.button("ui.common.back", _close_examine)
	back.position = Vector2(24, 760)
	_examine.add_child(back)


func _close_examine() -> void:
	_examine.queue_free()
	_examine = null
