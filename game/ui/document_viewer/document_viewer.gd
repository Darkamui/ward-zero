class_name DocumentViewer
extends CanvasLayer
## Localized live text over supplied paper. Scroll and enlarge without closing the reader.

const UI_NAME := &"document"
const PAPER := preload("res://assets/art/ui/paper.png")

var doc: DocumentData
var _root: Control
var _title: Label
var _body: Label
var _scroll: ScrollContainer
var _font_step := 0
var _previous_focus: Control


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
	AudioDirector.play_sfx(AudioDirector.PAPER, -8.0, &"UI")
	GameState.add_document(String(d.id))
	GameState.mark_document_read(String(d.id))
	if not was_open:
		_previous_focus = get_viewport().gui_get_focus_owner()
		_build()
		EventBus.ui_opened.emit(UI_NAME)
	_scroll.scroll_vertical = 0
	_render()


func close() -> void:
	if doc == null:
		return
	doc = null
	_root.queue_free()
	EventBus.ui_closed.emit(UI_NAME)
	if is_instance_valid(_previous_focus):
		_previous_focus.grab_focus.call_deferred()


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
	var paper := TextureRect.new()
	paper.texture = PAPER
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	paper.position = Vector2(620, 0)
	paper.size = Vector2(680, 1020)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(paper)
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(688, 115)
	_scroll.size = Vector2(548, 780)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.focus_mode = Control.FOCUS_ALL
	_root.add_child(_scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 32)
	_scroll.add_child(box)
	_title = Label.new()
	_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_color_override("font_color", UiStyle.PAPER_INK)
	box.add_child(_title)
	_body = Label.new()
	_body.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_color_override("font_color", UiStyle.PAPER_INK)
	box.add_child(_body)
	var toolbar := VBoxContainer.new()
	toolbar.position = Vector2(1360, 160)
	toolbar.add_theme_constant_override("separation", 16)
	_root.add_child(toolbar)
	toolbar.add_child(UiStyle.button("ui.document.larger", change_text_size.bind(1)))
	toolbar.add_child(UiStyle.button("ui.document.smaller", change_text_size.bind(-1)))
	toolbar.add_child(UiStyle.button("ui.common.back", close))
	var hint := UiStyle.label("ui.document.controls", 24, UiStyle.INK_DIM)
	hint.position = Vector2(620, 1020)
	hint.size.x = 680
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(hint)
	_scroll.grab_focus.call_deferred()


func change_text_size(direction: int) -> void:
	_font_step = clampi(_font_step + direction, 0, 4)
	_render()


func _render() -> void:
	var font := UiStyle.font_for(doc.style)
	var base_size := 40 if font == UiStyle.HANDWRITTEN_FONT else 28
	_title.add_theme_font_override("font", UiStyle.TYPEWRITER_BOLD)
	_title.add_theme_font_size_override("font_size", 34 + _font_step * 2)
	_body.add_theme_font_override("font", font)
	_body.add_theme_font_size_override("font_size", base_size + _font_step * 4)
	_title.text = DocumentRenderer.title(doc)
	_body.text = DocumentRenderer.body(doc)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and doc and is_instance_valid(_body):
		_render()


func _input(event: InputEvent) -> void:
	if doc == null:
		return
	if (
		event.is_action_pressed(&"pause")
		or event.is_action_pressed(&"open_files")
		or InventoryUi._is_right_click(event)
	):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				change_text_size(1)
				get_viewport().set_input_as_handled()
			KEY_MINUS, KEY_KP_SUBTRACT:
				change_text_size(-1)
				get_viewport().set_input_as_handled()
			KEY_PAGEDOWN, KEY_PAGEUP:
				_scroll.scroll_vertical += 600 if event.keycode == KEY_PAGEDOWN else -600
				get_viewport().set_input_as_handled()
