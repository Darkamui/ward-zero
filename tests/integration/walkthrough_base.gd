class_name WalkthroughBase
extends RoomTestBase
## Helpers for critical-path tests that play acts through game systems: starting states,
## solving puzzles through PuzzleBase (rewards included), walking through exits.


func before_each() -> void:
	super.before_each()
	SaveSystem.save_dir = "user://test_saves"


func after_each() -> void:
	for slot in SaveSystem.SLOT_COUNT:
		SaveSystem.delete_slot(slot)
	SaveSystem.save_dir = SaveSystem.SAVE_DIR
	super.after_each()


func _act1_done(threat: String, puzzle: String, s: int) -> void:
	NewGame.start(threat, puzzle, s)
	for item in [
		"item_photograph",
		"item_choleric_key",
		"item_music_box_crank",
		"item_f01_admission_file",
		"item_f02_fire_clipping"
	]:
		GameState.give_item(item)
	for flag in [
		"g01.chain_released", "g02.gate_open", "act1.chase_done", "g02.barricade_broken", "g06.loft_open"
	]:
		GameState.set_flag(flag)
	for p in ["P01", "P02", "P03", "P04", "P05"]:
		GameState.mark_puzzle_solved(p)


func _solve(puzzle_id: StringName) -> void:
	var data := ContentDB.get_puzzle(puzzle_id)
	var pb := PuzzleBase.new()
	pb.data = data
	pb.logic = PuzzleValues.make_logic(data)
	var ok := pb.logic.apply_solution()
	assert_true(ok, "%s solution accepted" % puzzle_id)
	pb.report_attempt(ok)
	pb.free()


func _go(room: Room, exit_hotspot: String) -> Room:
	var h := hotspot(room, exit_hotspot)
	assert_true(h != null, "%s has %s" % [room.room_id(), exit_hotspot])
	assert_false(h.is_locked(), "%s/%s unlocked" % [room.room_id(), exit_hotspot])
	var e := h.exit_def()
	return enter(e.target_room, e.target_spawn)


func _use(room: Room, hotspot_name: String) -> void:
	var h := hotspot(room, hotspot_name)
	assert_true(h.is_active(), "%s/%s active" % [room.room_id(), hotspot_name])
	h.interact()


func _shift(room: Room, anchor_spot: String, anchor: StringName) -> void:
	hotspot(room, anchor_spot).use_item(anchor)
	await wait(1.4)
	assert_true(GameState.in_memory(), "%s shifts to 1976" % room.room_id())


func _unshift(room: Room, anchor_spot: String) -> void:
	hotspot(room, anchor_spot).interact()
	await wait(1.4)
	assert_false(GameState.in_memory())


## State at the end of Act 2 (docs/04-milestone-3.md §2), F03 included.
func _act2_done(threat: String, puzzle: String, s: int) -> void:
	_act1_done(threat, puzzle, s)
	GameState.set_slot_count(GameState.SATCHEL_SLOTS)
	for item in [
		"item_melancholic_key",
		"item_phlegmatic_key",
		"item_ribbon",
		"item_cylinder",
		"item_f03_nurse_log",
		"item_f04_drawing",
		"item_f05_essay",
		"item_f06_scratchings",
		"item_f07_tape",
	]:
		GameState.give_item(item)
	for flag in ["act2.started", "b01.power_on", "b01.shortcut_open"]:
		GameState.set_flag(flag)
	for p in ["P06", "P07", "P08", "P08L", "P09", "P10", "P11", "P12", "P13"]:
		GameState.mark_puzzle_solved(p)
