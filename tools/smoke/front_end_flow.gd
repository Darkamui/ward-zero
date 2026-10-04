extends RefCounted
## Exercise real scene changes without touching the user's save slots or settings.


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	var save_dir_before := SaveSystem.save_dir
	SaveSystem.save_dir = "user://test_front_end_flow"
	var title: Control = load("res://game/main/title.tscn").instantiate()
	tree.root.add_child(title)
	tree.current_scene = title
	title._begin(false)
	title._choose("threat", "observer")
	title._choose("puzzle", "hard")
	await tree.process_frame
	title._start()
	title._start()
	await tree.create_timer(0.2).timeout
	var intro := tree.current_scene
	var success := intro.scene_file_path == "res://game/main/act1_intro.tscn"
	var seed_before := Seed.current
	if success:
		var event := InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.physical_keycode = KEY_ESCAPE
		event.pressed = true
		tree.root.push_input(event)
		event = event.duplicate()
		event.pressed = false
		tree.root.push_input(event)
		await tree.create_timer(1.6).timeout
		success = tree.current_scene.scene_file_path == "res://game/main/game.tscn"
		success = success and GameState.current_room == "G01" and Seed.current == seed_before
		success = (
			success and GameState.threat_difficulty == "observer" and GameState.puzzle_difficulty == "hard"
		)
		success = success and GameState.has_item("item_dictaphone") and GameState.has_item("item_wristband")
		success = success and bool(GameState.get_flag("intro.done"))
	for slot in SaveSystem.SLOT_COUNT:
		SaveSystem.delete_slot(slot)
	SaveSystem.save_dir = save_dir_before
	if success:
		print("PASS: New Game -> Act I -> Dayroom; seed, difficulty, items and opening tape preserved")
	else:
		push_error("Front-end scene flow failed")
	return 0 if success else 1
