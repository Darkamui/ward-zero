extends PuzzleUi
## P06 close-up: pick a patient's drawer, then a pill from the tray. Pills are labelled
## with colour and shape in words plus a shape glyph (rule R5).

const GLYPHS := ["●", "⬭", "■", "▲", "⬮"]

var _patient := -1
var _drawers: Array[Button] = []
var _tray_buttons: Array[Button] = []


func _build_content() -> void:
	var l := logic as P06Logic
	for i in l.patient_count():
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size = Vector2(560, 70)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.position = Vector2(0, i * 86)
		b.pressed.connect(func() -> void: _select(i))
		content.add_child(b)
		_drawers.append(b)
	var tray := l.tray()
	for t in tray.size():
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size = Vector2(420, 64)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.position = Vector2(700 + (t % 2) * 440, (t / 2) * 80)
		b.text = pill_label(tray[t])
		b.pressed.connect(func() -> void: _put(t))
		content.add_child(b)
		_tray_buttons.append(b)
	var submit := UiStyle.button("puzzle.p06.submit", _on_submit, 30)
	submit.position = Vector2(700, 560)
	content.add_child(submit)


func pill_label(pill: Array) -> String:
	return (
		"%s  %s %s"
		% [
			GLYPHS[pill[1]],
			tr("pill.color.%s" % P06Logic.COLORS[pill[0]]),
			tr("pill.shape.%s" % P06Logic.SHAPES[pill[1]])
		]
	)


func _refresh() -> void:
	var l := logic as P06Logic
	var tray := l.tray()
	for i in _drawers.size():
		var pill_text := "—" if l.drawers[i] < 0 else pill_label(tray[l.drawers[i]])
		_drawers[i].text = "%s%s:  %s" % ["▶ " if i == _patient else "", P06Logic.PATIENTS[i], pill_text]


func _select(i: int) -> void:
	_patient = i
	_refresh()


func _put(tray_index: int) -> void:
	if _patient < 0:
		return
	(logic as P06Logic).assign(_patient, tray_index)
	_patient = -1
	save_state()
	_refresh()


func _on_submit() -> void:
	attempt((logic as P06Logic).submit(), "puzzle.p06.wrong")
