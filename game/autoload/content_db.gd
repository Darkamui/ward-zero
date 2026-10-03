extends Node
## Index of all data resources by id. Scans the data folders on startup.
## Tests and debug tools can register extra resources at runtime.

const ITEMS_DIR := "res://game/data/items"
const DOCUMENTS_DIR := "res://game/data/documents"
const TAPES_DIR := "res://game/data/tapes"
const PUZZLES_DIR := "res://game/data/puzzles"
const ROOMS_DIR := "res://game/rooms"

var items: Dictionary[StringName, ItemData] = {}
var documents: Dictionary[StringName, DocumentData] = {}
var tapes: Dictionary[StringName, TapeData] = {}
var puzzles: Dictionary[StringName, PuzzleData] = {}
var rooms: Dictionary[StringName, RoomData] = {}


func _ready() -> void:
	reload()


func reload() -> void:
	items.clear()
	documents.clear()
	tapes.clear()
	puzzles.clear()
	rooms.clear()
	for res in _load_dir(ITEMS_DIR):
		if res is ItemData:
			register_item(res)
	for res in _load_dir(DOCUMENTS_DIR):
		if res is DocumentData:
			register_document(res)
	for res in _load_dir(TAPES_DIR):
		if res is TapeData:
			register_tape(res)
	for res in _load_dir(PUZZLES_DIR):
		if res is PuzzleData:
			register_puzzle(res)
	for res in _load_dir(ROOMS_DIR, true, "room_data.tres"):
		if res is RoomData:
			register_room(res)


func register_item(item: ItemData) -> void:
	_check_dup(items, item.id, "item")
	items[item.id] = item


func register_document(doc: DocumentData) -> void:
	_check_dup(documents, doc.id, "document")
	documents[doc.id] = doc


func register_tape(tape: TapeData) -> void:
	_check_dup(tapes, tape.id, "tape")
	tapes[tape.id] = tape


func register_puzzle(puzzle: PuzzleData) -> void:
	_check_dup(puzzles, puzzle.id, "puzzle")
	puzzles[puzzle.id] = puzzle


func register_room(room: RoomData) -> void:
	_check_dup(rooms, room.id, "room")
	rooms[room.id] = room


func get_item(id: StringName) -> ItemData:
	return items.get(id)


func get_document(id: StringName) -> DocumentData:
	return documents.get(id)


func get_tape(id: StringName) -> TapeData:
	return tapes.get(id)


func get_puzzle(id: StringName) -> PuzzleData:
	return puzzles.get(id)


func get_room(id: StringName) -> RoomData:
	return rooms.get(id)


func _check_dup(dict: Dictionary, id: StringName, kind: String) -> void:
	if id == &"":
		push_error("ContentDB: %s with empty id" % kind)
	elif dict.has(id):
		push_warning("ContentDB: duplicate %s id '%s', replacing" % [kind, id])


## Loads every .tres/.res in dir (or only files named only_name). In exported builds
## files are listed as *.remap.
func _load_dir(dir_path: String, recursive := false, only_name := "") -> Array[Resource]:
	var result: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for sub in dir.get_directories():
		if recursive:
			result.append_array(_load_dir(dir_path.path_join(sub), true, only_name))
	for file in dir.get_files():
		var name := file.trim_suffix(".remap")
		if only_name != "" and name != only_name:
			continue
		if name.ends_with(".tres") or name.ends_with(".res"):
			var res := load(dir_path.path_join(name))
			if res != null:
				result.append(res)
	return result
