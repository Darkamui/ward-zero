extends PuzzleUi
## P09 close-up: six frames and the drawings. Click a frame, then a drawing; "turn over"
## shows the dates on the backs (Easy: always shown).

var _frame := -1
var _frames: Array[Button] = []
var _pieces: Array[Button] = []
var _show_backs := false


func _build_content() -> void:
	var l := logic as P09Logic
	l.missing_available = GameState.get_flag("p09.drawing_found", false)
	_show_backs = bool(data.params_for(GameState.puzzle_difficulty).get("dates_on_front", false))
	for s in P09Logic.COUNT:
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size = Vector2(250, 120)
		b.position = Vector2(s * 270, 0)
		b.add_theme_font_size_override("font_size", 20)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func() -> void: _select(s))
		content.add_child(b)
		_frames.append(b)
	for p in P09Logic.COUNT:
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size = Vector2(250, 120)
		b.position = Vector2(p * 270, 220)
		b.add_theme_font_size_override("font_size", 20)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(func() -> void: _put(p))
		content.add_child(b)
		_pieces.append(b)
	var turn := UiStyle.button(
		"puzzle.p09.turn",
		func() -> void:
			_show_backs = not _show_backs
			_refresh()
	)
	turn.position = Vector2(0, 400)
	content.add_child(turn)
	var submit := UiStyle.button("puzzle.p09.submit", _on_submit, 30)
	submit.position = Vector2(400, 400)
	content.add_child(submit)
	if not l.missing_available:
		show_status("puzzle.p09.missing")


func _piece_text(p: int) -> String:
	var t := tr("puzzle.p09.drawing_%d" % p)
	if _show_backs:
		t += "\n" + tr("puzzle.p09.back").format({"date": (logic as P09Logic).date_of(p)})
	return t


func _refresh() -> void:
	var l := logic as P09Logic
	for s in _frames.size():
		var piece: int = l.slots[s]
		_frames[s].text = ("▶ " if s == _frame else "") + ("—" if piece < 0 else _piece_text(piece))
	var available := l.available_pieces()
	for p in _pieces.size():
		_pieces[p].visible = available.has(p) and not l.slots.has(p)
		_pieces[p].text = _piece_text(p)


func _select(s: int) -> void:
	if _frame == s and (logic as P09Logic).slots[s] >= 0:
		(logic as P09Logic).clear(s)
		_frame = -1
	else:
		_frame = s
	save_state()
	_refresh()


func _put(p: int) -> void:
	if _frame < 0:
		return
	(logic as P09Logic).place(_frame, p)
	_frame = -1
	save_state()
	_refresh()


func _on_submit() -> void:
	attempt((logic as P09Logic).submit(), "puzzle.p09.wrong")
