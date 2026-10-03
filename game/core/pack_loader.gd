class_name PackLoader
extends Node
## Per-act resource packs (GDD §9.4, docs/03-milestone-2.md §7): download a .pck to
## user://packs/ and mount it with ProjectSettings.load_resource_pack. Add as a child
## (for HTTPRequest) and await load_from_url().

signal progress(fraction: float)
signal finished(ok: bool)

const DIR := "user://packs"

var _http: HTTPRequest


func _ready() -> void:
	_http = HTTPRequest.new()
	_http.use_threads = false
	add_child(_http)


## Downloads and mounts a pack. Re-uses a previous download of the same name.
func load_from_url(url: String, pack_name: String, force_download := false) -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := DIR.path_join(pack_name + ".pck")
	if force_download or not FileAccess.file_exists(path):
		var done := [false, 0, 0]  # finished, result, HTTP code
		_http.request_completed.connect(
			func(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray) -> void:
				done[0] = true
				done[1] = result
				done[2] = code,
			CONNECT_ONE_SHOT
		)
		_http.download_file = path
		if _http.request(url) != OK:
			finished.emit(false)
			return false
		while not done[0]:
			var total := _http.get_body_size()
			if total > 0:
				progress.emit(float(_http.get_downloaded_bytes()) / total)
			await get_tree().process_frame
		if done[1] != HTTPRequest.RESULT_SUCCESS or done[2] != 200:
			DirAccess.remove_absolute(path)
			finished.emit(false)
			return false
	var ok := load_from_file(path)
	progress.emit(1.0)
	finished.emit(ok)
	return ok


static func load_from_file(path: String) -> bool:
	return ProjectSettings.load_resource_pack(path, true)
