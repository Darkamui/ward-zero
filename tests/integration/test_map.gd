extends RoomTestBase
## Map status (GDD §3.5, docs/03-milestone-2.md §6).


func test_g01_unresolved_until_radio_solved() -> void:
	var room := load_room(&"G01", &"spawn_start")
	var reasons := MapStatus.reasons(room)
	assert_has(reasons, "puzzle:P01")
	assert_has(reasons, "locked:to_g02")
	GameState.mark_puzzle_solved("P01")
	GameState.set_flag("g01.chain_released")
	assert_eq(MapStatus.compute(room), MapStatus.CLEARED)


func test_pickups_count_only_when_available() -> void:
	GameState.set_difficulty("patient", "normal")
	var room := load_room(&"G03", &"spawn_from_g02")
	assert_false(MapStatus.reasons(room).has("pickup:hs_blank_cassette"), "Committed-only pickup ignored")
	GameState.set_difficulty("committed", "normal")
	assert_has(MapStatus.reasons(room), "pickup:hs_blank_cassette")


func test_status_stored_on_leaving() -> void:
	load_room(&"G01", &"spawn_start")
	load_room(&"G02", &"spawn_from_g01")
	assert_eq(MapStatus.stored("G01"), MapStatus.UNRESOLVED)


func test_map_shows_visited_rooms_only() -> void:
	enter(&"G01", &"spawn_start")
	var map := MapUi.new()
	tree().root.add_child(map)
	map.open()
	assert_eq(map.shown_rooms(), [&"G01"])
	map.close()
	enter(&"G02", &"spawn_from_g01")
	map.open()
	assert_has(map.shown_rooms(), &"G02")
	map.close()
	map.free()
