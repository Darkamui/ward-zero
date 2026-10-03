extends PuzzleUi
## P12 close-up: five cell doors. "Listen" replays the knocks; each knock also shakes dust
## from its door (the visual alternative to the sound, rule R6).

const BEAT := 0.9

var _doors: Array[Button] = []
var _playing := false


func _build_content() -> void:
	for d in P12Logic.DOORS:
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size = Vector2(260, 300)
		b.position = Vector2(d * 300, 0)
		b.add_theme_font_size_override("font_size", 30)
		b.pressed.connect(func() -> void: _open(d))
		content.add_child(b)
		_doors.append(b)
	var listen := UiStyle.button("puzzle.p12.listen", _demo, 30)
	listen.position = Vector2(0, 360)
	content.add_child(listen)
	_demo()


func _door_text(d: int, dust: bool) -> String:
	return "%s\n\n%s" % [tr("puzzle.p12.cell").format({"n": d + 1}), tr("puzzle.p12.dust") if dust else ""]


func _refresh() -> void:
	for d in _doors.size():
		_doors[d].text = _door_text(d, false)


func _demo() -> void:
	if _playing:
		return
	_playing = true
	(logic as P12Logic).progress = 0
	for d in (logic as P12Logic).sequence():
		if not is_inside_tree():
			return
		_doors[d].text = _door_text(d, true)
		await get_tree().create_timer(BEAT * 0.6).timeout
		if not is_inside_tree():
			return
		_doors[d].text = _door_text(d, false)
		await get_tree().create_timer(BEAT * 0.4).timeout
	_playing = false


func _open(d: int) -> void:
	if _playing:
		return
	var l := logic as P12Logic
	var ok := l.open(d)
	save_state()
	if not ok:
		attempt(false, "puzzle.p12.wrong")
	elif l.solved:
		attempt(true, "")
