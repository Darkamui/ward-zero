class_name FilesUi
extends CanvasLayer
## Files (GDD §2.2, §11): the patient folder. Documents, tapes and truth fragments the
## player has found. Documents open in the DocumentViewer; tapes replay.

enum Tab { DOCUMENTS, TAPES, FRAGMENTS }

const UI_NAME := &"files"

var tab := Tab.DOCUMENTS
var _open := false
var _root: Control
var _list: ItemList


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
	_root.add_child(UiStyle.dimmer())
	var title := UiStyle.label("ui.files.title", 44, UiStyle.ACCENT)
	title.position = Vector2(120, 70)
	_root.add_child(title)
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(120, 150)
	tabs.add_theme_constant_override("separation", 14)
	_root.add_child(tabs)
	tabs.add_child(UiStyle.button("ui.files.documents", _set_tab.bind(Tab.DOCUMENTS)))
	tabs.add_child(UiStyle.button("ui.files.tapes", _set_tab.bind(Tab.TAPES)))
	tabs.add_child(UiStyle.button("ui.files.fragments", _set_tab.bind(Tab.FRAGMENTS)))
	_list = ItemList.new()
	_list.position = Vector2(120, 240)
	_list.size = Vector2(1100, 700)
	_list.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_list.item_activated.connect(_on_activate)
	_list.item_clicked.connect(func(i: int, _p: Vector2, _b: int) -> void: _on_activate(i))
	_root.add_child(_list)


func _set_tab(t: Tab) -> void:
	tab = t
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
	_list.clear()
	for id in entries():
		var label := id
		if tab == Tab.TAPES:
			var t: TapeData = ContentDB.get_tape(id)
			label = tr(t.title_key) if t else id
		else:
			var d: DocumentData = ContentDB.get_document(id)
			if d:
				label = DocumentRenderer.title(d)
				if d.fragment_id != &"":
					label = "[%s] %s" % [d.fragment_id, label]
				if not GameState.documents_read.has(id):
					label = "• " + label
		var idx := _list.add_item(label)
		_list.set_item_metadata(idx, id)


func _on_activate(i: int) -> void:
	var id := String(_list.get_item_metadata(i))
	if tab == Tab.TAPES:
		EventBus.tape_requested.emit(StringName(id))
	else:
		EventBus.document_requested.emit(StringName(id))
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _open:
		_refresh()
