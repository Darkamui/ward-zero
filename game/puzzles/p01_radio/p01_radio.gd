extends PuzzleUi
## P01 radio close-up: drag the dial; the signal meter is the visual alternative to the
## static fading into the message (rule R6).

var _slider: HSlider
var _meter: ProgressBar


func _build_content() -> void:
	var l := logic as P01Logic
	var face := Panel.new()
	face.size = Vector2(1400, 420)
	face.position = Vector2(140, 80)
	content.add_child(face)
	for khz in range(600, 1700, 100):
		var tick := UiStyle.label(str(khz), 24, UiStyle.INK_DIM)
		tick.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		tick.position = Vector2(
			60 + (khz - P01Logic.DIAL_MIN) / (P01Logic.DIAL_MAX - P01Logic.DIAL_MIN) * 1240 - 20, 60
		)
		face.add_child(tick)
	var unit := UiStyle.label("kHz", 24, UiStyle.INK_DIM)
	unit.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	unit.position = Vector2(1320, 110)
	face.add_child(unit)
	_slider = HSlider.new()
	_slider.min_value = P01Logic.DIAL_MIN
	_slider.max_value = P01Logic.DIAL_MAX
	_slider.step = 1.0
	_slider.value = l.dial
	_slider.position = Vector2(60, 130)
	_slider.size = Vector2(1240, 60)
	_slider.value_changed.connect(_on_dial)
	_slider.drag_ended.connect(_on_release)
	face.add_child(_slider)
	if params_easy():
		var mark := UiStyle.label("▼", 34, UiStyle.ACCENT)
		mark.position = Vector2(
			60 + (l.frequency() - P01Logic.DIAL_MIN) / (P01Logic.DIAL_MAX - P01Logic.DIAL_MIN) * 1240 - 10, 92
		)
		face.add_child(mark)
	var sig := UiStyle.label("puzzle.p01.signal", 26)
	sig.position = Vector2(60, 250)
	face.add_child(sig)
	_meter = ProgressBar.new()
	_meter.min_value = 0
	_meter.max_value = 100
	_meter.show_percentage = false
	_meter.position = Vector2(220, 252)
	_meter.size = Vector2(600, 36)
	face.add_child(_meter)


func params_easy() -> bool:
	return GameState.puzzle_difficulty == "easy"


func _refresh() -> void:
	_meter.value = (logic as P01Logic).signal_strength() * 100.0


func _on_dial(v: float) -> void:
	(logic as P01Logic).set_dial(v)
	_refresh()


func _on_release(_changed: bool) -> void:
	var l := logic as P01Logic
	save_state()
	if l.release():
		attempt(true, "")
