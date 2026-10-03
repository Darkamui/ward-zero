extends RoomTestBase
## Plays Act 1 start to finish through game systems (no UI), for several seeds: the
## critical path of docs/02-milestone-1.md §2.2. Catches broken flags, exits, rewards and
## seed/template mismatches between rooms.


func _solve(puzzle_id: StringName) -> void:
	var data := ContentDB.get_puzzle(puzzle_id)
	var pb := PuzzleBase.new()
	pb.data = data
	pb.logic = PuzzleValues.make_logic(data)
	var s: Variant = pb.logic.solution()
	var ok := false
	match puzzle_id:
		&"P01":
			pb.logic.set_dial(s)
			ok = pb.logic.release()
		&"P02":
			for link in s:
				pb.logic.connect_jacks(link[0], link[1])
			ok = pb.logic.ring()
		&"P03":
			pb.logic.open_drawer(s["drawer"])
			ok = pb.logic.open_cabinet(s["cabinet"])
		&"P04":
			for i in 4:
				pb.logic.set_wheel(i, s[i])
			ok = pb.logic.pull()
		&"P05":
			for r in s.size():
				var n: int = s[r]
				pb.logic.place(r, 0, n / 100)
				pb.logic.place(r, 1, (n / 10) % 10)
				pb.logic.place(r, 2, n % 10)
			ok = pb.logic.submit()
	assert_true(ok, "%s solution accepted" % puzzle_id)
	pb.report_attempt(ok)
	pb.free()


func _through(room: Room, exit_hotspot: String) -> Room:
	var h := hotspot(room, exit_hotspot)
	assert_false(h.is_locked(), "%s/%s unlocked" % [room.room_id(), exit_hotspot])
	var e := h.exit_def()
	return enter(e.target_room, e.target_spawn)


func test_act1_start_to_finish() -> void:
	for s in [11, 222, 3333]:
		StalkerDirector.reset()
		NewGame.start("patient", "normal", s)
		await _play_act1(s)
		CameraDirector.unregister_room()


func _play_act1(s: int) -> void:
	var tapes := []
	var on_tape := func(id: StringName) -> void: tapes.append(id)
	EventBus.tape_requested.connect(on_tape)
	var room := enter(&"G01", &"spawn_start")
	assert_has(tapes, &"tape_01_claire", "opening tape plays (seed %d)" % s)
	assert_true(hotspot(room, "hs_door").is_locked(), "door chained at start")
	_solve(&"P01")
	assert_true(GameState.get_flag("g01.chain_released"))
	room = _through(room, "hs_door")
	assert_eq(room.room_id(), &"G02")
	assert_true(hotspot(room, "hs_gate").is_locked(), "gate locked before P02")
	room = _through(room, "hs_door_g03")
	_solve(&"P02")
	room = _through(room, "hs_door_g02")
	room = _through(room, "hs_gate")
	assert_eq(room.room_id(), &"G04")
	_solve(&"P03")
	assert_true(GameState.has_item("item_photograph"))
	assert_true(GameState.fragments().has("F01"))
	room = _through(room, "hs_door_g05")
	_solve(&"P04")
	assert_true(GameState.has_item("item_choleric_key"))
	assert_true(GameState.fragments().has("F02"))
	room = _through(room, "hs_door_g04")
	room = _through(room, "hs_gate_g02")
	assert_true(StalkerDirector.chase_active, "chase starts on entering the Lobby with the key")
	room = _through(room, "hs_door_g01")
	assert_true(GameState.get_flag("act1.chase_done"), "escaping to the Dayroom ends the chase")
	room = _through(room, "hs_door")
	room = _through(room, "hs_door_g06")
	assert_eq(room.room_id(), &"G06")
	hotspot(room, "hs_altar").use_item(&"item_photograph")
	await wait(1.4)
	assert_true(GameState.in_memory(), "photograph at the altar shifts to 1976")
	assert_true(hotspot(room, "hs_hymn_board_1976").is_active())
	assert_false(hotspot(room, "hs_hymn_board").is_active())
	hotspot(room, "hs_altar").interact()
	await wait(1.4)
	assert_false(GameState.in_memory(), "altar again returns to the present")
	_solve(&"P05")
	assert_true(hotspot(room, "hs_crank").is_active(), "loft open")
	hotspot(room, "hs_crank").interact()
	assert_true(GameState.has_item("item_music_box_crank"))
	room = _through(room, "hs_door_g02")
	var uis := []
	var on_ui := func(n: StringName) -> void: uis.append(n)
	EventBus.ui_requested.connect(on_ui)
	var corridor := hotspot(room, "hs_corridor")
	assert_true(corridor.is_active(), "corridor door reachable after the chase")
	corridor.interact()
	EventBus.ui_requested.disconnect(on_ui)
	EventBus.tape_requested.disconnect(on_tape)
	assert_has(uis, &"end_of_slice")
	var stats := EndOfSliceScreen.stats()
	assert_eq(stats["solved"], 5)
	assert_eq(stats["fragments"], 2)


func test_memory_shift_ends_when_leaving_by_door() -> void:
	GameState.give_item("item_photograph")
	var room := enter(&"G06", &"spawn_from_g02")
	hotspot(room, "hs_altar").use_item(&"item_photograph")
	await wait(1.4)
	assert_true(GameState.in_memory())
	_through(room, "hs_door_g02")
	assert_false(GameState.in_memory(), "doors always return to the present (GDD §4.1)")


func test_save_and_load_mid_act() -> void:
	NewGame.start("patient", "normal", 77)
	enter(&"G01", &"spawn_start")
	_solve(&"P01")
	SaveSystem.save_dir = "user://test_saves"
	SaveSystem.save(2)
	GameState.reset()
	assert_eq(SaveSystem.load_slot(2), SaveSystem.SaveError.OK)
	SaveSystem.delete_slot(2)
	SaveSystem.save_dir = SaveSystem.SAVE_DIR
	assert_true(GameState.get_flag("g01.chain_released"))
	assert_true(GameState.is_puzzle_solved("P01"))
	assert_true(GameState.has_item("item_wristband"))
	assert_eq(Seed.current, 77)
