extends TestCase

const TEST_DIR := "user://test_saves"


func before_each() -> void:
	SaveSystem.save_dir = TEST_DIR
	for slot in SaveSystem.SLOT_COUNT:
		SaveSystem.delete_slot(slot)


func after_each() -> void:
	for slot in SaveSystem.SLOT_COUNT:
		SaveSystem.delete_slot(slot)
	SaveSystem.save_dir = SaveSystem.SAVE_DIR


func _sample_state() -> void:
	Seed.set_seed(4242)
	GameState.set_flag("p01.solved", true)
	GameState.add_document("doc_quiet_hours")
	GameState.set_location("G03", "spawn_from_g02")


func test_save_and_load_slot() -> void:
	_sample_state()
	assert_eq(SaveSystem.save(3), SaveSystem.SaveError.OK)
	assert_true(SaveSystem.has_save(3))
	GameState.reset()
	Seed.set_seed(0)
	assert_eq(SaveSystem.load_slot(3), SaveSystem.SaveError.OK)
	assert_eq(Seed.current, 4242)
	assert_true(GameState.get_flag("p01.solved"))
	assert_eq(GameState.current_room, "G03")


func test_load_missing_slot() -> void:
	assert_eq(SaveSystem.load_slot(5), SaveSystem.SaveError.NO_SAVE)


func test_list_slots() -> void:
	_sample_state()
	SaveSystem.save(1)
	SaveSystem.save(4)
	var slots := SaveSystem.list_slots()
	assert_eq(slots.size(), 2)
	assert_eq(slots[1]["slot"], 4)
	assert_eq(slots[0]["room"], "G03")


func test_export_import_round_trip() -> void:
	_sample_state()
	var code := SaveSystem.export_string()
	assert_true(code.begins_with("WZ1-"))
	GameState.reset()
	Seed.set_seed(0)
	assert_eq(SaveSystem.import_string(code), SaveSystem.SaveError.OK)
	assert_eq(Seed.current, 4242)
	assert_has(GameState.documents, "doc_quiet_hours")


func test_import_tolerates_whitespace() -> void:
	_sample_state()
	var code := "  \n" + SaveSystem.export_string() + "\n "
	assert_eq(SaveSystem.import_string(code), SaveSystem.SaveError.OK)


func test_import_garbage() -> void:
	assert_eq(SaveSystem.import_string("hello"), SaveSystem.SaveError.BAD_FORMAT)
	assert_eq(SaveSystem.import_string("WZ1-abc"), SaveSystem.SaveError.BAD_FORMAT)


func test_import_damaged() -> void:
	_sample_state()
	var code := SaveSystem.export_string()
	# Flip one base64 character in the payload.
	var i := code.length() - 6
	var damaged := code.substr(0, i) + ("A" if code[i] != "A" else "B") + code.substr(i + 1)
	var err := SaveSystem.import_string(damaged)
	assert_true(
		err == SaveSystem.SaveError.BAD_CHECKSUM or err == SaveSystem.SaveError.BAD_FORMAT,
		"damaged code must be rejected, got %s" % err
	)


func test_import_does_not_change_state_on_error() -> void:
	_sample_state()
	SaveSystem.import_string("WZ1-00000000-AAAA")
	assert_eq(Seed.current, 4242)
	assert_eq(GameState.current_room, "G03")


func test_too_new_rejected() -> void:
	var json := JSON.stringify({"version": SaveSystem.VERSION + 1})
	assert_eq(SaveSystem.apply_save_json(json), SaveSystem.SaveError.TOO_NEW)


func test_error_keys_exist_in_translations() -> void:
	for err in [1, 2, 3, 4, 5]:
		var key := SaveSystem.error_key(err)
		assert_ne(key, "")
		assert_ne(tr(key), key, "missing translation for %s" % key)
