class_name DocumentViewer
extends CanvasLayer
## Shows a document on paper (EventBus.document_requested), in the current language,
## re-rendering live if the language changes. Marks it read. Click or Esc closes.

const UI_NAME := &"document"

var doc: DocumentData
var _root: Control
var _title: Label
var _body: Label


func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.document_requested.connect(open)


func open(document_id: StringName) -> void:
	var d: DocumentData = ContentDB.get_document(document_id)
	if d == null:
		push_error("DocumentViewer: unknown document %s" % document_id)
		return
	var was_open := doc != null
	doc = d
	GameState.add_document(String(d.id))
	GameState.mark_document_read(String(d.id))
	if not was_open:
		_build()
		EventBus.ui_opened.emit(UI_NAME)
	_render()


func close() -> void:
	if doc == null:
		return
	doc = null
	_root.queue_free()
	EventBus.ui_closed.emit(UI_NAME)


func is_open() -> bool:
	return doc != null


func shown_text() -> String:
	return _body.text if doc else ""


func _build() -> void:
	_root = Control.new()
	_root.theme = UiStyle.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.add_child(UiStyle.dimmer())
	var paper := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = UiStyle.PAPER
	style.set_content_margin_all(56)
	style.shadow_size = 18
	style.shadow_color = Color(0, 0, 0, 0.6)
	paper.add_theme_stylebox_override("panel", style)
	paper.custom_minimum_size = Vector2(1100, 760)
	paper.position = Vector2(410, 160)
	_root.add_child(paper)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	paper.add_child(box)
	_title = Label.new()
	_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_title.add_theme_color_override("font_color", UiStyle.PAPER_INK)
	box.add_child(_title)
	_body = Label.new()
	_body.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(988, 0)
	_body.add_theme_color_override("font_color", UiStyle.PAPER_INK)
	box.add_child(_body)


func _render() -> void:
	var font := UiStyle.font_for(doc.style)
	var size := 40 if font == UiStyle.HANDWRITTEN_FONT else 28
	_title.add_theme_font_override("font", UiStyle.TYPEWRITER_BOLD)
	_title.add_theme_font_size_override("font_size", 32)
	_body.add_theme_font_override("font", font)
	_body.add_theme_font_size_override("font_size", size)
	_title.text = DocumentRenderer.title(doc)
	_body.text = DocumentRenderer.body(doc)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and doc:
		_render()


func _input(event: InputEvent) -> void:
	if doc == null:
		return
	var close_it := false
	if event is InputEventMouseButton and event.pressed:
		close_it = true
	elif event.is_action_pressed(&"pause") or event.is_action_pressed(&"open_files"):
		close_it = true
	if close_it:
		get_viewport().set_input_as_handled()
		close()
