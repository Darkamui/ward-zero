extends PuzzleUi
## P07 close-up: tub levels with their marks (numbers, not colour), and the valve actions.

const NAMES := ["A", "B", "C", "D"]

var _bars: Array[ProgressBar] = []
var _labels: Array[Label] = []


func _build_content() -> void:
	var l := logic as P07Logic
	var n := l.caps().size()
	for i in n:
		var label := UiStyle.label("", 28)
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		label.position = Vector2(0, i * 110)
		content.add_child(label)
		_labels.append(label)
		var bar := ProgressBar.new()
		bar.max_value = l.caps()[i]
		bar.step = 1
		bar.show_percentage = false
		bar.position = Vector2(0, i * 110 + 44)
		bar.size = Vector2(620, 34)
		content.add_child(bar)
		_bars.append(bar)
	var ops := VBoxContainer.new()
	ops.position = Vector2(760, 0)
	content.add_child(ops)
	for a in n:
		for b in n:
			if a != b:
				ops.add_child(
					_op_button(tr("puzzle.p07.pour").format({"a": NAMES[a], "b": NAMES[b]}), ["pour", a, b])
				)
	for a in n:
		ops.add_child(_op_button(tr("puzzle.p07.drain").format({"a": NAMES[a]}), ["drain", a]))
		if l.has_tap():
			ops.add_child(_op_button(tr("puzzle.p07.fill").format({"a": NAMES[a]}), ["fill", a]))
	ops.add_child(_op_button(tr("puzzle.p07.reset"), ["reset"]))


func _op_button(text: String, op: Array) -> Button:
	var b := Button.new()
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.text = text
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(func() -> void: _do(op))
	return b


func _refresh() -> void:
	var l := logic as P07Logic
	for i in _bars.size():
		_bars[i].value = l.levels[i]
		_labels[i].text = tr("puzzle.p07.tub").format(
			{"a": NAMES[i], "n": l.levels[i], "cap": l.caps()[i], "mark": l.goal()[i]}
		)


func _do(op: Array) -> void:
	var l := logic as P07Logic
	l.levels = l._apply(l.levels, op)
	save_state()
	_refresh()
	if l.check():
		attempt(true, "")
