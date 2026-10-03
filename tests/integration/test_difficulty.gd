extends RoomTestBase
## Threat difficulty rules (GDD §8.1, docs/03-milestone-2.md §2).

const TEST_SAVES := "user://test_saves"


func before_each() -> void:
	super.before_each()
	SaveSystem.save_dir = TEST_SAVES
	for slot in SaveSystem.SLOT_COUNT:
		SaveSystem.delete_slot(slot)


func after_each() -> void:
	for slot in SaveSystem.SLOT_COUNT:
		SaveSystem.delete_slot(slot)
	SaveSystem.save_dir = SaveSystem.SAVE_DIR
	super.after_each()


func test_tuning_table() -> void:
	var o := Difficulty.tuning("observer")
	var p := Difficulty.tuning("patient")
	var c := Difficulty.tuning("committed")
	assert_false(o.catch_lethal)
	assert_true(p.catch_lethal and c.catch_lethal)
	assert_true(o.autosave_every_room and not p.autosave_every_room)
	assert_true(c.saves_cost_cassette and not p.saves_cost_cassette)
	assert_true(o.close_ups_pause and not p.close_ups_pause)
	assert_true(o.walk_speed < p.walk_speed and p.walk_speed < c.walk_speed)
	assert_true(
		o.breath_capacity - o.breath_required > c.breath_capacity - c.breath_required,
		"Observer has the widest breath window"
	)


func test_committed_save_needs_cassette() -> void:
	GameState.set_difficulty("committed", "normal")
	assert_eq(SaveScreen.save_with_rules(1), "ui.save.need_cassette")
	assert_false(SaveSystem.has_save(1))
	GameState.give_item("item_blank_cassette")
	assert_eq(SaveScreen.save_with_rules(1), "ui.save.saved")
	assert_true(SaveSystem.has_save(1))
	assert_false(GameState.has_item("item_blank_cassette"), "cassette used up")


func test_patient_save_is_free() -> void:
	GameState.set_difficulty("patient", "normal")
	assert_eq(SaveScreen.save_with_rules(1), "ui.save.saved")


func test_observer_autosaves_on_room_entry() -> void:
	GameState.set_difficulty("observer", "normal")
	enter(&"G03", &"spawn_from_g02")
	assert_true(SaveSystem.has_save(SaveSystem.AUTOSAVE_SLOT))
	SaveSystem.delete_slot(SaveSystem.AUTOSAVE_SLOT)
	GameState.set_difficulty("patient", "normal")
	enter(&"G03", &"spawn_from_g02")
	assert_false(SaveSystem.has_save(SaveSystem.AUTOSAVE_SLOT))


func test_cassettes_only_appear_on_committed() -> void:
	GameState.set_difficulty("patient", "normal")
	var room := load_room(&"G03", &"spawn_from_g02")
	assert_false(hotspot(room, "hs_blank_cassette").is_active())
	GameState.set_difficulty("committed", "normal")
	assert_true(hotspot(room, "hs_blank_cassette").is_active())


func test_patient_catch_is_game_over() -> void:
	GameState.set_difficulty("patient", "normal")
	GameState.give_item("item_choleric_key")
	enter(&"G02", &"spawn_from_g04")
	var caught := [false]
	var on_caught := func() -> void: caught[0] = true
	StalkerDirector.player_caught.connect(on_caught)
	StalkerDirector._on_caught()
	StalkerDirector.player_caught.disconnect(on_caught)
	assert_true(caught[0])


func test_observer_catch_wakes_in_safe_room() -> void:
	GameState.set_difficulty("observer", "normal")
	GameState.give_item("item_choleric_key")
	GameState.give_item("item_music_box_crank")
	var room := enter(&"G02", &"spawn_from_g04")
	await wait_nav_sync(room)
	var before := GameState.composure
	var caught := [false]
	var on_caught := func() -> void: caught[0] = true
	StalkerDirector.player_caught.connect(on_caught)
	StalkerDirector._on_caught()
	StalkerDirector.player_caught.disconnect(on_caught)
	assert_false(caught[0], "not lethal on Observer")
	assert_false(GameState.has_item("item_music_box_crank"), "one droppable item left behind")
	var dropped: Array = GameState.room_state("G02")["vars"].get("dropped", [])
	assert_eq(dropped.size(), 1)
	assert_true(GameState.composure < before)
	assert_true(GameState.get_flag("act1.chase_done"), "Act 1 reveal counts as done")
	await wait(2.5)
	assert_eq(GameState.current_room, "G01", "wakes in the nearest safe room")


func test_room_graph() -> void:
	var n := RoomGraph.neighbors(&"G02")
	for r in [&"G01", &"G03", &"G04", &"G06"]:
		assert_has(n, r)
	assert_eq(RoomGraph.distance(&"G01", &"G05"), 3)
	assert_eq(RoomGraph.path(&"G03", &"G05"), [&"G03", &"G02", &"G04", &"G05"])
	assert_eq(RoomGraph.nearest(&"G05", func(d: RoomData) -> bool: return d.safe_room), &"G01")
	var avoid_g02 := func(r: StringName) -> bool: return r != &"G02"
	assert_eq(RoomGraph.distance(&"G03", &"G05", avoid_g02), -1, "G03 only connects through G02")


func test_sedatives_restore_composure() -> void:
	GameState.set_composure(0.2)
	GameState.give_item("item_sedatives")
	var inv := InventoryUi.new()
	tree().root.add_child(inv)
	assert_true(inv.consume("item_sedatives"))
	assert_false(GameState.has_item("item_sedatives"))
	assert_between(GameState.composure, 0.59, 0.61)
	assert_false(inv.consume("item_music_box_crank"), "not a consumable")
	inv.free()


func test_committed_has_enough_cassettes() -> void:
	# GDD §8.1: about 12 Blank Cassettes in the whole game, spread across the acts.
	GameState.set_difficulty("committed", "normal")
	var total := 0
	var floors := {}
	for room_id in ContentDB.rooms:
		var data: RoomData = ContentDB.get_room(room_id)
		var room := data.scene.instantiate() as Room
		for h in room.hotspots():
			if h.item_id == &"item_blank_cassette":
				total += 1
				floors[data.map_floor] = true
		room.free()
	assert_true(total >= 12, "at least 12 cassettes placed (found %d)" % total)
	assert_eq(floors.size(), RoomData.Floor.size(), "cassettes on every floor")


func test_act_start_autosaves_except_committed() -> void:
	for threat in ["patient", "committed"]:
		SaveSystem.delete_slot(SaveSystem.AUTOSAVE_SLOT)
		GameState.set_difficulty(threat, "normal")
		GameState.set_flag("act3.started", false)
		enter(&"U01", &"spawn_from_g09")
		var saved := SaveSystem.has_save(SaveSystem.AUTOSAVE_SLOT)
		assert_eq(saved, threat == "patient", "act-start autosave on %s" % threat)
		StalkerDirector.reset()
	SaveSystem.delete_slot(SaveSystem.AUTOSAVE_SLOT)
	GameState.set_difficulty("patient", "normal")
	enter(&"U01", &"spawn_from_g09")
	assert_false(SaveSystem.has_save(SaveSystem.AUTOSAVE_SLOT), "once per act, not every entry")
