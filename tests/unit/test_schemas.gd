extends TestCase


func test_puzzle_params_fallback() -> void:
	var p := PuzzleData.new()
	p.params = {"normal": {"cables": 3}, "hard": {"cables": 4}}
	assert_eq(p.params_for("hard")["cables"], 4)
	assert_eq(p.params_for("easy")["cables"], 3, "missing set falls back to normal")


func test_room_lookup() -> void:
	var r := RoomData.new()
	var e := ExitDef.new()
	e.id = &"to_g02"
	r.exits = [e]
	var c := CameraDef.new()
	c.id = &"cam_a"
	r.cameras = [c]
	assert_eq(r.get_exit(&"to_g02"), e)
	assert_eq(r.get_exit(&"nope"), null)
	assert_eq(r.get_camera(&"cam_a"), c)


func test_tape_locale_fallback() -> void:
	var t := TapeData.new()
	var en := AudioStreamGenerator.new()
	var fr := AudioStreamGenerator.new()
	t.audio = {"en": en, "fr_CA": fr}
	assert_eq(t.audio_for("fr_CA"), fr)
	assert_eq(t.audio_for("fr"), fr)
	assert_eq(t.audio_for("de"), en)


func test_data_folders_load() -> void:
	# Every shipped resource must load and have an id (ContentDB.reload ran in the runner).
	for dict in [ContentDB.items, ContentDB.documents, ContentDB.tapes, ContentDB.puzzles, ContentDB.rooms]:
		for id in dict:
			assert_ne(String(id), "")
