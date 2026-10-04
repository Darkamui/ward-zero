extends RefCounted
## Capture the actual screens without modifying saves or persisted preferences.

const OUT := "res://production/art-review/front_end"
var _tree: SceneTree


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	_tree = tree
	DirAccess.make_dir_recursive_absolute(OUT)
	var locale_before := TranslationServer.get_locale()
	var setting_before: String = Settings.get_value("locale")
	for locale in ["en", "fr_CA"]:
		Settings.values["locale"] = locale
		TranslationServer.set_locale(locale)
		var title: Control = load("res://game/main/title.tscn").instantiate()
		tree.root.add_child(title)
		await _shot(locale + "_main")
		title._begin(false)
		await _shot(locale + "_new_game")
		title._options()
		await _shot(locale + "_options_audio")
		title._options_panel._select_tab("display")
		await _shot(locale + "_options_display")
		title._options_panel._select_tab("accessibility")
		await _shot(locale + "_options_accessibility")
		title.queue_free()
		await tree.process_frame
		var intro: Control = load("res://game/main/act1_intro.tscn").instantiate()
		tree.root.add_child(intro)
		await _shot(locale + "_intro")
		intro.queue_free()
		await tree.process_frame
	TranslationServer.set_locale(locale_before)
	Settings.values["locale"] = setting_before
	return 0


func _shot(filename: String) -> void:
	await _tree.create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var path := OUT.path_join("%s_%d.png" % [filename, _tree.root.size.y])
	_tree.root.get_texture().get_image().save_png(path)
	print("front_end_screens: ", path)
