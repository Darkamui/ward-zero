extends PuzzleUi
## P15 close-up: the pharmacy scale. Each weight sits off the scale or on a pan (the left
## pan, beside the substance, only on Hard). Easy shows the running total on the dial.

var _rows: Array[Label] = []
var _total: Label


func _build_content() -> void:
	var l := logic as P15Logic
	var w: Array = l.weights()
	for i in w.size():
		var y := i * 100
		var weight_label := UiStyle.label("%d g" % int(w[i]), 34)
		weight_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		weight_label.position = Vector2(0, y + 10)
		content.add_child(weight_label)
		var positions := [[-1, "puzzle.p15.left"], [0, "puzzle.p15.off"], [1, "puzzle.p15.right"]]
		for k in positions.size():
			if positions[k][0] == -1 and not l.two_pans():
				continue
			var b := UiStyle.button(positions[k][1], _place.bind(i, positions[k][0]), 26)
			b.position = Vector2(160 + k * 220, y)
			b.custom_minimum_size = Vector2(200, 70)
			content.add_child(b)
		var state := UiStyle.label("", 28, UiStyle.INK_DIM)
		state.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		state.position = Vector2(860, y + 14)
		content.add_child(state)
		_rows.append(state)
	_total = UiStyle.label("", 34, UiStyle.ACCENT)
	_total.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_total.position = Vector2(1150, 100)
	content.add_child(_total)
	var weigh := UiStyle.button("puzzle.p15.weigh", _on_weigh, 30)
	weigh.position = Vector2(1150, 220)
	content.add_child(weigh)


func _refresh() -> void:
	var l := logic as P15Logic
	for i in _rows.size():
		_rows[i].text = ["◀", "·", "▶"][int(l.placement[i]) + 1]
	var show_total := bool(data.params_for(GameState.puzzle_difficulty).get("show_total", false))
	_total.text = tr("puzzle.p15.total").format({"g": l.total()}) if show_total else ""


func _place(i: int, pan: int) -> void:
	(logic as P15Logic).set_weight(i, pan)
	save_state()
	_refresh()


func _on_weigh() -> void:
	attempt((logic as P15Logic).weigh(), "puzzle.p15.wrong")
