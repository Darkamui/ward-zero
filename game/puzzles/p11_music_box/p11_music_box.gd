extends PuzzleUi
## P11 close-up: one pin per step (rows of note names), then wind.

var _cells: Array = []  # steps x notes Buttons


func _build_content() -> void:
	var l := logic as P11Logic
	for n in P11Logic.NOTES.size():
		var label := UiStyle.label("note.%s" % P11Logic.NOTES[n], 28)
		label.position = Vector2(0, 20 + n * 90)
		content.add_child(label)
	for step in l.length():
		var column := []
		for n in P11Logic.NOTES.size():
			var b := Button.new()
			b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			b.custom_minimum_size = Vector2(90, 70)
			b.position = Vector2(120 + step * 110, n * 90)
			b.pressed.connect(func() -> void: _toggle(step, n))
			content.add_child(b)
			column.append(b)
		_cells.append(column)
	var wind := UiStyle.button("puzzle.p11.play", _on_play, 30)
	wind.position = Vector2(120, 480)
	content.add_child(wind)


func _refresh() -> void:
	var l := logic as P11Logic
	for step in _cells.size():
		for n in P11Logic.NOTES.size():
			(_cells[step][n] as Button).text = "●" if l.pins[step] == n else "·"


func _toggle(step: int, note: int) -> void:
	var l := logic as P11Logic
	l.set_pin(step, -1 if l.pins[step] == note else note)
	save_state()
	_refresh()


func _on_play() -> void:
	attempt((logic as P11Logic).play(), "puzzle.p11.wrong")
