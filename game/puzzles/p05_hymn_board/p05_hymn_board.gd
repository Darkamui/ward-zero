extends PuzzleUi
## P05 hymn board close-up: select a slot, then a number card. Right-click a slot to put
## its card back in the tray.

var _slots: Array = []  # rows x 3 Buttons
var _sel := Vector2i(-1, -1)


func _build_content() -> void:
	var l := logic as P05Logic
	var board := Panel.new()
	board.size = Vector2(560, 120 + l.rows() * 130)
	board.position = Vector2(80, 0)
	content.add_child(board)
	for r in l.rows():
		var row := []
		for c in 3:
			var b := Button.new()
			b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			b.custom_minimum_size = Vector2(130, 110)
			b.position = Vector2(60 + c * 150, 60 + r * 130)
			b.add_theme_font_size_override("font_size", 56)
			b.pressed.connect(_on_slot.bind(r, c))
			b.gui_input.connect(_on_slot_input.bind(r, c))
			board.add_child(b)
			row.append(b)
		_slots.append(row)
	for d in 10:
		var card := Button.new()
		card.text = str(d)
		card.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		card.custom_minimum_size = Vector2(90, 110)
		card.position = Vector2(760 + (d % 5) * 110, 40 + (d / 5) * 130)
		card.add_theme_font_size_override("font_size", 48)
		card.pressed.connect(_on_card.bind(d))
		content.add_child(card)
	var submit := UiStyle.button("puzzle.p05.submit", _on_submit, 30)
	submit.position = Vector2(760, 360)
	content.add_child(submit)


func _refresh() -> void:
	var l := logic as P05Logic
	for r in _slots.size():
		for c in 3:
			var v: int = l.board[r][c]
			var b: Button = _slots[r][c]
			b.text = "_" if v < 0 else str(v)
			if Vector2i(r, c) == _sel:
				b.text = "[" + b.text + "]"


func _on_slot(r: int, c: int) -> void:
	_sel = Vector2i(r, c)
	_refresh()


func _on_slot_input(event: InputEvent, r: int, c: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		(logic as P05Logic).clear(r, c)
		save_state()
		_refresh()
		accept_event()


func _on_card(d: int) -> void:
	if _sel.x < 0:
		return
	(logic as P05Logic).place(_sel.x, _sel.y, d)
	_sel = Vector2i(_sel.x, _sel.y + 1) if _sel.y < 2 else Vector2i(-1, -1)
	save_state()
	_refresh()


func _on_submit() -> void:
	attempt((logic as P05Logic).submit(), "puzzle.p05.wrong")
