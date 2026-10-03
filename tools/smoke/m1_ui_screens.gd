extends RefCounted
## Screenshots every M1 UI for visual review (production/screens/m1_*.png).
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --audio-driver Dummy \
##       --resolution 1920x1080 res://tools/run_tool.tscn -- res://tools/smoke/m1_ui_screens.gd [fr_CA]

const OUT := "res://production/screens"

var _tree: SceneTree


func run(tree: SceneTree, args: PackedStringArray) -> int:
	_tree = tree
	var locale := args[0] if args.size() > 0 else "en"
	Settings.set_value("locale", locale)
	var suffix := "" if locale == "en" else "_" + locale
	var title: Node = load("res://game/main/title.tscn").instantiate()
	tree.root.add_child(title)
	await _wait(0.3)
	await _shot("m1_title" + suffix)
	title.queue_free()
	NewGame.start("patient", "normal", 12345)
	var game: Node = load("res://game/main/game.tscn").instantiate()
	tree.root.add_child(game)
	await _wait(1.2)
	for id in [&"P01", &"P02", &"P03", &"P04", &"P05"]:
		EventBus.puzzle_requested.emit(id)
		await _wait(0.2)
		await _shot("m1_puzzle_%s%s" % [String(id).to_lower(), suffix])
		game.puzzle_host.close()
	EventBus.document_requested.emit(&"doc_quiet_hours")
	await _wait(0.2)
	await _shot("m1_document" + suffix)
	game.document_viewer.close()
	GameState.give_item("item_music_box_crank")
	game.inventory.open(true)
	game.inventory._select("item_music_box_crank")
	await _wait(0.2)
	await _shot("m1_inventory_bin" + suffix)
	game.inventory.close()
	GameState.add_document("doc_f01_admission_file")
	game.files.open()
	await _wait(0.2)
	await _shot("m1_files" + suffix)
	game.files.close()
	EventBus.ui_requested.emit(&"save_screen")
	await _wait(0.2)
	await _shot("m1_save_screen" + suffix)
	game.save_screen.close()
	EventBus.tape_requested.emit(&"tape_01_claire")
	await _wait(4.0)
	await _shot("m1_tape_subtitle" + suffix)
	for r in ["G02", "G03", "G04", "G05", "G06"]:
		GameState.set_flag("%s.visited" % r.to_lower(), true)
	GameState.room_state("G03")["status"] = MapStatus.CLEARED
	game.map.open()
	await _wait(0.2)
	await _shot("m1_map" + suffix)
	game.map.close()
	var options := OptionsPanel.new()
	game.add_child(options)
	await _wait(0.2)
	await _shot("m1_options" + suffix)
	return 0


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := _tree.root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT.path_join(shot_name + ".png")))
	print("m1_ui_screens: ", shot_name)


func _wait(seconds: float) -> void:
	await _tree.create_timer(seconds).timeout
