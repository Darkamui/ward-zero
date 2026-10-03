class_name OrderingUi
extends PuzzleUi
## Close-up for OrderingLogic puzzles (P14 shelf, P16 carousel): a row of slots and the
## loose pieces. Click a slot, then a piece; click a filled slot again to empty it.

var _slot := -1
var _slots: Array[Button] = []
var _pieces: Array[Button] = []


## Override: label for piece p.
func piece_text(p: int) -> String:
	return str(p)


## Override: label for an empty slot.
func slot_text(_s: int) -> String:
	return "—"


func submit_key() -> String:
	return "puzzle.%s.submit" % String(data.id).to_lower()


func wrong_key() -> String:
	return "puzzle.%s.wrong" % String(data.id).to_lower()


func _build_content() -> void:
	var l := logic as OrderingLogic
	var w := mini(250, int(1680.0 / l.count()) - 20)
	for s in l.count():
		_slots.append(_tile(Vector2(s * (w + 20), 0), w, _select.bind(s)))
	for p in l.count():
		_pieces.append(_tile(Vector2(p * (w + 20), 240), w, _put.bind(p)))
	var submit := UiStyle.button(submit_key(), _on_submit, 30)
	submit.position = Vector2(0, 440)
	content.add_child(submit)


func _tile(pos: Vector2, width: int, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.custom_minimum_size = Vector2(width, 140)
	b.position = pos
	b.add_theme_font_size_override("font_size", 20)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(on_pressed)
	content.add_child(b)
	return b


func _refresh() -> void:
	var l := logic as OrderingLogic
	for s in _slots.size():
		var piece: int = l.slots[s]
		_slots[s].text = ("▶ " if s == _slot else "") + (slot_text(s) if piece < 0 else piece_text(piece))
	for p in _pieces.size():
		_pieces[p].visible = not l.slots.has(p)
		_pieces[p].text = piece_text(p)


func _select(s: int) -> void:
	var l := logic as OrderingLogic
	if _slot == s and l.slots[s] >= 0:
		l.clear(s)
		_slot = -1
	else:
		_slot = s
	save_state()
	_refresh()


func _put(p: int) -> void:
	if _slot < 0:
		return
	(logic as OrderingLogic).place(_slot, p)
	_slot = -1
	save_state()
	_refresh()


func _on_submit() -> void:
	attempt((logic as OrderingLogic).submit(), wrong_key())
