extends WalkthroughBase
## Plays Acts 3-4 and the finale through game systems (docs/05-milestone-4.md), starting
## from a completed Act 2, on all 9 difficulty combinations. Each combination ends with a
## different ending in turn: Discharge, Relapse, Claire.

const ENDINGS := [Ending.DISCHARGE, Ending.RELAPSE, Ending.CLAIRE]


func before_each() -> void:
	super.before_each()
	Profile.path = "user://test_profile.cfg"
	Profile.clear()


func after_each() -> void:
	Finale.cancel()
	Profile.clear()
	Profile.path = "user://profile.cfg"
	super.after_each()


func test_full_game_on_every_difficulty_combination() -> void:
	var s := 1200
	var i := 0
	for threat in GameState.THREAT_LEVELS:
		for puzzle in GameState.PUZZLE_LEVELS:
			StalkerDirector.reset()
			_act2_done(threat, puzzle, s)
			var label := "%s/%s" % [threat, puzzle]
			var room := await _play_act3(label)
			room = await _play_act4(room, label)
			await _finale(room, ENDINGS[i % 3], label)
			CameraDirector.unregister_room()
			s += 1
			i += 1
	assert_eq(Profile.endings_seen().size(), 3, "all three endings recorded in the profile")
	assert_true(Profile.ng_plus_unlocked())


func _play_act3(label: String) -> Room:
	var room := _go(enter(&"G09", &"spawn_from_b01"), "hs_to_u01")
	assert_eq(room.room_id(), &"U01")
	assert_true(StalkerDirector.ai_active, "AI on upstairs (%s)" % label)
	assert_eq(StalkerDirector.zone, "act3")
	assert_eq(int(GameState.get_flag("act", 0)), 3)
	StalkerDirector.deactivate()
	room = _go(room, "hs_to_u03")
	_use(room, "hs_dictation")
	assert_has(GameState.tapes, "tape_04_director")
	room = _go(_go(room, "hs_to_u01"), "hs_to_u02")
	assert_true(hotspot(room, "hs_to_u06").is_locked(), "secret door shut before P14")
	_use(room, "hs_cart")
	_solve(&"P14")
	room = _go(_go(room, "hs_to_u01"), "hs_to_u04")
	_solve(&"P15")
	assert_true(GameState.has_item("item_projector_key"))
	room = _go(_go(room, "hs_to_u01"), "hs_to_u05")
	_use(room, "hs_projector")
	_solve(&"P16")
	assert_has(GameState.documents, "doc_f10_case_slide")
	_use(room, "hs_screen")
	assert_has(GameState.documents, "doc_slide_overlay", "the screen shows the safe code")
	room = _go(_go(_go(room, "hs_to_u01"), "hs_to_u02"), "hs_to_u06")
	assert_true(hotspot(room, "hs_to_b03").is_locked(), "dumbwaiter bolted before P18")
	_solve(&"P17")
	assert_true(GameState.has_item("item_sanguine_key"))
	await _shift(room, "hs_armchair", &"item_photograph")
	assert_true(hotspot(room, "hs_session_1976").is_active(), "1976 session (%s)" % label)
	assert_false(hotspot(room, "hs_safe").is_active())
	await _unshift(room, "hs_armchair")
	_solve(&"P18")
	return room


func _play_act4(from: Room, label: String) -> Room:
	var room := _go(from, "hs_to_b03")
	assert_eq(room.room_id(), &"B03", "the dumbwaiter drops into the Morgue")
	assert_true(StalkerDirector.ai_active, "AI on below (%s)" % label)
	assert_eq(StalkerDirector.zone, "act4")
	assert_eq(StalkerDirector.sim.zone.get("hearing"), 1, "basement: he hears further")
	StalkerDirector.deactivate()
	_solve(&"P19")
	assert_true(GameState.has_item("item_crayon_drawing"))
	room = _go(room, "hs_to_b02")
	assert_true(hotspot(room, "hs_to_b07").is_locked(), "no Ward Zero before the file is closed")
	room = _go(room, "hs_to_b04")
	await _shift(room, "hs_chair", &"item_crayon_drawing")
	assert_true(hotspot(room, "hs_mural_1976").is_active())
	await _unshift(room, "hs_chair")
	_solve(&"P20")
	assert_has(GameState.tapes, "tape_05_last_night")
	room = _go(_go(_go(room, "hs_to_b02"), "hs_to_b05"), "hs_to_b06")
	assert_eq(GameState.fragments().size(), 12, "every fragment collected (%s)" % label)
	return room


func _finale(vault: Room, ending: String, label: String) -> void:
	_seal_file(ending == Ending.RELAPSE)
	var room := _go(_go(_go(vault, "hs_to_b05"), "hs_to_b02"), "hs_to_b07")
	assert_true(Finale.active, "Ward Zero starts the finale (%s)" % label)
	var seen := []
	var on_ended := func(e: String) -> void: seen.append(e)
	Finale.ended.connect(on_ended)
	if ending == Ending.CLAIRE:
		# Stand still and let him come.
		for k in 40:
			if not seen.is_empty():
				break
			await wait(0.25)
	else:
		_use(room, "hs_exit")
	Finale.ended.disconnect(on_ended)
	assert_eq(seen, [ending], "%s ending (%s)" % [ending, label])
	assert_eq(GameState.get_flag("ending"), ending)


## Closes the file through P21's logic like the close-up does. `misplace` swaps enough
## fragments to drop below the Discharge threshold.
func _seal_file(misplace: bool) -> void:
	var data := ContentDB.get_puzzle(&"P21")
	var pb := PuzzleBase.new()
	pb.data = data
	pb.logic = PuzzleValues.make_logic(data)
	var l := pb.logic as P21Logic
	l.available = GameState.fragments()
	var order: Array = l.solution()
	if misplace:
		for k in range(0, 8, 2):
			var tmp: String = order[k]
			order[k] = order[k + 1]
			order[k + 1] = tmp
	for k in order.size():
		l.place(k, order[k])
	l.seal()
	GameState.set_flag("p21.score", l.score)
	pb.report_attempt(true)
	pb.free()
	assert_eq(l.score, 4 if misplace else 12)
	assert_true(GameState.get_flag("b06.file_sealed"))


func test_ending_rules() -> void:
	assert_eq(Ending.compute(12, true), Ending.CLAIRE)
	assert_eq(Ending.compute(11, true), Ending.RELAPSE, "staying needs a complete file")
	assert_eq(Ending.compute(12, false), Ending.DISCHARGE)
	assert_eq(Ending.compute(9, false), Ending.DISCHARGE)
	assert_eq(Ending.compute(8, false), Ending.RELAPSE)


func test_new_game_plus_keeps_files_and_adds_hint() -> void:
	NewGame.start("patient", "normal", 5)
	GameState.add_document("doc_f02_fire_clipping")
	GameState.add_tape("tape_01_claire")
	Profile.record_ending(Ending.RELAPSE)
	assert_eq(Profile.endings_seen(), [Ending.RELAPSE] as Array[String])
	NewGame.start("observer", "hard", 6, true)
	assert_eq(GameState.ng_plus, 1)
	assert_has(GameState.documents, "doc_f02_fire_clipping", "Files carry over")
	assert_has(GameState.tapes, "tape_01_claire")
	assert_has(GameState.documents, NewGame.NG_PLUS_HINT, "Claire hint appears in Files")
	assert_eq(Seed.current, 6, "new seed")
	NewGame.start("patient", "normal", 7)
	assert_false(GameState.documents.has(NewGame.NG_PLUS_HINT), "plain new game has no hint")


func test_ai_zone_survives_save_and_load() -> void:
	_act2_done("committed", "normal", 31)
	enter(&"U01", &"spawn_from_g09")
	assert_eq(StalkerDirector.zone, "act3")
	await wait(0.2)
	SaveSystem.save(4)
	StalkerDirector.reset()
	GameState.reset()
	assert_eq(SaveSystem.load_slot(4), SaveSystem.SaveError.OK)
	StalkerDirector.restore(GameState.stalker)
	assert_eq(StalkerDirector.zone, "act3")
	assert_eq(StalkerDirector.sim.zone.get("speed"), 1.2)


func test_ai_patrols_act3_and_act4_routes() -> void:
	_act2_done("patient", "normal", 32)
	enter(&"U03", &"spawn_from_u01")
	for route in [StalkerDirector.ACT3_ROUTE, StalkerDirector.ACT4_ROUTE]:
		StalkerDirector.activate(route, route[0])
		var visited: Array[StringName] = []
		StalkerDirector.sim.arrived.connect(func(r: StringName) -> void: visited.append(r))
		for k in 300:
			StalkerDirector.sim.tick(0.5)
		for r in route:
			assert_has(visited, r, "patrol reaches %s" % r)
		for r in visited:
			assert_eq(ContentDB.get_room(r).access, RoomData.Access.OPEN, "only open rooms (%s)" % r)
		StalkerDirector.deactivate()
