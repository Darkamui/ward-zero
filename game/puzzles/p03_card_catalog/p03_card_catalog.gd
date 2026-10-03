extends PuzzleUi
## P03 card catalog close-up: month drawers, then the filing cabinets.

var _drawers: Dictionary = {}


func _build_content() -> void:
	for m in range(1, 13):
		var b := UiStyle.button("ui.month.%d" % m, _on_drawer.bind(m), 26)
		b.custom_minimum_size = Vector2(230, 80)
		b.position = Vector2(((m - 1) % 4) * 250, ((m - 1) / 4) * 100)
		content.add_child(b)
		_drawers[m] = b
	var cab := UiStyle.label("puzzle.p03.cabinets", 30, UiStyle.ACCENT)
	cab.position = Vector2(0, 340)
	content.add_child(cab)
	for n in range(1, 13):
		var b := Button.new()
		b.text = str(n)
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size = Vector2(110, 80)
		b.position = Vector2((n - 1) * 125, 400)
		b.pressed.connect(_on_cabinet.bind(n))
		content.add_child(b)


func _refresh() -> void:
	for m in _drawers:
		var opened: bool = (logic as P03Logic).opened_drawers.has(m)
		(_drawers[m] as Button).text = ("▣ " if opened else "") + tr("ui.month.%d" % m)


func _on_drawer(label_month: int) -> void:
	var l := logic as P03Logic
	var month := l.open_drawer(label_month)
	save_state()
	_refresh()
	if month == l.birth_month():
		show_status("puzzle.p03.card_found")
		EventBus.document_requested.emit(&"doc_catalog_card")
	else:
		show_status("puzzle.p03.drawer_contents", {"month": tr("ui.month.%d" % month)})


func _on_cabinet(n: int) -> void:
	attempt((logic as P03Logic).open_cabinet(n), "puzzle.p03.wrong_cabinet")
