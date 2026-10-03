extends Logger
## Records engine and script errors so the runner can fail the test that caused them.

var errors: Array[String] = []
var _mutex := Mutex.new()


func _log_error(
	function: String,
	file: String,
	line: int,
	code: String,
	rationale: String,
	_editor_notify: bool,
	error_type: int,
	_script_backtrace: Array[ScriptBacktrace]
) -> void:
	if error_type == ERROR_TYPE_WARNING:
		return
	_mutex.lock()
	errors.append(
		"%s (%s:%d in %s) %s" % [rationale if rationale != "" else code, file, line, function, code]
	)
	_mutex.unlock()


func take() -> Array[String]:
	_mutex.lock()
	var result := errors.duplicate()
	errors.clear()
	_mutex.unlock()
	return result
