extends PuzzleUi
## P04 wall safe close-up: four number wheels and a handle.

var _digits: Array[Label] = []


func _build_content() -> void:
	var easy := GameState.puzzle_difficulty == "easy"
	for i in 4:
		var x := 300 + i * 220
		var up := UiStyle.button("▲", _turn.bind(i, 1), 34)
		up.position = Vector2(x, 60)
		up.custom_minimum_size = Vector2(150, 80)
		content.add_child(up)
		var d := UiStyle.label("0", 96)
		d.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		d.position = Vector2(x + 45, 160)
		content.add_child(d)
		_digits.append(d)
		var down := UiStyle.button("▼", _turn.bind(i, -1), 34)
		down.position = Vector2(x, 320)
		down.custom_minimum_size = Vector2(150, 80)
		content.add_child(down)
		if easy and i < 2:
			var shown := UiStyle.label(str((logic as P04Logic).code()[i]), 30, UiStyle.INK_DIM)
			shown.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			shown.position = Vector2(x + 62, 420)
			content.add_child(shown)
	var pull := UiStyle.button("puzzle.p04.pull", _on_pull, 34)
	pull.position = Vector2(1250, 200)
	pull.custom_minimum_size = Vector2(240, 110)
	content.add_child(pull)


func _refresh() -> void:
	for i in 4:
		_digits[i].text = str((logic as P04Logic).wheels[i])


func _turn(i: int, step: int) -> void:
	(logic as P04Logic).turn_wheel(i, step)
	save_state()
	_refresh()


func _on_pull() -> void:
	attempt((logic as P04Logic).pull(), "puzzle.p04.wrong")
