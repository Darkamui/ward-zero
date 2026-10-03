extends RefCounted
## Screenshots the Act 3-4 close-ups (production/screens/m4_*.png, not committed).

const OUT := "res://production/screens"
const IDS := [&"P14", &"P15", &"P16", &"P17", &"P18", &"P19", &"P20", &"P21"]


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	NewGame.start("patient", "normal", 4242)
	var game: Node = load("res://game/main/game.tscn").instantiate()
	tree.root.add_child(game)
	for item in ["item_choleric_key", "item_melancholic_key", "item_phlegmatic_key", "item_sanguine_key"]:
		GameState.give_item(item)
	for item in ["item_f01_admission_file", "item_f02_fire_clipping", "item_f04_drawing"]:
		GameState.give_item(item)
	await tree.create_timer(1.2).timeout
	for id in IDS:
		EventBus.puzzle_requested.emit(id)
		await tree.create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var img := tree.root.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("%s/m4_%s.png" % [OUT, String(id).to_lower()]))
		game.puzzle_host.close()
	return 0
