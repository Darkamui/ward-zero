extends TestCase
## Loads every script and scene under game/ and tools/ so parse errors (including
## warnings treated as errors) fail CI even when no other test touches the file.

const ROOTS := ["res://game", "res://tools", "res://tests"]


func test_every_script_and_scene_loads() -> void:
	var count := 0
	for root in ROOTS:
		for path in _files(root):
			var res := load(path)
			count += 1
			if res == null:
				fail("could not load %s" % path)
			elif res is GDScript and not (res as GDScript).can_instantiate():
				fail("script does not compile: %s" % path)
	assert_true(count > 20, "expected to check many files, checked %d" % count)


func _files(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for sub in dir.get_directories():
		result.append_array(_files(dir_path.path_join(sub)))
	for f in dir.get_files():
		if f.ends_with(".gd") or f.ends_with(".tscn"):
			result.append(dir_path.path_join(f))
	return result
