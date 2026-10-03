extends Range
## One tuning range shared by a linear scale and coarse/fine rotary controls.
## Horizontal drag turns a knob; keyboard steps remain precise on every control.

signal tuning_released

enum Kind { SCALE, COARSE, FINE }

const KNOB := preload("res://assets/puzzles/radio-knob.svg")
const NEEDLE := preload("res://assets/puzzles/radio-needle.svg")
const INK := Color("292d2b")

var kind := Kind.SCALE
var easy_frequency := -1
var locked := false
var _dragging := false
var _drag_origin := Vector2.ZERO
var _drag_value := 0.0
var _hovered := false


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	mouse_entered.connect(
		func() -> void:
			_hovered = true
			queue_redraw()
	)
	mouse_exited.connect(
		func() -> void:
			_hovered = false
			queue_redraw()
	)
	value_changed.connect(func(_value: float) -> void: queue_redraw())


func _draw() -> void:
	if kind == Kind.SCALE:
		_draw_scale()
	else:
		draw_set_transform(size * 0.5, lerpf(deg_to_rad(-135), deg_to_rad(135), ratio))
		draw_texture_rect(KNOB, Rect2(-size * 0.5, size), false)
		draw_set_transform(Vector2.ZERO)
	if not locked and (has_focus() or _hovered):
		if kind == Kind.SCALE:
			draw_rect(Rect2(Vector2(0, 2), size - Vector2(0, 4)), INK, false, 2)
		else:
			draw_arc(size * 0.5, size.x * 0.5 - 1, 0, TAU, 64, UiStyle.ACCENT, 3, true)


func _draw_scale() -> void:
	var font := get_theme_default_font()
	for khz in range(550, 1701, 50):
		var x := _scale_x(khz)
		var major := khz % 200 == 0
		draw_line(Vector2(x, 40 if major else 52), Vector2(x, 69), INK, 2)
		if major:
			var number := str(khz)
			var width := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
			draw_string(font, Vector2(x - width * 0.5, 99), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, INK)
	if easy_frequency >= 0:
		var x := _scale_x(easy_frequency)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 7, 8), Vector2(x + 7, 8), Vector2(x, 21)]), INK)
	draw_texture_rect(NEEDLE, Rect2(_scale_x(value) - 6, 6, 12, 108), false)


func _scale_x(khz: float) -> float:
	return 14.0 + (khz - min_value) / (max_value - min_value) * (size.x - 28.0)


func _set_from_pointer(at: Vector2) -> void:
	if kind == Kind.SCALE:
		value = min_value + (at.x - 14.0) / (size.x - 28.0) * (max_value - min_value)
	else:
		value = _drag_value + (at.x - _drag_origin.x) * (1.0 if kind == Kind.FINE else 4.0)


func _gui_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			if event.pressed:
				grab_focus()
				_dragging = true
				_drag_origin = event.position
				_drag_value = value
				_set_from_pointer(event.position)
			elif _dragging:
				_dragging = false
				tuning_released.emit()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			grab_focus()
			value += 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
			accept_event()
			tuning_released.emit()
	elif event is InputEventMouseMotion and _dragging:
		_set_from_pointer(event.position)
		accept_event()
	elif event is InputEventKey:
		_handle_key(event)


func _handle_key(event: InputEventKey) -> void:
	var key := event.keycode
	if (
		key
		not in [
			KEY_LEFT,
			KEY_RIGHT,
			KEY_UP,
			KEY_DOWN,
			KEY_PAGEUP,
			KEY_PAGEDOWN,
			KEY_HOME,
			KEY_END,
			KEY_ENTER,
			KEY_KP_ENTER,
			KEY_SPACE
		]
	):
		return
	accept_event()
	if not event.pressed:
		tuning_released.emit()
		return
	match key:
		KEY_LEFT, KEY_DOWN:
			value -= 1
		KEY_RIGHT, KEY_UP:
			value += 1
		KEY_PAGEUP:
			value += 10
		KEY_PAGEDOWN:
			value -= 10
		KEY_HOME:
			value = min_value
		KEY_END:
			value = max_value
