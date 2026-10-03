extends PuzzleUi
## P21 close-up: the timeline of my file, 1975 to 1998, and the fragments I hold. Closing
## the file always works; the number placed correctly decides the ending (stored in the
## "p21.score" flag for the finale).

var _slot := -1
var _slots: Array[Button] = []
var _pieces: Array[Button] = []
var _confirming := false


func _build_content() -> void:
	var l := logic as P21Logic
	l.available = GameState.fragments()
	l.available.sort()
	for i in P21Logic.TIMELINE.size():
		var b := UiStyle.button("", _select.bind(i), 18)
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(260, 100)
		b.position = Vector2((i % 6) * 280, (i / 6) * 120)
		content.add_child(b)
		_slots.append(b)
	for k in l.available.size():
		var b := UiStyle.button("", _put.bind(String(l.available[k])), 18)
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(260, 80)
		b.position = Vector2((k % 6) * 280, 280 + (k / 6) * 100)
		content.add_child(b)
		_pieces.append(b)
	var seal := UiStyle.button("puzzle.p21.seal", _on_seal, 30)
	seal.position = Vector2(0, 520)
	content.add_child(seal)


func _fragment_name(fragment: String) -> String:
	for item_id in GameState.key_pouch:
		var item: ItemData = ContentDB.get_item(item_id)
		if item != null and String(item.fragment_id) == fragment:
			return tr(item.name_key)
	return fragment


func _refresh() -> void:
	var l := logic as P21Logic
	for i in _slots.size():
		var f: String = l.slots[i]
		_slots[i].text = (
			("▶ " if i == _slot else "")
			+ str(P21Logic.YEARS[i])
			+ "\n"
			+ (tr("puzzle.p21.empty") if f == "" else _fragment_name(f))
		)
	for k in _pieces.size():
		var f := String(l.available[k])
		_pieces[k].text = _fragment_name(f)
		_pieces[k].visible = not l.slots.has(f)


func _select(i: int) -> void:
	var l := logic as P21Logic
	_confirming = false
	if _slot == i and l.slots[i] != "":
		l.place(i, "")
		_slot = -1
	else:
		_slot = i
	save_state()
	_refresh()


func _put(fragment: String) -> void:
	if _slot < 0 or logic.solved:
		return
	(logic as P21Logic).place(_slot, fragment)
	_slot = -1
	save_state()
	_refresh()


func _on_seal() -> void:
	if logic.solved:
		return
	if not _confirming:
		_confirming = true
		show_status("puzzle.p21.confirm")
		return
	var l := logic as P21Logic
	l.seal()
	GameState.set_flag("p21.score", l.score)
	attempt(true, "")
