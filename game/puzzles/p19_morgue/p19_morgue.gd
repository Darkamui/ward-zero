extends PuzzleUi
## P19 close-up: the wall of twelve drawers. Wrong drawers rattle (noise).

var _drawers: Array[Button] = []


func _build_content() -> void:
	for n in range(1, P19Logic.DRAWERS + 1):
		var b := UiStyle.button(str(n), _open.bind(n), 34)
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size = Vector2(240, 150)
		b.position = Vector2(((n - 1) % 4) * 270, ((n - 1) / 4) * 180)
		content.add_child(b)
		_drawers.append(b)


func _refresh() -> void:
	var l := logic as P19Logic
	for i in _drawers.size():
		var n := i + 1
		_drawers[i].text = ("[%d]" % n) if l.opened.has(n) else str(n)


func _open(n: int) -> void:
	attempt((logic as P19Logic).open_drawer(n), "puzzle.p19.wrong")
