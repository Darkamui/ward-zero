class_name FilesUi
extends CanvasLayer
## Files (GDD §2.2, §11): the patient folder. Documents, tapes and truth fragments the
## player has found. Documents open in the DocumentViewer; tapes replay.

enum Tab { DOCUMENTS, TAPES, FRAGMENTS }

const UI_NAME := &"files"
const FOLDER := preload("res://assets/art/ui/folder.png")

var tab := Tab.DOCUMENTS
var _open := false
var _root: Control
var _list: ItemList
var _tabs: Array[Button] = []
var _preview_title: Label
var _preview_body: Label
var _open_entry: Button
var _empty: Label
var _selected_id := ""


func _ready() -> void:
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_open() -> bool:
	return _open


func open() -> void:
	if _open:
		return
	_open = true
	_build()
	_refresh()
	EventBus.ui_opened.emit(UI_NAME)


func close() -> void:
	if not _open:
		return
	_open = false
	_root.queue_free()
	EventBus.ui_closed.emit(UI_NAME)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"open_files"):
		if _open:
			close()
		elif not _ui_busy():
			open()
		get_viewport().set_input_as_handled()
	elif _open and (event.is_action_pressed(&"pause") or InventoryUi._is_right_click(event)):
		close()
		get_viewport().set_input_as_handled()


func _ui_busy() -> bool:
	var controller := get_tree().get_first_node_in_group(&"interaction_controller") as InteractionController
	return controller != null and controller.is_blocked()


func _build() -> void:
	_root = Control.new()
	_root.theme = UiStyle.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dimmer := UiStyle.dimmer()
	dimmer.gui_input.connect(_on_surface_input)
	_root.add_child(dimmer)
	_root.add_child(UiStyle.artwork(FOLDER, Vector2(192, 28), Vector2(1536, 1024)))
	var title := UiStyle.label("ui.files.title", 44, UiStyle.ACCENT)
	title.position = Vector2(120, 70)
	_root.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(305, 232)
	tabs.add_theme_constant_override("separation", 8)
	_root.add_child(tabs)
	_tabs.clear()
	for key in ["ui.files.documents", "ui.files.tapes", "ui.files.fragments"]:
		var button := UiStyle.paper_button(key, _set_tab.bind(_tabs.size()), 24)
		button.toggle_mode = true
		tabs.add_child(button)
		_tabs.append(button)
	_list = ItemList.new()
	_list.position = Vector2(305, 320)
	_list.size = Vector2(550, 570)
	_list.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_list.fixed_icon_size = Vector2i(28, 28)
	_list.max_text_lines = 2
	_list.add_theme_color_override("font_color", UiStyle.PAPER_INK)
	_list.add_theme_color_override("font_selected_color", UiStyle.PAPER_INK)
	_list.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_list.add_theme_stylebox_override(
		"selected", UiStyle._box(Color(0.3, 0.2, 0.1, 0.16), 1, UiStyle.PAPER_INK)
	)
	_list.add_theme_stylebox_override(
		"selected_focus", UiStyle._box(Color(0.3, 0.2, 0.1, 0.16), 2, UiStyle.PAPER_INK)
	)
	_list.add_theme_stylebox_override("focus", UiStyle._box(Color(0, 0, 0, 0), 2, UiStyle.PAPER_INK))
	_list.item_selected.connect(_select_entry)
	_list.item_activated.connect(_on_activate)
	_list.gui_input.connect(_on_surface_input)
	_root.add_child(_list)
	_empty = UiStyle.label("ui.files.empty", 26, UiStyle.PAPER_INK)
	_empty.position = Vector2(330, 345)
	_root.add_child(_empty)
	_preview_title = UiStyle.label("", 32, UiStyle.PAPER_INK)
	_preview_title.add_theme_font_override("font", UiStyle.TYPEWRITER_BOLD)
	_preview_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_preview_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_title.position = Vector2(1040, 245)
	_preview_title.size = Vector2(550, 90)
	_root.add_child(_preview_title)
	_preview_body = UiStyle.label("", 28, UiStyle.PAPER_INK)
	_preview_body.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_preview_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_body.max_lines_visible = 10
	_preview_body.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_preview_body.position = Vector2(1040, 350)
	_preview_body.size = Vector2(535, 420)
	_root.add_child(_preview_body)
	_open_entry = UiStyle.paper_button("ui.files.read", _open_selected)
	_open_entry.position = Vector2(1040, 820)
	_root.add_child(_open_entry)
	var back := UiStyle.button("ui.common.back", close)
	back.position = Vector2(120, 990)
	_root.add_child(back)
	_list.grab_focus.call_deferred()


func _on_surface_input(event: InputEvent) -> void:
	if InventoryUi._is_right_click(event):
		get_viewport().set_input_as_handled()
		close()


func _set_tab(t: Tab) -> void:
	tab = t
	_selected_id = ""
	_list.get_v_scroll_bar().value = 0
	_refresh()


## Ids listed in the current tab, in order.
func entries() -> Array[String]:
	var result: Array[String] = []
	match tab:
		Tab.DOCUMENTS:
			result = GameState.documents.duplicate()
		Tab.TAPES:
			result = GameState.tapes.duplicate()
		Tab.FRAGMENTS:
			for doc_id in GameState.documents:
				var d: DocumentData = ContentDB.get_document(doc_id)
				if d and d.fragment_id != &"":
					result.append(doc_id)
	return result


func _refresh() -> void:
	if not _open:
		return
	var scroll := _list.get_v_scroll_bar().value
	_list.clear()
	var selected_index := 0
	for id in entries():
		var label := id
		if tab == Tab.TAPES:
			var tape: TapeData = ContentDB.get_tape(id)
			label = tr(tape.title_key) if tape else id
		else:
			var document: DocumentData = ContentDB.get_document(id)
			if document:
				label = DocumentRenderer.title(document)
				if document.fragment_id != &"":
					label = "[%s] %s" % [document.fragment_id, label]
				if not GameState.documents_read.has(id):
					label = "\u2022 " + label
		var icon := UiStyle.PAPER_ICONS["cassette" if tab == Tab.TAPES else "folder"] as Texture2D
		var index := _list.add_item(label, icon)
		_list.set_item_metadata(index, id)
		_list.set_item_tooltip(index, label)
		if id == _selected_id:
			selected_index = index
	for i in _tabs.size():
		_tabs[i].set_pressed_no_signal(i == tab)
	_empty.visible = _list.item_count == 0
	_open_entry.visible = _list.item_count > 0
	if _list.item_count > 0:
		_list.select(selected_index)
		_select_entry(selected_index)
	else:
		_selected_id = ""
		_preview_title.text = ""
		_preview_body.text = ""
	_list.get_v_scroll_bar().set_value_no_signal(scroll)


func _select_entry(index: int) -> void:
	_selected_id = String(_list.get_item_metadata(index))
	if tab == Tab.TAPES:
		var tape := ContentDB.get_tape(_selected_id)
		_preview_title.text = tr(tape.title_key)
		_preview_body.text = tr("ui.files.tape_hint")
		_open_entry.text = "ui.files.play"
		_open_entry.icon = UiStyle.PAPER_ICONS["play"]
	else:
		var document := ContentDB.get_document(_selected_id)
		_preview_title.text = DocumentRenderer.title(document)
		_preview_body.text = DocumentRenderer.body(document)
		_open_entry.text = "ui.files.read"
		_open_entry.icon = UiStyle.PAPER_ICONS["eye"]


func _open_selected() -> void:
	var indices := _list.get_selected_items()
	if not indices.is_empty():
		_on_activate(indices[0])


func _on_activate(index: int) -> void:
	var id := String(_list.get_item_metadata(index))
	if tab == Tab.TAPES:
		EventBus.tape_requested.emit(StringName(id))
	else:
		EventBus.document_requested.emit(StringName(id))
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _open and is_instance_valid(_list):
		_refresh()
