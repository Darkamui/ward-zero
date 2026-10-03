extends Node
## Headless test runner:  godot --headless res://tests/run_tests.tscn [-- --filter=<text>]
## Finds tests/**/test_*.gd, runs every test_* method, exits with code 1 on any failure.
## Engine or script errors raised during a test fail that test, as do allowed errors
## that a test does not expect (see TestCase.expect_errors).

const TEST_ROOT := "res://tests"
const ErrorCapture := preload("res://tests/framework/error_capture.gd")


func _ready() -> void:
	var filter := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.trim_prefix("--filter=")
	var capture := ErrorCapture.new()
	OS.add_logger(capture)
	var passed := 0
	var failed: Array[String] = []
	for path in _find_tests(TEST_ROOT):
		var script: GDScript = load(path)
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var full := "%s::%s" % [path.get_file().get_basename(), name]
			if filter != "" and not full.contains(filter):
				continue
			_reset_globals()
			capture.take()
			var test: TestCase = script.new()
			test.before_each()
			await test.call(name)
			test.after_each()
			var problems: Array[String] = test.failures.duplicate()
			var errors := capture.take()
			var allowed: int = test.get_meta("expected_errors", 0)
			if errors.size() > allowed:
				for e in errors:
					problems.append("engine error: %s" % e)
			if problems.is_empty():
				passed += 1
			else:
				failed.append("%s\n    %s" % [full, "\n    ".join(problems)])
	_reset_globals()
	OS.remove_logger(capture)
	print("")
	for f in failed:
		print("FAIL ", f)
	print("\n%d passed, %d failed" % [passed, failed.size()])
	get_tree().quit(1 if failed.size() > 0 else 0)


func _reset_globals() -> void:
	GameState.reset()
	Seed.set_seed(0)
	ContentDB.reload()


func _find_tests(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for sub in dir.get_directories():
		result.append_array(_find_tests(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd"):
			result.append(dir_path.path_join(file))
	result.sort()
	return result
