extends RefCounted
## Review supplied item models and localized seeded documents in their real UI hosts.

const OUT := "res://production/art-review/g01_items"
var _tree: SceneTree


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	_tree = tree
	DirAccess.make_dir_recursive_absolute(OUT)
	var old_locale := TranslationServer.get_locale()
	GameState.reset()
	Seed.set_seed(12345)
	GameState.give_item("item_dictaphone")
	GameState.give_item("item_wristband")
	var inventory := InventoryUi.new()
	var reader := DocumentViewer.new()
	tree.root.add_child(inventory)
	tree.root.add_child(reader)
	for locale in ["en", "fr_CA"]:
		TranslationServer.set_locale(locale)
		inventory.open()
		for id in ["item_dictaphone", "item_wristband"]:
			inventory._select(id)
			inventory._on_examine()
			await _shot(locale + "_" + id)
			if id == "item_wristband":
				inventory._examine.rotate_by(Vector2(PI, 0))
				# The first discovery opens the reader; close it to inspect the inner face.
				if not reader.is_open():
					reader.open(&"doc_wristband_note")
				await _shot(locale + "_wristband_reading")
				reader.close()
				await _shot(locale + "_wristband_inside")
			inventory._close_examine()
		inventory.close()
		for difficulty in ["normal", "hard"]:
			GameState.set_difficulty("patient", difficulty)
			reader.open(&"doc_quiet_hours")
			await _shot(locale + "_quiet_hours_" + difficulty)
			for i in 4:
				reader.change_text_size(1)
			await _shot(locale + "_quiet_hours_" + difficulty + "_large")
			reader._scroll.scroll_vertical = 10000
			await _shot(locale + "_quiet_hours_" + difficulty + "_large_end")
			for i in 4:
				reader.change_text_size(-1)
			reader.close()
			await tree.process_frame
	inventory.queue_free()
	reader.queue_free()
	TranslationServer.set_locale(old_locale)
	return 0


func _shot(filename: String) -> void:
	await _tree.create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var path := OUT.path_join("%s_%d.png" % [filename, _tree.root.size.y])
	_tree.root.get_texture().get_image().save_png(path)
	print("g01_item_screens: ", path)
