extends RoomTestBase
## Scripted Act 1 chase (docs/02-milestone-1.md M1-18).


func _start_chase() -> Room:
	GameState.give_item("item_choleric_key")
	var room := enter(&"G02", &"spawn_from_g04")
	await wait_nav_sync(room)
	return room


func test_no_chase_without_key() -> void:
	enter(&"G02", &"spawn_from_g04")
	assert_false(StalkerDirector.chase_active)


func test_telegraph_before_stalker_appears() -> void:
	await _start_chase()
	assert_true(StalkerDirector.chase_active)
	assert_true(StalkerDirector.stalker == null, "not visible during the telegraph")
	assert_ne(StalkerDirector.checkpoint, "", "retry checkpoint captured")
	await wait(StalkerDirector.MIN_TELEGRAPH_SECONDS - 0.2)
	assert_true(StalkerDirector.stalker == null, "still hidden before 3 s (rule R9)")
	await wait(0.9)
	assert_true(StalkerDirector.stalker != null, "appears after the telegraph")
	assert_true(GameState.get_flag("g02.barricade_broken"))


func test_escape_to_another_room_ends_chase() -> void:
	await _start_chase()
	await wait(StalkerDirector.MIN_TELEGRAPH_SECONDS + 0.7)
	load_room(&"G01", &"spawn_from_g02")
	assert_false(StalkerDirector.chase_active)
	assert_true(GameState.get_flag("act1.chase_done"))
	enter(&"G02", &"spawn_from_g01")
	assert_false(StalkerDirector.chase_active, "never restarts once done")


func test_walking_player_is_caught_running_player_escapes() -> void:
	# Walking from the gate to the Dayroom door gets caught; running makes it.
	for run in [false, true]:
		StalkerDirector.reset()
		GameState.reset()
		var room := await _start_chase()
		var caught := [false]
		var on_caught := func() -> void: caught[0] = true
		StalkerDirector.player_caught.connect(on_caught)
		await wait(StalkerDirector.MIN_TELEGRAPH_SECONDS + 0.6)
		var door := hotspot(room, "hs_door_g01")
		var arrived := [false]
		player.walk_to(door.approach_position(), run, func() -> void: arrived[0] = true)
		for i in 900:
			if arrived[0] or caught[0]:
				break
			await tree().physics_frame
		StalkerDirector.player_caught.disconnect(on_caught)
		if run:
			assert_true(arrived[0] and not caught[0], "running player escapes")
		else:
			assert_true(caught[0], "walking player is caught")
		CameraDirector.unregister_room()
