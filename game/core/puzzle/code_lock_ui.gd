extends PuzzleUi
## Shared close-up for CodeLockLogic puzzles (E05 lockbox, W03 desk padlock).

var _digits: Array[Label] = []


func _build_content() -> void:
	var l := logic as CodeLockLogic
	for i in l.digits():
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
	var open := UiStyle.button("puzzle.p04.pull", _on_open, 34)
	open.position = Vector2(300 + l.digits() * 220 + 60, 200)
	open.custom_minimum_size = Vector2(240, 110)
	content.add_child(open)


func _refresh() -> void:
	var l := logic as CodeLockLogic
	for i in _digits.size():
		_digits[i].text = str(l.wheels[i])


func _turn(i: int, step: int) -> void:
	(logic as CodeLockLogic).turn_wheel(i, step)
	save_state()
	_refresh()


func _on_open() -> void:
	attempt((logic as CodeLockLogic).try_open(), "puzzle.%s.wrong" % String(data.id).to_lower())
