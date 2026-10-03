extends PuzzleUi
## P13 close-up: three valves (− / +) and three gauges, each with its number and band in
## words (rule R5). Pushing a gauge into the red is loud.

var _settings: Array[Label] = []
var _gauges: Array[Label] = []
var _bars: Array[ProgressBar] = []


func _build_content() -> void:
	for v in 3:
		var minus := UiStyle.button("−", _turn.bind(v, -1), 34)
		minus.position = Vector2(v * 300, 0)
		content.add_child(minus)
		var label := UiStyle.label("0", 48)
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		label.position = Vector2(v * 300 + 90, 0)
		content.add_child(label)
		_settings.append(label)
		var plus := UiStyle.button("+", _turn.bind(v, 1), 34)
		plus.position = Vector2(v * 300 + 170, 0)
		content.add_child(plus)
	for g in 3:
		var label := UiStyle.label("", 28)
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		label.position = Vector2(0, 140 + g * 110)
		content.add_child(label)
		_gauges.append(label)
		var bar := ProgressBar.new()
		bar.max_value = 24
		bar.show_percentage = false
		bar.position = Vector2(0, 184 + g * 110)
		bar.size = Vector2(720, 30)
		content.add_child(bar)
		_bars.append(bar)


func _band(value: int) -> String:
	if value > P13Logic.RED_ABOVE:
		return tr("puzzle.p13.band_red")
	if value > P13Logic.GREEN_HIGH:
		return tr("puzzle.p13.band_high")
	if value < P13Logic.GREEN_LOW:
		return tr("puzzle.p13.band_low")
	return tr("puzzle.p13.band_green")


func _refresh() -> void:
	var l := logic as P13Logic
	var gauges := l.gauges()
	for v in 3:
		_settings[v].text = str(l.valves[v])
	for g in 3:
		_gauges[g].text = tr("puzzle.p13.gauge").format(
			{"n": g + 1, "v": gauges[g], "band": _band(gauges[g])}
		)
		_bars[g].value = clampi(gauges[g], 0, 24)


func _turn(v: int, step: int) -> void:
	var l := logic as P13Logic
	var ok := l.set_valve(v, l.valves[v] + step)
	save_state()
	_refresh()
	if not ok:
		attempt(false, "puzzle.p13.wrong")
	elif l.solved:
		attempt(true, "")
