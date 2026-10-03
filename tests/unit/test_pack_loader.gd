extends TestCase
## Resource packs (docs/03-milestone-2.md §7): a .pck built at runtime with PCKPacker
## mounts and its files become loadable; a failed download leaves nothing behind.

const PACK := "user://test_packs/test_pack.pck"
const SOURCE := "user://test_packs/hello.txt"


func test_pack_mounts_and_exposes_files() -> void:
	DirAccess.make_dir_recursive_absolute("user://test_packs")
	var f := FileAccess.open(SOURCE, FileAccess.WRITE)
	f.store_string("act two")
	f.close()
	var packer := PCKPacker.new()
	assert_eq(packer.pck_start(PACK), OK)
	assert_eq(packer.add_file("res://pack_test/hello.txt", ProjectSettings.globalize_path(SOURCE)), OK)
	assert_eq(packer.flush(), OK)
	assert_false(FileAccess.file_exists("res://pack_test/hello.txt"))
	assert_true(PackLoader.load_from_file(PACK))
	assert_eq(FileAccess.get_file_as_string("res://pack_test/hello.txt"), "act two")


func test_failed_download_reports_failure() -> void:
	var loader := PackLoader.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(loader)
	var ok: bool = await loader.load_from_url("http://127.0.0.1:9/nothing.pck", "missing_pack", true)
	assert_false(ok)
	assert_false(FileAccess.file_exists("user://packs/missing_pack.pck"))
	loader.queue_free()
