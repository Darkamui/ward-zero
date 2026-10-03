extends WalkthroughBase
## Plays Act 2 through game systems (docs/04-milestone-3.md §2), starting from a completed
## Act 1, on all 9 difficulty combinations. Also checks the AI turns on and survives saving.


func test_act2_on_every_difficulty_combination() -> void:
	var s := 900
	for threat in GameState.THREAT_LEVELS:
		for puzzle in GameState.PUZZLE_LEVELS:
			StalkerDirector.reset()
			_act1_done(threat, puzzle, s)
			await _play_act2("%s/%s" % [threat, puzzle])
			CameraDirector.unregister_room()
			s += 1


func _play_act2(label: String) -> void:
	var room := enter(&"G09", &"spawn_from_g02")
	assert_true(StalkerDirector.ai_active, "AI on in Act 2 (%s)" % label)
	# The walkthrough below is instant; keep him from interrupting it.
	StalkerDirector.deactivate()
	assert_true(hotspot(room, "hs_to_w01").is_locked(), "West Wing locked before P07")
	room = _go(room, "hs_to_e01")
	assert_true(hotspot(room, "hs_to_e04").is_locked(), "Linen Room locked before P06")
	room = _go(room, "hs_to_e02")
	_solve(&"P06")
	assert_true(GameState.has_item("item_linen_key"))
	room = _go(_go(room, "hs_to_e01"), "hs_to_e04")
	_solve(&"P08")
	assert_eq(GameState.slot_count(), GameState.SATCHEL_SLOTS, "Satchel: 8 slots")
	room = _go(_go(room, "hs_to_e01"), "hs_to_e05")
	_solve(&"P08L")
	assert_true(GameState.has_item("item_valve_wheel"))
	room = _go(_go(room, "hs_to_e01"), "hs_to_e03")
	_use(room, "hs_valves")  # opens the close-up (wheel present)
	_solve(&"P07")
	assert_true(GameState.has_item("item_melancholic_key"))
	room = _go(_go(_go(room, "hs_to_e01"), "hs_to_g09"), "hs_to_w01")
	room = _go(room, "hs_to_w06")
	_use(room, "hs_lullaby")
	assert_has(GameState.tapes, "tape_03_lullaby")
	room = _go(_go(room, "hs_to_w01"), "hs_to_w02")
	assert_false(hotspot(room, "hs_radiator_found").is_active())
	await _shift(room, "hs_small_bed", &"item_photograph")
	_use(room, "hs_radiator_1976")
	assert_true(MemoryShiftSystem.is_persistent("w02_drawing"))
	await _unshift(room, "hs_small_bed")
	_use(room, "hs_radiator_found")
	assert_true(GameState.get_flag("p09.drawing_found"), "the 1976 drawing carried forward")
	_solve(&"P09")
	assert_true(GameState.has_item("item_ribbon"))
	room = _go(_go(room, "hs_to_w01"), "hs_to_w03")
	await _shift(room, "hs_coat_hook", &"item_ribbon")
	assert_true(hotspot(room, "hs_board_1976").is_active())
	await _unshift(room, "hs_coat_hook")
	_solve(&"P10")
	assert_true(GameState.has_item("item_cylinder"))
	room = _go(_go(room, "hs_to_w01"), "hs_to_w04")
	_use(room, "hs_music_box")
	_solve(&"P11")
	assert_true(GameState.has_item("item_fuse"))
	room = _go(_go(room, "hs_to_w01"), "hs_to_w05")
	_solve(&"P12")
	assert_true(GameState.has_item("item_phlegmatic_key"))
	room = _go(_go(_go(room, "hs_to_w01"), "hs_to_g09"), "hs_to_b01")
	_solve(&"P13")
	assert_true(GameState.get_flag("b01.power_on"))
	assert_false(hotspot(room, "hs_to_g08").is_locked(), "kitchen shortcut opens from below")
	room = _go(room, "hs_to_g09")
	assert_false(hotspot(room, "hs_to_u01").is_locked(), "elevator has power (%s)" % label)
	var stats := EndOfSliceScreen.stats()
	assert_eq(stats["solved"], 14)
	assert_eq(stats["fragments"], 6, "F01 F02 F04 F05 F06 F07 (F03 is optional)")


func test_ai_state_survives_save_and_load() -> void:
	_act1_done("patient", "normal", 77)
	enter(&"G09", &"spawn_from_g02")
	assert_true(StalkerDirector.ai_active)
	await wait(0.2)
	var before := StalkerDirector.snapshot()
	assert_true(before["active"])
	SaveSystem.save(3)
	StalkerDirector.reset()
	GameState.reset()
	assert_eq(SaveSystem.load_slot(3), SaveSystem.SaveError.OK)
	StalkerDirector.restore(GameState.stalker)
	assert_true(StalkerDirector.ai_active, "AI resumes after loading")
	assert_eq(StalkerDirector.sim.room, StringName(before["room"]))
	assert_eq(StalkerDirector.sim.patrol_index, int(before["patrol_index"]))


func test_ai_patrols_act2_route() -> void:
	_act1_done("patient", "normal", 78)
	enter(&"W06", &"spawn_from_w01")  # safe room: he never comes in
	StalkerDirector.activate(StalkerDirector.ACT2_ROUTE, StalkerDirector.ACT2_START)
	var visited: Array[StringName] = []
	StalkerDirector.sim.arrived.connect(func(r: StringName) -> void: visited.append(r))
	for i in 300:  # 150 s: more than one full loop of the route
		StalkerDirector.sim.tick(0.5)
	for r in [&"E01", &"G09", &"G07", &"W01", &"W05"]:
		assert_has(visited, r, "patrol reaches %s" % r)
	for r in visited:
		assert_eq(ContentDB.get_room(r).access, RoomData.Access.OPEN, "only open rooms (%s)" % r)
