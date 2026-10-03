extends PuzzleUi
## P02 switchboard close-up: click two jacks to patch them; click both ends of a patched
## link to unplug it. Each correct link shows a lit lamp with a ✓ (rule R5).

var _buttons: Dictionary = {}  # ext -> Button
var _selected := -1
var _links: Label
var _cables: Label
var _lines: Control


func _build_content() -> void:
	var l := logic as P02Logic
	var board := Panel.new()
	board.size = Vector2(980, 600)
	content.add_child(board)
	_lines = Control.new()
	_lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines.draw.connect(_draw_lines)
	var jacks := l.jacks()
	for i in jacks.size():
		var ext: int = jacks[i]
		var b := Button.new()
		b.text = str(ext)
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(200, 90)
		b.position = Vector2(60 + (i % 4) * 230, 50 + (i / 4) * 170)
		b.pressed.connect(_on_jack.bind(ext))
		board.add_child(b)
		_buttons[ext] = b
	board.add_child(_lines)
	_cables = UiStyle.label("", 28)
	_cables.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_cables.position = Vector2(1060, 0)
	content.add_child(_cables)
	_links = UiStyle.label("", 30)
	_links.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_links.position = Vector2(1060, 60)
	content.add_child(_links)
	var ring := UiStyle.button("puzzle.p02.ring", _on_ring, 34)
	ring.position = Vector2(1060, 480)
	ring.custom_minimum_size = Vector2(260, 90)
	content.add_child(ring)


func _refresh() -> void:
	var l := logic as P02Logic
	var lines := []
	for p in l.patches:
		var lamp := "● ✓" if l.link_correct(p) else "○"
		lines.append("%d — %d   %s" % [p[0], p[1], lamp])
	_links.text = "\n".join(lines)
	_cables.text = tr("puzzle.p02.cables").format({"n": l.cable_count() - l.patches.size()})
	for ext in _buttons:
		var b: Button = _buttons[ext]
		b.set_pressed_no_signal(ext == _selected)
		b.text = "%d%s" % [ext, " •".repeat(l.jack_load(ext))]
	_lines.queue_redraw()


func _on_jack(ext: int) -> void:
	var l := logic as P02Logic
	if _selected == -1:
		_selected = ext
	elif _selected == ext:
		_selected = -1
	else:
		if l.has_link(_selected, ext):
			l.unplug_link(_selected, ext)
		else:
			l.connect_jacks(_selected, ext)
		_selected = -1
	save_state()
	_refresh()


func _on_ring() -> void:
	attempt((logic as P02Logic).ring(), "puzzle.p02.wrong")


func _draw_lines() -> void:
	for p in (logic as P02Logic).patches:
		var a: Button = _buttons[p[0]]
		var b: Button = _buttons[p[1]]
		_lines.draw_line(a.position + a.size * 0.5, b.position + b.size * 0.5, UiStyle.ACCENT, 5.0, true)
