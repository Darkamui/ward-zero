extends PuzzleUi
## Artwork stays blank; all station information comes from the seeded P01 logic.

const TuningControl := preload("res://game/puzzles/p01_radio/radio_tuning_control.gd")
const HOUSING := preload("res://assets/art/puzzle-bases/radio-housing.png")
const FACE_INK := Color("292d2b")

var _controls: Array[Range] = []
var _meter: ProgressBar
var _readout: Label
var _static: AudioStreamPlayer
var _next_detent_ms := 0


func _build_content() -> void:
	_static = AudioStreamPlayer.new()
	_static.bus = &"SFX"
	_static.stream = AudioDirector.looped(preload("res://assets/audio/radio_static_loop.wav"))
	add_child(_static)
	if not logic.solved:
		_static.play()
	# Photograph and controls share native-pixel coordinates.
	content.position = Vector2(192, 0)
	content.size = Vector2(1536, 1024)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var housing := TextureRect.new()
	housing.texture = HOUSING
	housing.position = content.position
	housing.size = content.size
	housing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(housing)
	move_child(housing, 0)
	_add_tuner(TuningControl.Kind.SCALE, Vector2(805, 364), Vector2(584, 122))
	_add_tuner(TuningControl.Kind.COARSE, Vector2(1053, 574), Vector2(128, 128))
	_add_tuner(TuningControl.Kind.FINE, Vector2(1251, 574), Vector2(128, 128))
	_face_label("puzzle.p01.tuning", Vector2(1017, 703), Vector2(200, 32))
	_face_label("puzzle.p01.fine", Vector2(1215, 703), Vector2(200, 32))
	_face_label("puzzle.p01.signal", Vector2(808, 518), Vector2(210, 32))
	_meter = ProgressBar.new()
	_meter.position = Vector2(826, 555)
	_meter.size = Vector2(174, 14)
	_meter.show_percentage = false
	_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := StyleBoxFlat.new()
	track.bg_color = Color("807762")
	track.set_border_width_all(1)
	track.border_color = FACE_INK
	var fill := StyleBoxFlat.new()
	fill.bg_color = FACE_INK
	_meter.add_theme_stylebox_override("background", track)
	_meter.add_theme_stylebox_override("fill", fill)
	content.add_child(_meter)
	_readout = _face_label("", Vector2(808, 595), Vector2(210, 40), 30)
	_readout.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var instructions := UiStyle.label("puzzle.p01.controls", 24, UiStyle.INK_DIM)
	instructions.position = Vector2(0, 895)
	instructions.size.x = 1536
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(instructions)
	_controls[0].grab_focus.call_deferred()


func _add_tuner(kind: int, at: Vector2, dimensions: Vector2) -> void:
	var tuner := TuningControl.new()
	tuner.kind = kind
	tuner.position = at
	tuner.size = dimensions
	tuner.min_value = P01Logic.DIAL_MIN
	tuner.max_value = P01Logic.DIAL_MAX
	tuner.step = 1.0
	tuner.easy_frequency = (logic as P01Logic).frequency() if params_easy() else -1
	tuner.value_changed.connect(_on_dial)
	tuner.tuning_released.connect(_on_release)
	content.add_child(tuner)
	_controls.append(tuner)


func _face_label(key: String, at: Vector2, dimensions: Vector2, font_size := 22) -> Label:
	var label := UiStyle.label(key, font_size, FACE_INK)
	label.position = at
	label.size = dimensions
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(label)
	return label


func params_easy() -> bool:
	return GameState.puzzle_difficulty == "easy"


func _refresh() -> void:
	var l := logic as P01Logic
	_static.volume_db = lerpf(-22.0, -50.0, l.signal_strength())
	if l.solved:
		_static.stop()
	_meter.value = l.signal_strength() * 100.0
	_readout.text = "%d kHz" % roundi(l.dial)
	for tuner in _controls:
		tuner.set_value_no_signal(l.dial)
		tuner.locked = l.solved
		tuner.queue_redraw()


func _on_dial(value: float) -> void:
	var now := Time.get_ticks_msec()
	if now >= _next_detent_ms and value != (logic as P01Logic).dial:
		AudioDirector.play_sfx(preload("res://assets/audio/radio_detent.wav"), -18.0)
		_next_detent_ms = now + 80
	(logic as P01Logic).set_dial(value)
	save_state()
	_refresh()


func _on_release() -> void:
	var l := logic as P01Logic
	if not l.solved and l.release():
		attempt(true, "")
