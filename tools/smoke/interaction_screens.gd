extends RefCounted
## Capture room controls in both cameras and locales at the shipping viewport size.


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	NewGame.start("patient", "normal")
	GameState.set_flag("intro.done")
	var game: Node = load("res://game/main/game.tscn").instantiate()
	tree.root.add_child(game)
	await tree.create_timer(1.0).timeout
	CameraDirector.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute("res://production/screens")
	for locale in ["en", "fr_CA"]:
		TranslationServer.set_locale(locale)
		for camera in [&"cam_a", &"cam_b"]:
			CameraDirector.cut_to(camera)
			await tree.create_timer(0.2).timeout
			await RenderingServer.frame_post_draw
			tree.root.get_texture().get_image().save_png(
				"res://production/screens/interaction_%s_%s.png" % [locale, camera]
			)
	return 0
