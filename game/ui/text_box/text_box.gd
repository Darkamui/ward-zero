class_name TextBox
extends CanvasLayer
## Examine / message text at the bottom of the screen. Listens to EventBus.text_requested.
## Click, Space, Enter or right-click advances; queued messages show in order.

const UI_NAME := &"text_box"

var _queue: Array[String] = []
var _open := false
var _panel: PanelContainer
var _label: Label


func _ready() -> void:
	layer = 10
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.15
	_panel.anchor_right = 0.85
	_panel.anchor_top = 0.80
	_panel.anchor_bottom = 0.95
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.03, 0.85)
	style.set_content_margin_all(24)
	_panel.add_theme_stylebox_override("panel", style)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 30)
	_label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.85))
	_panel.add_child(_label)
	add_child(_panel)
	_panel.visible = false
	EventBus.text_requested.connect(show_key)


func show_key(key: String) -> void:
	_queue.append(key)
	if not _open:
		_open = true
		EventBus.ui_opened.emit(UI_NAME)
		_next()


func is_open() -> bool:
	return _open


func current_text() -> String:
	return _label.text if _open else ""


func _next() -> void:
	if _queue.is_empty():
		_panel.visible = false
		_open = false
		EventBus.ui_closed.emit(UI_NAME)
		return
	_label.text = tr(_queue.pop_front())
	_panel.visible = true


func _input(event: InputEvent) -> void:
	if not _open:
		return
	var advance := false
	if event is InputEventMouseButton and event.pressed:
		advance = event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]
	elif event is InputEventKey and event.pressed and not event.echo:
		advance = event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]
	if advance:
		get_viewport().set_input_as_handled()
		_next()
