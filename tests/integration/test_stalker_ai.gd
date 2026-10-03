extends RoomTestBase
## Stalker AI on the test level (docs/03-milestone-2.md §3-5): telegraphed entry, sight
## and chase, hiding and breath-hold, following through doors, safe rooms, composure.

var spawned_at := -1.0
var approach_at := -1.0
var caught := false


func before_each() -> void:
	super.before_each()
	StalkerLevel.register()
	GameState.set_difficulty("patient", "normal")
	ComposureSystem.hallucinations_enabled = false
	spawned_at = -1.0
	caught = false
	StalkerDirector.stalker_spawned.connect(_on_spawned)
	StalkerDirector.player_caught.connect(_on_caught)


func after_each() -> void:
	StalkerDirector.stalker_spawned.disconnect(_on_spawned)
	StalkerDirector.player_caught.disconnect(_on_caught)
	ComposureSystem.hallucinations_enabled = true
	super.after_each()


func _on_spawned() -> void:
	spawned_at = _now()


func _on_caught() -> void:
	caught = true


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## Player in T02; stalker starts in T03 heading for T02.
func _setup_incoming(spawn := &"spawn_from_t01") -> Room:
	var room := enter(&"T02", spawn)
	await wait_nav_sync(room)
	approach_at = _now()
	StalkerDirector.activate([&"T02", &"T03"], &"T03")
	return room


func _wait_until(cond: Callable, max_seconds: float) -> bool:
	var t := 0.0
	while t < max_seconds:
		if cond.call():
			return true
		await tree().physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
	return cond.call()


func test_entry_is_telegraphed_and_a_visible_player_is_caught() -> void:
	await _setup_incoming()
	assert_true(await _wait_until(func() -> bool: return spawned_at > 0.0, 8.0), "he enters")
	assert_true(
		spawned_at - approach_at >= StalkerDirector.MIN_TELEGRAPH_SECONDS, "at least 3 s warning (rule R9)"
	)
	assert_true(
		await _wait_until(func() -> bool: return caught, 10.0), "sees and catches the player in the open"
	)


func test_hidden_player_who_holds_breath_is_not_found() -> void:
	var room := await _setup_incoming()
	hotspot(room, "hs_locker").interact()
	assert_true(player.is_hidden())
	assert_false((hotspot(room, "hs_locker") as HidingSpot).compromised, "he didn't see me go in")
	StalkerDirector.breath_override = false
	var checked := [false]
	StalkerDirector.breath_check_ended.connect(func(ok: bool) -> void: checked[0] = ok)
	# Start holding only once he is actually at the spot (CHECK phase).
	var done := await _wait_until(
		func() -> bool:
			if StalkerDirector.breath and StalkerDirector.breath.phase == BreathCheck.Phase.CHECK:
				StalkerDirector.breath_override = true
			return checked[0] or caught,
		20.0
	)
	assert_true(done and checked[0], "breath check passed")
	assert_false(caught)
	assert_true(
		await _wait_until(func() -> bool: return StalkerDirector.stalker == null, 25.0),
		"he searches, then leaves"
	)
	assert_false(caught, "never found")


func test_hidden_player_who_breathes_is_found() -> void:
	var room := await _setup_incoming()
	hotspot(room, "hs_locker").interact()
	StalkerDirector.breath_override = false
	assert_true(await _wait_until(func() -> bool: return caught, 25.0), "found when not holding breath")


func test_holding_too_long_gasps() -> void:
	var check := BreathCheck.new(2.5, 4.5)
	for i in 30:
		check.update(0.1, true)  # 3 s holding while he walks over
	check.begin_check()
	var phase := check.phase
	for i in 30:
		phase = check.update(0.1, true)
	assert_eq(phase, BreathCheck.Phase.FAILED)
	assert_eq(check.fail_reason, "gasp")
	var good := BreathCheck.new(2.5, 4.5)
	good.begin_check()
	for i in 30:
		phase = good.update(0.1, true)
	assert_eq(phase, BreathCheck.Phase.PASSED)


func test_seen_entering_a_hiding_spot_is_caught() -> void:
	var room := await _setup_incoming()
	assert_true(await _wait_until(func() -> bool: return spawned_at > 0.0, 8.0))
	assert_true(
		await _wait_until(func() -> bool: return StalkerDirector.stalker_sees_player(), 2.0),
		"he can see the player"
	)
	var spot := hotspot(room, "hs_locker") as HidingSpot
	player.global_position = spot.approach_position()
	spot.interact()
	assert_true(spot.compromised or caught, "seen going in")
	# He loses sight (8 s), searches, and goes straight for the compromised spot.
	assert_true(await _wait_until(func() -> bool: return caught, 20.0))


func test_chase_follows_through_a_door_with_telegraph() -> void:
	await _setup_incoming()
	assert_true(await _wait_until(func() -> bool: return spawned_at > 0.0, 8.0))
	assert_true(
		await _wait_until(
			func() -> bool:
				return StalkerDirector.stalker and StalkerDirector.stalker.mode == ManInWhite.Mode.CHASE,
			3.0
		),
		"chasing"
	)
	spawned_at = -1.0
	var room := enter(&"T04", &"spawn_from_t02")
	var left_at := _now()
	await wait_nav_sync(room)
	assert_true(StalkerDirector.stalker == null, "not in the new room yet")
	assert_true(await _wait_until(func() -> bool: return spawned_at > 0.0, 10.0), "follows")
	assert_true(spawned_at - left_at >= StalkerDirector.MIN_TELEGRAPH_SECONDS, "with a 3 s warning")


func test_never_enters_the_safe_room() -> void:
	var room := enter(&"T01", &"spawn_from_t02")
	await wait_nav_sync(room)
	StalkerDirector.activate([&"T02", &"T03"], &"T02")
	EventBus.noise_emitted.emit(&"T01", 2)
	await wait(12.0)
	assert_eq(spawned_at, -1.0, "safe rooms are never entered")
	assert_false(caught)


func test_cannot_follow_into_a_memory() -> void:
	var room := enter(&"T02", &"spawn_from_t01")
	await wait_nav_sync(room)
	GameState.set_memory(true)
	StalkerDirector.activate([&"T02", &"T03"], &"T03")
	await wait(9.0)
	assert_eq(spawned_at, -1.0)


func test_composure_drops_when_seen_and_recovers_in_safe_room() -> void:
	await _setup_incoming()
	assert_true(await _wait_until(func() -> bool: return StalkerDirector.stalker_sees_player(), 8.0))
	var before := GameState.composure
	await wait(0.6)
	assert_true(GameState.composure < before, "seeing him lowers composure")
	StalkerDirector.reset()
	GameState.set_composure(0.5)
	var safe := enter(&"T01", &"spawn_from_t02")
	await wait(1.0)
	assert_true(GameState.composure > 0.5, "safe rooms restore composure")
	assert_eq(ComposureSystem.band(), ComposureSystem.Band.SHAKEN)
	CameraDirector.unregister_room()
	safe.queue_free()


func test_glints_are_fake_and_never_puzzle_critical() -> void:
	var room := enter(&"T03", &"spawn_from_t02")
	await wait_nav_sync(room)
	var glint := ComposureSystem.spawn_glint(room)
	assert_true(glint != null)
	assert_false(glint.is_in_group(ComposureSystem.PUZZLE_CRITICAL_GROUP))
	var texts := []
	var on_text := func(k: String) -> void: texts.append(k)
	EventBus.text_requested.connect(on_text)
	glint.interact()
	EventBus.text_requested.disconnect(on_text)
	assert_eq(texts, ["ui.glint.nothing"])
	assert_eq(GameState.free_slots(), 6, "no item given")
