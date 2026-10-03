extends PuzzleUi
## P20 close-up: four keyholes labelled with seasons (Easy adds their elements). Click a
## keyhole, then a temperament key. Needs all four keys in the pouch.

var _slot := -1
var _slots: Array[Button] = []
var _keys: Array[Button] = []
var _has_keys := true


func _build_content() -> void:
	for k in P20Logic.KEYS:
		if not GameState.has_item("item_%s_key" % k):
			_has_keys = false
	if not _has_keys:
		show_status("puzzle.p20.need_keys")
		return
	for s in 4:
		var b := UiStyle.button("", _select.bind(s), 24)
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size = Vector2(360, 160)
		b.position = Vector2(s * 400, 0)
		content.add_child(b)
		_slots.append(b)
	for k in 4:
		var b := UiStyle.button("temperament.%s" % P20Logic.KEYS[k], _put.bind(k), 24)
		b.custom_minimum_size = Vector2(360, 90)
		b.position = Vector2(k * 400, 260)
		content.add_child(b)
		_keys.append(b)
	var turn := UiStyle.button("puzzle.p20.turn", _on_turn, 30)
	turn.position = Vector2(0, 440)
	content.add_child(turn)


func _slot_label(s: int) -> String:
	var l := logic as P20Logic
	var season := l.slot_season(s)
	var t := tr("season.%s" % P20Logic.SEASONS[season])
	if bool(data.params_for(GameState.puzzle_difficulty).get("elements", false)):
		t += " (%s)" % tr("element.%s" % P20Logic.ELEMENTS[season])
	var key: int = l.slots[s]
	if key >= 0:
		t += "\n" + tr("temperament.%s" % P20Logic.KEYS[key])
	return ("▶ " if s == _slot else "") + t


func _refresh() -> void:
	var l := logic as P20Logic
	for s in _slots.size():
		_slots[s].text = _slot_label(s)
	for k in _keys.size():
		_keys[k].visible = not l.slots.has(k)


func _select(s: int) -> void:
	var l := logic as P20Logic
	if _slot == s and l.slots[s] >= 0:
		l.place(s, -1)
		_slot = -1
	else:
		_slot = s
	save_state()
	_refresh()


func _put(k: int) -> void:
	if _slot < 0:
		return
	(logic as P20Logic).place(_slot, k)
	_slot = -1
	save_state()
	_refresh()


func _on_turn() -> void:
	if _has_keys:
		attempt((logic as P20Logic).submit(), "puzzle.p20.wrong")
