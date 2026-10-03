extends Node
## Saves GameState as JSON under user:// (IndexedDB in the browser), and exports or
## imports saves as a text string because browsers can clear IndexedDB (GDD §9.2).

signal saved(slot: int)
signal loaded(slot: int)

enum SaveError { OK, NO_SAVE, BAD_FORMAT, BAD_CHECKSUM, TOO_NEW, WRITE_FAILED }

const VERSION := 1
const SLOT_COUNT := 10
## Slot used for act-start and room-entry autosaves.
const AUTOSAVE_SLOT := 0
const EXPORT_PREFIX := "WZ1"
const SAVE_DIR := "user://saves"

## Overridable by tests so they never touch real saves.
var save_dir: String = SAVE_DIR


func slot_path(slot: int) -> String:
	return save_dir.path_join("slot_%02d.json" % slot)


func has_save(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func save(slot: int) -> SaveError:
	assert(slot >= 0 and slot < SLOT_COUNT)
	DirAccess.make_dir_recursive_absolute(save_dir)
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: cannot write %s (%s)" % [slot_path(slot), FileAccess.get_open_error()])
		return SaveError.WRITE_FAILED
	file.store_string(JSON.stringify(build_save_dict()))
	file.close()
	saved.emit(slot)
	return SaveError.OK


func load_slot(slot: int) -> SaveError:
	if not has_save(slot):
		return SaveError.NO_SAVE
	var text := FileAccess.get_file_as_string(slot_path(slot))
	var result := apply_save_json(text)
	if result == SaveError.OK:
		loaded.emit(slot)
	return result


func delete_slot(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(slot_path(slot))


## Summary for the load menu: { slot, room, play_time, saved_at, locale } per used slot.
func list_slots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in SLOT_COUNT:
		if not has_save(slot):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
		if parsed is Dictionary:
			(
				result
				. append(
					{
						"slot": slot,
						"room": parsed.get("room", ""),
						"play_time": parsed.get("play_time", 0.0),
						"saved_at": parsed.get("saved_at", ""),
						"locale": parsed.get("locale", ""),
					}
				)
			)
	return result


func build_save_dict() -> Dictionary:
	var d := GameState.to_dict()
	d["version"] = VERSION
	d["saved_at"] = Time.get_datetime_string_from_system(true)
	d["locale"] = TranslationServer.get_locale()
	return d


func apply_save_json(text: String) -> SaveError:
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return SaveError.BAD_FORMAT
	var d: Dictionary = parsed
	var version := int(d.get("version", 0))
	if version > VERSION:
		return SaveError.TOO_NEW
	if version < 1:
		return SaveError.BAD_FORMAT
	GameState.from_dict(migrate(d, version))
	return SaveError.OK


## Upgrades an old save dict step by step. Add _migrate_vN_to_vN+1 per schema bump.
func migrate(d: Dictionary, from_version: int) -> Dictionary:
	var v := from_version
	# while v < VERSION:
	# 	match v:
	# 		1: d = _migrate_v1_to_v2(d)
	# 	v += 1
	d["version"] = v
	return d


# --- Text export/import -------------------------------------------------------
# Format: "WZ1-<8 hex sha256 of payload>-<base64 of deflate(json)>"


func export_string() -> String:
	var bytes := JSON.stringify(build_save_dict()).to_utf8_buffer()
	var packed := bytes.compress(FileAccess.COMPRESSION_DEFLATE)
	return "%s-%s-%s" % [EXPORT_PREFIX, _checksum(packed), Marshalls.raw_to_base64(packed)]


## Parses and verifies an exported string without applying it.
func decode_export(text: String) -> Dictionary:
	var parts := text.strip_edges().split("-", false, 2)
	if parts.size() != 3 or parts[0] != EXPORT_PREFIX:
		return {"error": SaveError.BAD_FORMAT}
	var packed := Marshalls.base64_to_raw(parts[2])
	if packed.is_empty():
		return {"error": SaveError.BAD_FORMAT}
	if _checksum(packed) != parts[1]:
		return {"error": SaveError.BAD_CHECKSUM}
	var raw := packed.decompress_dynamic(-1, FileAccess.COMPRESSION_DEFLATE)
	if raw.is_empty():
		return {"error": SaveError.BAD_FORMAT}
	return {"error": SaveError.OK, "json": raw.get_string_from_utf8()}


func import_string(text: String) -> SaveError:
	var decoded := decode_export(text)
	if decoded["error"] != SaveError.OK:
		return decoded["error"]
	return apply_save_json(decoded["json"])


func error_key(err: SaveError) -> String:
	match err:
		SaveError.NO_SAVE:
			return "ui.save.error_no_save"
		SaveError.BAD_FORMAT:
			return "ui.save.error_bad_format"
		SaveError.BAD_CHECKSUM:
			return "ui.save.error_bad_checksum"
		SaveError.TOO_NEW:
			return "ui.save.error_too_new"
		SaveError.WRITE_FAILED:
			return "ui.save.error_write_failed"
	return ""


static func _checksum(bytes: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode().substr(0, 8)
