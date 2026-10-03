extends RefCounted
## Bootstraps Act 1 data resources (items, documents, tapes, puzzles) as .tres files.
##   godot --headless res://tools/run_tool.tscn -- res://tools/content/build_act1_data.gd [--force]
## Existing files are kept unless --force: after the first run, edit them in the editor.

const DATA := "res://game/data"

var force := false
var written := 0
var kept := 0


func run(_tree: SceneTree, args: PackedStringArray) -> int:
	force = args.has("--force")
	_items()
	_documents()
	_tapes()
	_puzzles()
	print("build_act1_data: %d written, %d kept" % [written, kept])
	return 0


# --- Items --------------------------------------------------------------------


func _items() -> void:
	_item("item_dictaphone", "dictaphone", ItemData.Storage.KEY_POUCH, ItemData.Kind.TOOL)
	var wristband := _item(
		"item_wristband", "wristband", ItemData.Storage.KEY_POUCH, ItemData.Kind.TOOL, false
	)
	var reveal := ExamineReveal.new()
	reveal.view_direction = Vector3.FORWARD
	reveal.adds_document = &"doc_wristband_note"
	wristband.examine_reveals = [reveal]
	_save_item(wristband)
	_item("item_photograph", "photograph", ItemData.Storage.KEY_POUCH, ItemData.Kind.ANCHOR)
	_item("item_choleric_key", "choleric_key", ItemData.Storage.KEY_POUCH, ItemData.Kind.KEY)
	_item("item_music_box_crank", "music_box_crank", ItemData.Storage.SLOT, ItemData.Kind.TOOL)
	var f01 := _item(
		"item_f01_admission_file",
		"f01_admission_file",
		ItemData.Storage.KEY_POUCH,
		ItemData.Kind.FRAGMENT,
		false
	)
	f01.fragment_id = &"F01"
	_save_item(f01)
	var f02 := _item(
		"item_f02_fire_clipping",
		"f02_fire_clipping",
		ItemData.Storage.KEY_POUCH,
		ItemData.Kind.FRAGMENT,
		false
	)
	f02.fragment_id = &"F02"
	_save_item(f02)


func _item(id: String, key: String, storage: ItemData.Storage, kind: ItemData.Kind, save := true) -> ItemData:
	var it := ItemData.new()
	it.id = StringName(id)
	it.name_key = "item.%s.name" % key
	it.desc_key = "item.%s.desc" % key
	it.storage = storage
	it.kind = kind
	it.droppable = storage == ItemData.Storage.SLOT and kind != ItemData.Kind.KEY
	if save:
		_save_item(it)
	return it


func _save_item(it: ItemData) -> void:
	_save(it, "%s/items/%s.tres" % [DATA, it.id])


# --- Documents ----------------------------------------------------------------


func _documents() -> void:
	_doc("doc_quiet_hours", "quiet_hours", DocumentData.Style.NOTICE, {"frequency": "puzzle:P01.frequency"})
	var dir := {}
	for role in P02Logic.ALL_ROLES:
		dir["ext_" + role] = "puzzle:P02.ext_" + role
	_doc("doc_staff_directory", "staff_directory", DocumentData.Style.PRINT, dir)
	_doc("doc_desk_memo", "desk_memo", DocumentData.Style.HANDWRITTEN, {})
	_doc(
		"doc_founding_plaque",
		"founding_plaque",
		DocumentData.Style.PRINT,
		{"year": "puzzle:P04.founding_year"}
	)
	_doc("doc_cipher_memo", "cipher_memo", DocumentData.Style.TYPEWRITER, {"shift": "puzzle:P04.shift"})
	_doc(
		"doc_wristband_note", "wristband_note", DocumentData.Style.NOTE, {"birthdate": "puzzle:P03.birthdate"}
	)
	_doc(
		"doc_catalog_card",
		"catalog_card",
		DocumentData.Style.NOTE,
		{"birthdate": "puzzle:P03.birthdate", "cabinet": "puzzle:P03.cabinet"}
	)
	_doc(
		"doc_f01_admission_file",
		"f01_admission_file",
		DocumentData.Style.TYPEWRITER,
		{"birthdate": "puzzle:P03.birthdate"},
		&"F01"
	)
	_doc(
		"doc_f02_fire_clipping",
		"f02_fire_clipping",
		DocumentData.Style.PRINT,
		{"fire_time": "puzzle:P18.fire_time"},
		&"F02"
	)
	_doc(
		"doc_hymn_board_1976",
		"hymn_board_1976",
		DocumentData.Style.NOTE,
		{"h1": "puzzle:P05.hymns[0]", "h2": "puzzle:P05.hymns[1]", "h3": "puzzle:P05.hymns[2]"}
	)
	_doc("doc_visitor_notice", "visitor_notice", DocumentData.Style.NOTICE, {})
	_doc("doc_hymnal_page", "hymnal_page", DocumentData.Style.PRINT, {})


func _doc(
	id: String, key: String, style: DocumentData.Style, placeholders: Dictionary, fragment := &""
) -> void:
	var d := DocumentData.new()
	d.id = StringName(id)
	d.title_key = "doc.%s.title" % key
	d.body_key = "doc.%s.body" % key
	d.style = style
	d.fragment_id = fragment
	for k in placeholders:
		d.placeholders[StringName(k)] = placeholders[k]
	_save(d, "%s/documents/%s.tres" % [DATA, id])


# --- Tapes --------------------------------------------------------------------


func _tapes() -> void:
	_tape("tape_01_claire", "01_claire", [[0.5, 3.0], [3.5, 7.0]], true)
	_tape("vo_p01_radio", "vo_p01_radio", [[0.3, 4.5], [4.8, 6.5]], false)


func _tape(id: String, key: String, timings: Array, listed: bool) -> void:
	var t := TapeData.new()
	t.id = StringName(id)
	t.title_key = "tape.%s.title" % key
	t.listed_in_files = listed
	for i in timings.size():
		var line := SubLine.new()
		line.start = timings[i][0]
		line.end = timings[i][1]
		line.key = "tape.%s.line%d" % [key, i + 1]
		t.subtitles.append(line)
	_save(t, "%s/tapes/%s.tres" % [DATA, id])


# --- Puzzles ------------------------------------------------------------------


func _puzzles() -> void:
	var p01 := _puzzle("P01", "G01", "p01_radio", P01Logic, 0, &"p01.solved")
	p01.seed_fields = [_field("frequency", SeedField.Kind.STEPPED, 550, 1600, 10)]
	p01.rewards = [_set_flag("g01.chain_released"), _play_tape("vo_p01_radio")]
	_save_puzzle(p01)

	var p02 := _puzzle("P02", "G03", "p02_switchboard", P02Logic, 1, &"p02.solved")
	p02.seed_fields = [
		_field("extensions", SeedField.Kind.UNIQUE_INTS, 200, 899, 1, P02Logic.ALL_ROLES.size())
	]
	var decoys := ["records", "chaplain", "kitchen", "pharmacy", "director"]
	p02.params = {
		"easy": {"route": ["reception", "night_desk", "administrator"], "decoys": decoys},
		"normal": {"route": ["reception", "night_desk", "relay", "administrator"], "decoys": decoys},
		"hard": {"route": ["reception", "night_desk", "relay", "records", "administrator"], "decoys": decoys},
	}
	p02.rewards = [_set_flag("g02.gate_open")]
	_save_puzzle(p02)

	var p03 := _puzzle("P03", "G04", "p03_card_catalog", P03Logic, 1, &"p03.solved")
	p03.seed_fields = [
		_field("birth_day", SeedField.Kind.INT, 1, 28),
		_field("birth_month", SeedField.Kind.INT, 1, 12),
		_field("cabinet", SeedField.Kind.INT, 1, 12),
		_field("swap_offset", SeedField.Kind.INT, 1, 11),
	]
	p03.params = {"easy": {"swapped": false}, "normal": {"swapped": true}, "hard": {"swapped": true}}
	p03.rewards = [
		_give("item_f01_admission_file"), _open_doc("doc_f01_admission_file"), _give("item_photograph")
	]
	_save_puzzle(p03)

	var p04 := _puzzle("P04", "G05", "p04_wall_safe", P04Logic, 1, &"p04.solved")
	p04.seed_fields = [
		_field("founding_year", SeedField.Kind.INT, 1890, 1925), _field("shift", SeedField.Kind.INT, 1, 9)
	]
	p04.params = {"easy": {}, "normal": {}, "hard": {"reverse": true}}
	p04.rewards = [
		_give("item_choleric_key"), _give("item_f02_fire_clipping"), _open_doc("doc_f02_fire_clipping")
	]
	_save_puzzle(p04)

	var p05 := _puzzle("P05", "G06", "p05_hymn_board", P05Logic, 1, &"p05.solved")
	p05.seed_fields = [_field("hymns", SeedField.Kind.UNIQUE_INTS, 100, 699, 1, 3)]
	p05.params = {"easy": {"rows": 2}, "normal": {"rows": 3}, "hard": {"rows": 3}}
	p05.rewards = [_set_flag("g06.loft_open")]
	_save_puzzle(p05)

	var p18 := _puzzle("P18", "U06", "p18_grandfather_clock", P18Logic, 1, &"p18.solved")
	p18.seed_fields = [
		_field("fire_hour", SeedField.Kind.INT, 1, 4), _field("fire_minute", SeedField.Kind.STEPPED, 0, 55, 5)
	]
	_save_puzzle(p18)


func _puzzle(
	id: String, room: String, dir_name: String, logic: Script, noise: int, flag: StringName
) -> PuzzleData:
	var p := PuzzleData.new()
	p.id = StringName(id)
	p.room_id = StringName(room)
	p.name_key = "puzzle.%s.name" % id.to_lower()
	p.logic_script = logic
	var scene_path := "res://game/puzzles/%s/%s.tscn" % [dir_name, id.to_lower()]
	if ResourceLoader.exists(scene_path):
		p.scene = load(scene_path)
	p.fail_noise_hops = noise
	p.solved_flag = flag
	p.params = {"normal": {}}
	return p


func _save_puzzle(p: PuzzleData) -> void:
	_save(p, "%s/puzzles/%s.tres" % [DATA, String(p.id).to_lower()])


func _field(name: String, kind: SeedField.Kind, lo: int, hi: int, step := 1, count := 1) -> SeedField:
	var f := SeedField.new()
	f.name = StringName(name)
	f.kind = kind
	f.min_value = lo
	f.max_value = hi
	f.step = step
	f.count = count
	return f


func _set_flag(flag: String) -> SetFlag:
	var a := SetFlag.new()
	a.flag = StringName(flag)
	return a


func _give(item: String) -> GiveItem:
	var a := GiveItem.new()
	a.item_id = StringName(item)
	return a


func _open_doc(doc: String) -> OpenDocument:
	var a := OpenDocument.new()
	a.document_id = StringName(doc)
	return a


func _play_tape(tape: String) -> PlayTape:
	var a := PlayTape.new()
	a.tape_id = StringName(tape)
	return a


func _save(res: Resource, path: String) -> void:
	if FileAccess.file_exists(path) and not force:
		kept += 1
		return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("build_act1_data: %s (%s)" % [path, error_string(err)])
	else:
		written += 1
