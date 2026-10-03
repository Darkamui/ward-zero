extends RefCounted
## Actual inventory/files hosts, with six/eight slots, storage and long bilingual lists.

const OUT := "res://production/art-review/shared_ui"
const ITEMS := [
	"item_music_box_crank",
	"item_sedatives",
	"item_blank_cassette",
	"item_fuse",
	"item_valve_wheel",
	"item_sedatives",
	"item_blank_cassette",
	"item_sedatives"
]
var _tree: SceneTree


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	_tree = tree
	DirAccess.make_dir_recursive_absolute(OUT)
	var old_locale := TranslationServer.get_locale()
	var inventory := InventoryUi.new()
	var files := FilesUi.new()
	var reader := DocumentViewer.new()
	tree.root.add_child(inventory)
	tree.root.add_child(files)
	tree.root.add_child(reader)
	for locale in ["en", "fr_CA"]:
		GameState.reset()
		Seed.set_seed(12345)
		TranslationServer.set_locale(locale)
		GameState.give_item("item_dictaphone")
		GameState.give_item("item_wristband")
		inventory.open()
		inventory._select("item_dictaphone")
		await _shot(locale + "_starting_satchel")
		inventory.close()
		await tree.process_frame
		for id in ITEMS.slice(0, 6):
			GameState.give_item(id)
		inventory.open(true)
		inventory._select("item_music_box_crank")
		await _shot(locale + "_six_slots_bin")
		inventory._on_store()
		await _shot(locale + "_stored_item")
		inventory.close()
		await tree.process_frame
		GameState.set_slot_count(8)
		GameState.take_from_bin(0)
		for id in ITEMS.slice(6):
			GameState.give_item(id)
		inventory.open()
		inventory._select("item_valve_wheel")
		await _shot(locale + "_eight_slots")
		inventory._select("item_wristband")
		inventory._on_examine()
		await _shot(locale + "_examine")
		inventory.close()
		files.open()
		await _shot(locale + "_files_empty")
		files.close()
		await tree.process_frame
		GameState.add_document("doc_quiet_hours")
		for id in ContentDB.documents:
			GameState.add_document(id)
		GameState.add_tape("tape_01_claire")
		files.open()
		files._set_tab(FilesUi.Tab.DOCUMENTS)
		await _shot(locale + "_files_documents")
		files._open_selected()
		await _shot(locale + "_files_reader")
		reader.close()
		files._set_tab(FilesUi.Tab.TAPES)
		await _shot(locale + "_files_tapes")
		files._set_tab(FilesUi.Tab.FRAGMENTS)
		await _shot(locale + "_files_fragments")
		files.close()
		await tree.process_frame
	TranslationServer.set_locale(old_locale)
	inventory.queue_free()
	files.queue_free()
	reader.queue_free()
	return 0


func _shot(filename: String) -> void:
	await _tree.create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var path := OUT.path_join("%s_%d.png" % [filename, _tree.root.size.y])
	_tree.root.get_texture().get_image().save_png(path)
	print("shared_ui_screens: ", path)
