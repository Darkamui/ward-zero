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
	_act2_items()
	_item("item_blank_cassette", "blank_cassette", ItemData.Storage.SLOT, ItemData.Kind.CONSUMABLE)
	var sedatives := _item(
		"item_sedatives", "sedatives", ItemData.Storage.SLOT, ItemData.Kind.CONSUMABLE, false
	)
	var calm := ChangeComposure.new()
	calm.delta = 0.4
	sedatives.use_actions = [calm]
	_save_item(sedatives)
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


func _act2_items() -> void:
	_item("item_linen_key", "linen_key", ItemData.Storage.KEY_POUCH, ItemData.Kind.KEY)
	_item("item_valve_wheel", "valve_wheel", ItemData.Storage.SLOT, ItemData.Kind.TOOL)
	_item("item_melancholic_key", "melancholic_key", ItemData.Storage.KEY_POUCH, ItemData.Kind.KEY)
	_item("item_phlegmatic_key", "phlegmatic_key", ItemData.Storage.KEY_POUCH, ItemData.Kind.KEY)
	_item("item_satchel", "satchel", ItemData.Storage.KEY_POUCH, ItemData.Kind.TOOL)
	_item("item_ribbon", "ribbon", ItemData.Storage.KEY_POUCH, ItemData.Kind.ANCHOR)
	_item("item_cylinder", "cylinder", ItemData.Storage.KEY_POUCH, ItemData.Kind.ANCHOR)
	_item("item_fuse", "fuse", ItemData.Storage.SLOT, ItemData.Kind.TOOL)
	for f in [
		["F03", "f03_nurse_log"],
		["F04", "f04_drawing"],
		["F05", "f05_essay"],
		["F06", "f06_scratchings"],
		["F07", "f07_tape"]
	]:
		var frag := _item("item_" + f[1], f[1], ItemData.Storage.KEY_POUCH, ItemData.Kind.FRAGMENT, false)
		frag.fragment_id = StringName(f[0])
		_save_item(frag)


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
	_doc(
		"doc_quiet_hours",
		"quiet_hours",
		DocumentData.Style.NOTICE,
		{"frequency": "puzzle:P01.frequency", "a": "puzzle:P01.riddle_a", "b": "puzzle:P01.riddle_b"},
		&"",
		{"hard": "doc.quiet_hours.body_hard"}
	)
	var dir := {}
	for role in P02Logic.ALL_ROLES:
		dir["ext_" + role] = "puzzle:P02.ext_" + role
	_doc("doc_staff_directory", "staff_directory", DocumentData.Style.PRINT, dir)
	_doc(
		"doc_desk_memo",
		"desk_memo",
		DocumentData.Style.HANDWRITTEN,
		{},
		&"",
		{"easy": "doc.desk_memo.body_easy", "hard": "doc.desk_memo.body_hard"}
	)
	_doc(
		"doc_founding_plaque",
		"founding_plaque",
		DocumentData.Style.PRINT,
		{"year": "puzzle:P04.founding_year"}
	)
	_doc(
		"doc_cipher_memo",
		"cipher_memo",
		DocumentData.Style.TYPEWRITER,
		{"shift": "puzzle:P04.shift"},
		&"",
		{"hard": "doc.cipher_memo.body_hard"}
	)
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
		{
			"h1": "puzzle:P05.hymns[0]",
			"h2": "puzzle:P05.hymns[1]",
			"h3": "puzzle:P05.hymns[2]",
			"t1": "trpuzzle:P05.title_key_0",
			"t2": "trpuzzle:P05.title_key_1",
			"t3": "trpuzzle:P05.title_key_2",
		},
		&"",
		{"easy": "doc.hymn_board_1976.body_easy", "hard": "doc.hymn_board_1976.body_hard"}
	)
	var index := {}
	for i in P05Logic.TITLE_COUNT:
		index["n%d" % i] = "puzzle:P05.number_%d" % i
	_doc("doc_hymnal_index", "hymnal_index", DocumentData.Style.PRINT, index)
	_act2_documents()
	_doc("doc_visitor_notice", "visitor_notice", DocumentData.Style.NOTICE, {})
	_doc("doc_hymnal_page", "hymnal_page", DocumentData.Style.PRINT, {})


func _act2_documents() -> void:
	var charts := {}
	var shift_log := {}
	for i in P06Logic.PATIENTS.size():
		charts["p%d" % i] = "puzzle:P06.patient_%d" % i
		charts["s%d" % i] = "trpuzzle:P06.shape_key_%d" % i
		charts["c%d" % i] = "trpuzzle:P06.color_key_%d" % i
		shift_log["p%d" % i] = "puzzle:P06.patient_%d" % i
		shift_log["c%d" % i] = "trpuzzle:P06.color_key_%d" % i
	_doc(
		"doc_med_charts",
		"med_charts",
		DocumentData.Style.PRINT,
		charts,
		&"",
		{"easy": "doc.med_charts.body_easy", "hard": "doc.med_charts.body_hard"}
	)
	_doc(
		"doc_shift_log",
		"shift_log",
		DocumentData.Style.HANDWRITTEN,
		shift_log,
		&"",
		{"easy": "doc.shift_log.body_easy", "hard": "doc.shift_log.body_hard"}
	)
	_doc("doc_f03_nurse_log", "f03_nurse_log", DocumentData.Style.HANDWRITTEN, {}, &"F03")
	var ledger := {}
	for k in 6:
		ledger["r%d" % k] = "puzzle:P08.row_%d" % k
	_doc("doc_laundry_ledger", "laundry_ledger", DocumentData.Style.PRINT, ledger)
	_doc(
		"doc_laundry_note",
		"laundry_note",
		DocumentData.Style.HANDWRITTEN,
		{"bed": "puzzle:P08.bed", "day": "puzzle:P08.day_name", "tag": "puzzle:P08.target_tag"},
		&"",
		{"easy": "doc.laundry_note.body_easy"}
	)
	_doc(
		"doc_sheet_label",
		"sheet_label",
		DocumentData.Style.NOTE,
		{"a": "puzzle:P08.code_0", "b": "puzzle:P08.code_1", "c": "puzzle:P08.code_2"}
	)
	_doc("doc_f04_drawing", "f04_drawing", DocumentData.Style.NOTE, {}, &"F04")
	var digits := {}
	for i in 4:
		digits["d%d" % i] = "puzzle:P10.digit_%d" % i
	_doc(
		"doc_board_1998",
		"board_1998",
		DocumentData.Style.HANDWRITTEN,
		digits,
		&"",
		{"easy": "doc.board_1998.body_easy"}
	)
	_doc("doc_board_1976", "board_1976", DocumentData.Style.HANDWRITTEN, digits)
	_doc("doc_f05_essay", "f05_essay", DocumentData.Style.HANDWRITTEN, {}, &"F05")
	var notes := {}
	for i in 8:
		notes["n%d" % i] = "trpuzzle:P11.note_key_%d" % i
	_doc(
		"doc_lid_sheet",
		"lid_sheet",
		DocumentData.Style.PRINT,
		notes,
		&"",
		{"easy": "doc.lid_sheet.body_easy", "hard": "doc.lid_sheet.body_hard"}
	)
	_doc("doc_f06_scratchings", "f06_scratchings", DocumentData.Style.HANDWRITTEN, {}, &"F06")
	_doc(
		"doc_boiler_manual",
		"boiler_manual",
		DocumentData.Style.TYPEWRITER,
		{},
		&"",
		{"easy": "doc.boiler_manual.body_easy"}
	)
	_doc("doc_dining_menu", "dining_menu", DocumentData.Style.NOTICE, {})


func _doc(
	id: String,
	key: String,
	style: DocumentData.Style,
	placeholders: Dictionary,
	fragment := &"",
	by_difficulty := {}
) -> void:
	var d := DocumentData.new()
	d.id = StringName(id)
	d.title_key = "doc.%s.title" % key
	d.body_key = "doc.%s.body" % key
	d.style = style
	d.fragment_id = fragment
	for k in by_difficulty:
		d.body_key_by_difficulty[k] = by_difficulty[k]
	for k in placeholders:
		d.placeholders[StringName(k)] = placeholders[k]
	_save(d, "%s/documents/%s.tres" % [DATA, id])


# --- Tapes --------------------------------------------------------------------


func _tapes() -> void:
	_tape("tape_01_claire", "01_claire", [[0.5, 3.0], [3.5, 7.0]], true)
	_tape("vo_p01_radio", "vo_p01_radio", [[0.3, 4.5], [4.8, 6.5]], false)
	_tape(
		"tape_02_bouchard", "02_bouchard", [[0.5, 4.5], [5.0, 9.5], [10.0, 14.0], [14.5, 18.0]], true, &"F07"
	)
	_tape("tape_03_lullaby", "03_lullaby", [[0.5, 6.0], [6.5, 10.0]], true)


func _tape(id: String, key: String, timings: Array, listed: bool, fragment := &"") -> void:
	var t := TapeData.new()
	t.fragment_id = fragment
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
	p05.seed_fields = [
		_field("hymns", SeedField.Kind.UNIQUE_INTS, 100, 699, 1, 3),
		_field("hymn_titles", SeedField.Kind.UNIQUE_INTS, 0, P05Logic.TITLE_COUNT - 1, 1, 3),
	]
	p05.params = {"easy": {"rows": 2}, "normal": {"rows": 3}, "hard": {"rows": 3}}
	p05.rewards = [_set_flag("g06.loft_open")]
	_save_puzzle(p05)

	_act2_puzzles()

	var p18 := _puzzle("P18", "U06", "p18_grandfather_clock", P18Logic, 1, &"p18.solved")
	p18.seed_fields = [
		_field("fire_hour", SeedField.Kind.INT, 1, 4), _field("fire_minute", SeedField.Kind.STEPPED, 0, 55, 5)
	]
	_save_puzzle(p18)


func _act2_puzzles() -> void:
	var p06 := _puzzle("P06", "E02", "p06_medication_cart", P06Logic, 1, &"p06.solved")
	p06.seed_fields = [
		_field("colors", SeedField.Kind.UNIQUE_INTS, 0, 4, 1, 5),
		_field("shapes", SeedField.Kind.UNIQUE_INTS, 0, 4, 1, 5)
	]
	p06.params = {"easy": {"patients": 3}, "normal": {"patients": 4}, "hard": {"patients": 5}}
	p06.rewards = [_give("item_linen_key"), _give("item_sedatives")]
	_save_puzzle(p06)

	var p07 := _puzzle("P07", "E03", "p07_hydrotherapy", P07Logic, 0, &"p07.solved")
	p07.seed_fields = [_field("config", SeedField.Kind.INT, 0, 1)]
	p07.params = {
		"easy": {"configs": [{"caps": [5, 3], "start": [0, 0], "goal": [4, 0], "tap": true}]},
		"normal": {},
		"hard": {"configs": [{"caps": [12, 7, 5], "start": [12, 0, 0], "goal": [6, 6, 0]}]},
	}
	p07.rewards = [_give("item_melancholic_key")]
	_save_puzzle(p07)

	var p08 := _puzzle("P08", "E04", "p08_linen", P08Logic, 1, &"p08.solved")
	p08.seed_fields = [
		_field("tags", SeedField.Kind.UNIQUE_INTS, 0, 35, 1, 12),
		_field("target", SeedField.Kind.INT, 0, 11),
		_field("bed", SeedField.Kind.INT, 1, 12),
		_field("day", SeedField.Kind.INT, 0, 6),
		_field("lockbox_code", SeedField.Kind.INT, 100, 999),
	]
	p08.rewards = [_open_doc("doc_sheet_label"), _give("item_satchel"), GrowInventory.new()]
	_save_puzzle(p08)

	var p08l := _puzzle("P08L", "E05", "p08l_lockbox", CodeLockLogic, 1, &"p08l.solved")
	p08l.values_from = &"P08"
	p08l.params = {"normal": {"code_field": "lockbox_code", "digits": 3}}
	p08l.rewards = [_give("item_valve_wheel")]
	_save_puzzle(p08l)

	var p09 := _puzzle("P09", "W02", "p09_drawings", P09Logic, 1, &"p09.solved")
	p09.seed_fields = [_field("dates", SeedField.Kind.UNIQUE_INTS, 1, 28, 1, 6)]
	p09.params = {"easy": {"dates_on_front": true}, "normal": {}, "hard": {}}
	p09.rewards = [_give("item_f04_drawing"), _open_doc("doc_f04_drawing"), _give("item_ribbon")]
	_save_puzzle(p09)

	var p10 := _puzzle("P10", "W03", "p10_chalkboard", CodeLockLogic, 1, &"p10.solved")
	p10.seed_fields = [_field("code_number", SeedField.Kind.INT, 1000, 9999)]
	p10.params = {"normal": {"code_field": "code_number", "digits": 4}}
	p10.rewards = [_give("item_f05_essay"), _open_doc("doc_f05_essay"), _give("item_cylinder")]
	_save_puzzle(p10)

	var p11 := _puzzle("P11", "W04", "p11_music_box", P11Logic, 1, &"p11.solved")
	p11.seed_fields = [_field("melody", SeedField.Kind.INT_LIST, 0, 4, 1, 8)]
	p11.params = {"easy": {"length": 4}, "normal": {"length": 6}, "hard": {"length": 8}}
	p11.rewards = [_give("item_fuse")]
	_save_puzzle(p11)

	var p12 := _puzzle("P12", "W05", "p12_knocks", P12Logic, 1, &"p12.solved")
	p12.seed_fields = [_field("knocks", SeedField.Kind.INT_LIST, 0, 4, 1, 6)]
	p12.params = {"easy": {"length": 3}, "normal": {"length": 4}, "hard": {"length": 6}}
	p12.rewards = [
		_give("item_phlegmatic_key"), _give("item_f06_scratchings"), _open_doc("doc_f06_scratchings")
	]
	_save_puzzle(p12)

	var p13 := _puzzle("P13", "B01", "p13_boiler", P13Logic, 2, &"p13.solved")
	p13.seed_fields = [_field("solution", SeedField.Kind.INT_LIST, 1, 5, 1, 3)]
	p13.params = {"easy": {"simple": true}, "normal": {}, "hard": {}}
	p13.rewards = [_set_flag("b01.power_on"), _give("item_f07_tape"), _play_tape("tape_02_bouchard")]
	_save_puzzle(p13)


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
