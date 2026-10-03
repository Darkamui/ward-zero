extends PuzzleUi
## P08 close-up: twelve folded sheets; pulling one shows its tag. Wrong pulls are loud.

var _sheets: Array[Button] = []


func _build_content() -> void:
	for i in P08Logic.SHEETS:
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size = Vector2(240, 110)
		b.position = Vector2((i % 6) * 260, (i / 6) * 140)
		b.pressed.connect(func() -> void: _pull(i))
		content.add_child(b)
		_sheets.append(b)


func _refresh() -> void:
	var l := logic as P08Logic
	for i in _sheets.size():
		_sheets[i].text = l.tag(i) if l.pulled.has(i) else "▤"


func _pull(i: int) -> void:
	var ok := (logic as P08Logic).pull(i)
	_refresh()
	attempt(ok, "puzzle.p08.wrong")
