extends PuzzleUi
## P18 close-up: the clock face. Turn the hands, then pull the chain.

var _face: Label


func _build_content() -> void:
	_face = UiStyle.label("", 120, UiStyle.ACCENT)
	_face.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_face.position = Vector2(560, 160)
	content.add_child(_face)
	var l := logic as P18Logic
	_hand_controls("puzzle.p18.hour", 200, l.turn_hour)
	_hand_controls("puzzle.p18.minute", 760, l.turn_minute)
	var pull := UiStyle.button("puzzle.p18.pull", _on_pull, 30)
	pull.position = Vector2(1300, 460)
	content.add_child(pull)


func _hand_controls(key: String, x: int, turn: Callable) -> void:
	var label := UiStyle.label(key, 26, UiStyle.INK_DIM)
	label.position = Vector2(x, 400)
	content.add_child(label)
	var minus := UiStyle.button("◀", _turn.bind(turn, -1), 34)
	minus.position = Vector2(x, 460)
	content.add_child(minus)
	var plus := UiStyle.button("▶", _turn.bind(turn, 1), 34)
	plus.position = Vector2(x + 140, 460)
	content.add_child(plus)


func _refresh() -> void:
	var l := logic as P18Logic
	_face.text = "%d:%02d" % [l.hour, l.minute]


func _turn(turn: Callable, step: int) -> void:
	turn.call(step)
	save_state()
	_refresh()


func _on_pull() -> void:
	attempt((logic as P18Logic).try_time(), "puzzle.p18.wrong")
