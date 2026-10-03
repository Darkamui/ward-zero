extends RefCounted
## Screenshots the Act 2 close-ups (production/screens/m3_*.png, not committed).

const OUT := "res://production/screens"
const IDS := [&"P06", &"P07", &"P08", &"P08L", &"P09", &"P10", &"P11", &"P12", &"P13"]


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	NewGame.start("patient", "normal", 4242)
	var game: Node = load("res://game/main/game.tscn").instantiate()
	tree.root.add_child(game)
	await tree.create_timer(1.2).timeout
	for id in IDS:
		EventBus.puzzle_requested.emit(id)
		await tree.create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var img := tree.root.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path("%s/m3_%s.png" % [OUT, String(id).to_lower()]))
		game.puzzle_host.close()
	return 0
