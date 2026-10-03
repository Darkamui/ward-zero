extends RefCounted
## Capture the actual PuzzleHost at 1080p and 720p, without writing a save or settings.

const OUT := "res://production/art-review/p01_radio"


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	DirAccess.make_dir_recursive_absolute(OUT)
	var old_locale := TranslationServer.get_locale()
	GameState.reset()
	Seed.set_seed(12345)
	var host := PuzzleHost.new()
	tree.root.add_child(host)
	for locale in ["en", "fr_CA"]:
		TranslationServer.set_locale(locale)
		for difficulty in ["normal", "easy"]:
			GameState.set_difficulty("patient", difficulty)
			host.open(&"P01")
			await tree.create_timer(0.2).timeout
			await RenderingServer.frame_post_draw
			var path := OUT.path_join("%s_%s_%d.png" % [locale, difficulty, tree.root.size.y])
			tree.root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
			print("p01_art_screens: ", path)
			host.close()
			await tree.process_frame
	TranslationServer.set_locale(old_locale)
	host.queue_free()
	return 0
