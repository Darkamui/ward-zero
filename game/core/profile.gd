class_name Profile
extends RefCounted
## Player profile, separate from save slots (docs/05-milestone-4.md §3): endings seen, the
## New Game+ unlock, and the Files (documents, tapes) carried into New Game+.

static var path := "user://profile.cfg"


static func _load() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(path)
	return cfg


static func endings_seen() -> Array[String]:
	var result: Array[String] = []
	result.assign(_load().get_value("endings", "seen", []))
	return result


static func ng_plus_unlocked() -> bool:
	return not endings_seen().is_empty()


static func kept_documents() -> Array[String]:
	var result: Array[String] = []
	result.assign(_load().get_value("files", "documents", []))
	return result


static func kept_tapes() -> Array[String]:
	var result: Array[String] = []
	result.assign(_load().get_value("files", "tapes", []))
	return result


## Called when an ending plays: remembers it and the Files collected this run.
static func record_ending(ending: String) -> void:
	var cfg := _load()
	var seen: Array = cfg.get_value("endings", "seen", [])
	if not seen.has(ending):
		seen.append(ending)
	cfg.set_value("endings", "seen", seen)
	cfg.set_value("files", "documents", _union(cfg.get_value("files", "documents", []), GameState.documents))
	cfg.set_value("files", "tapes", _union(cfg.get_value("files", "tapes", []), GameState.tapes))
	var err := cfg.save(path)
	if err != OK:
		push_warning("Profile: could not save %s (%s)" % [path, error_string(err)])


static func clear() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func _union(a: Array, b: Array) -> Array:
	var result := a.duplicate()
	for x in b:
		if not result.has(x):
			result.append(x)
	return result
