extends Node
## Single source of runtime truth (ADR-007). Everything that must survive a save lives
## here, and every change goes through a method that emits a signal.
## Ids are stored as String so the state serializes to JSON unchanged.

signal flag_changed(flag: String, value: Variant)
signal inventory_changed
signal key_pouch_changed
signal bin_changed
signal document_added(document_id: String)
signal document_read(document_id: String)
signal tape_added(tape_id: String)
signal puzzle_state_changed(puzzle_id: String)
signal puzzle_solved(puzzle_id: String)
signal timeline_changed(memory: bool)
signal difficulty_changed
signal composure_changed(value: float)
signal state_loaded

const BASE_SLOTS := 6
const SATCHEL_SLOTS := 8
const THREAT_LEVELS: Array[String] = ["observer", "patient", "committed"]
const PUZZLE_LEVELS: Array[String] = ["easy", "normal", "hard"]

var flags: Dictionary = {}
## Fixed-size array. Empty slots hold "".
var inventory: Array[String] = []
var key_pouch: Array[String] = []
var bin: Array[String] = []
var documents: Array[String] = []
var documents_read: Array[String] = []
var tapes: Array[String] = []
## room id -> { "taken": [pickup ids], "opened": [exit ids], "vars": {} }
var room_states: Dictionary = {}
## puzzle id -> { "solved": bool, "data": {puzzle-specific} }
var puzzle_states: Dictionary = {}
var threat_difficulty: String = "patient"
var puzzle_difficulty: String = "normal"
var current_room: String = ""
var current_spawn: String = ""
var memory: bool = false
## 1.0 = Steady. Thresholds live in ComposureSystem.
var composure: float = 1.0
var stalker: Dictionary = {}
var play_time: float = 0.0
var ng_plus: int = 0


func _ready() -> void:
	reset()


func _process(delta: float) -> void:
	if current_room != "" and not get_tree().paused:
		play_time += delta


## Back to a blank new-game state. Does not touch Seed.
func reset() -> void:
	flags = {}
	inventory = []
	inventory.resize(BASE_SLOTS)
	inventory.fill("")
	key_pouch = []
	bin = []
	documents = []
	documents_read = []
	tapes = []
	room_states = {}
	puzzle_states = {}
	threat_difficulty = "patient"
	puzzle_difficulty = "normal"
	current_room = ""
	current_spawn = ""
	memory = false
	composure = 1.0
	stalker = {}
	play_time = 0.0
	ng_plus = 0


# --- Flags -------------------------------------------------------------------


func get_flag(flag: String, default: Variant = false) -> Variant:
	return flags.get(flag, default)


func set_flag(flag: String, value: Variant = true) -> void:
	if flags.has(flag) and values_equal(flags[flag], value):
		return
	flags[flag] = value
	flag_changed.emit(flag, value)


## Equality that never errors on mismatched types (GDScript 4 raises on 1 == "a").
static func values_equal(a: Variant, b: Variant) -> bool:
	return typeof(a) == typeof(b) and a == b


# --- Difficulty --------------------------------------------------------------


func set_difficulty(threat: String, puzzle: String) -> void:
	assert(threat in THREAT_LEVELS, "unknown threat difficulty %s" % threat)
	assert(puzzle in PUZZLE_LEVELS, "unknown puzzle difficulty %s" % puzzle)
	threat_difficulty = threat
	puzzle_difficulty = puzzle
	difficulty_changed.emit()


# --- Items -------------------------------------------------------------------


func slot_count() -> int:
	return inventory.size()


## Grows the inventory to the Satchel size. Never shrinks.
func set_slot_count(count: int) -> void:
	var old := inventory.size()
	if count <= old:
		return
	inventory.resize(count)
	for i in range(old, count):
		inventory[i] = ""
	inventory_changed.emit()


func free_slots() -> int:
	return inventory.count("")


func has_item(item_id: String) -> bool:
	return inventory.has(item_id) or key_pouch.has(item_id)


func is_key_pouch_item(item_id: String) -> bool:
	var item: ItemData = ContentDB.get_item(item_id)
	if item == null:
		push_warning("GameState: unknown item '%s', treating as slot item" % item_id)
		return false
	return item.storage == ItemData.Storage.KEY_POUCH


## Adds an item. Returns false (and changes nothing) when the slots are full.
func give_item(item_id: String) -> bool:
	if is_key_pouch_item(item_id):
		if not key_pouch.has(item_id):
			key_pouch.append(item_id)
			key_pouch_changed.emit()
		return true
	var slot := inventory.find("")
	if slot == -1:
		return false
	inventory[slot] = item_id
	inventory_changed.emit()
	return true


## Removes one instance. Returns false if the item was not held.
func remove_item(item_id: String) -> bool:
	var slot := inventory.find(item_id)
	if slot != -1:
		inventory[slot] = ""
		inventory_changed.emit()
		return true
	if key_pouch.has(item_id):
		key_pouch.erase(item_id)
		key_pouch_changed.emit()
		return true
	return false


## Replaces the item in a slot (used by combine). Returns false if the slot is empty.
func replace_slot(slot: int, item_id: String) -> bool:
	if slot < 0 or slot >= inventory.size() or inventory[slot] == "":
		return false
	inventory[slot] = item_id
	inventory_changed.emit()
	return true


func move_to_bin(slot: int) -> bool:
	if slot < 0 or slot >= inventory.size() or inventory[slot] == "":
		return false
	bin.append(inventory[slot])
	inventory[slot] = ""
	inventory_changed.emit()
	bin_changed.emit()
	return true


func take_from_bin(index: int) -> bool:
	if index < 0 or index >= bin.size():
		return false
	var slot := inventory.find("")
	if slot == -1:
		return false
	inventory[slot] = bin[index]
	bin.remove_at(index)
	inventory_changed.emit()
	bin_changed.emit()
	return true


## Fragment ids (F01..F12) of fragment items held in the key pouch.
func fragments() -> Array[String]:
	var result: Array[String] = []
	for item_id in key_pouch:
		var item: ItemData = ContentDB.get_item(item_id)
		if item != null and item.kind == ItemData.Kind.FRAGMENT and item.fragment_id != &"":
			result.append(String(item.fragment_id))
	return result


# --- Files -------------------------------------------------------------------


func add_document(document_id: String) -> void:
	if documents.has(document_id):
		return
	documents.append(document_id)
	document_added.emit(document_id)


func mark_document_read(document_id: String) -> void:
	if documents_read.has(document_id):
		return
	documents_read.append(document_id)
	document_read.emit(document_id)


func add_tape(tape_id: String) -> void:
	if tapes.has(tape_id):
		return
	tapes.append(tape_id)
	tape_added.emit(tape_id)


# --- Rooms -------------------------------------------------------------------


func room_state(room_id: String) -> Dictionary:
	if not room_states.has(room_id):
		room_states[room_id] = {"taken": [], "opened": [], "vars": {}}
	return room_states[room_id]


func mark_taken(room_id: String, pickup_id: String) -> void:
	var taken: Array = room_state(room_id)["taken"]
	if not taken.has(pickup_id):
		taken.append(pickup_id)


func is_taken(room_id: String, pickup_id: String) -> bool:
	return room_states.has(room_id) and room_states[room_id]["taken"].has(pickup_id)


func mark_exit_opened(room_id: String, exit_id: String) -> void:
	var opened: Array = room_state(room_id)["opened"]
	if not opened.has(exit_id):
		opened.append(exit_id)


func is_exit_opened(room_id: String, exit_id: String) -> bool:
	return room_states.has(room_id) and room_states[room_id]["opened"].has(exit_id)


func set_location(room_id: String, spawn: String) -> void:
	current_room = room_id
	current_spawn = spawn


func in_memory() -> bool:
	return memory


func set_memory(value: bool) -> void:
	if memory == value:
		return
	memory = value
	timeline_changed.emit(value)


# --- Puzzles -----------------------------------------------------------------


func get_puzzle_data(puzzle_id: String) -> Dictionary:
	return puzzle_states.get(puzzle_id, {}).get("data", {})


func set_puzzle_data(puzzle_id: String, data: Dictionary) -> void:
	var entry: Dictionary = puzzle_states.get(puzzle_id, {"solved": false, "data": {}})
	entry["data"] = data.duplicate(true)
	puzzle_states[puzzle_id] = entry
	puzzle_state_changed.emit(puzzle_id)


func is_puzzle_solved(puzzle_id: String) -> bool:
	return puzzle_states.get(puzzle_id, {}).get("solved", false)


func mark_puzzle_solved(puzzle_id: String) -> void:
	if is_puzzle_solved(puzzle_id):
		return
	var entry: Dictionary = puzzle_states.get(puzzle_id, {"solved": false, "data": {}})
	entry["solved"] = true
	puzzle_states[puzzle_id] = entry
	puzzle_solved.emit(puzzle_id)


# --- Composure ---------------------------------------------------------------


func set_composure(value: float) -> void:
	value = clampf(value, 0.0, 1.0)
	if is_equal_approx(value, composure):
		return
	composure = value
	composure_changed.emit(value)


# --- Serialization -----------------------------------------------------------


func to_dict() -> Dictionary:
	return {
		"seed": Seed.current,
		"difficulty": {"threat": threat_difficulty, "puzzle": puzzle_difficulty},
		"room": current_room,
		"spawn": current_spawn,
		"memory": memory,
		"flags": flags.duplicate(true),
		"inventory": inventory.duplicate(),
		"key_pouch": key_pouch.duplicate(),
		"bin": bin.duplicate(),
		"documents": documents.duplicate(),
		"documents_read": documents_read.duplicate(),
		"tapes": tapes.duplicate(),
		"rooms": room_states.duplicate(true),
		"puzzles": puzzle_states.duplicate(true),
		"composure": composure,
		"stalker": stalker.duplicate(true),
		"play_time": play_time,
		"ng_plus": ng_plus,
	}


## Restores from a dict produced by to_dict() (after SaveSystem migration).
func from_dict(d: Dictionary) -> void:
	reset()
	Seed.set_seed(int(d.get("seed", 0)))
	var diff: Dictionary = d.get("difficulty", {})
	threat_difficulty = diff.get("threat", "patient")
	puzzle_difficulty = diff.get("puzzle", "normal")
	current_room = d.get("room", "")
	current_spawn = d.get("spawn", "")
	memory = d.get("memory", false)
	flags = d.get("flags", {}).duplicate(true)
	inventory = _strings(d.get("inventory", []))
	if inventory.size() < BASE_SLOTS:
		var old := inventory.size()
		inventory.resize(BASE_SLOTS)
		for i in range(old, BASE_SLOTS):
			inventory[i] = ""
	key_pouch = _strings(d.get("key_pouch", []))
	bin = _strings(d.get("bin", []))
	documents = _strings(d.get("documents", []))
	documents_read = _strings(d.get("documents_read", []))
	tapes = _strings(d.get("tapes", []))
	room_states = d.get("rooms", {}).duplicate(true)
	puzzle_states = d.get("puzzles", {}).duplicate(true)
	composure = float(d.get("composure", 1.0))
	stalker = d.get("stalker", {}).duplicate(true)
	play_time = float(d.get("play_time", 0.0))
	ng_plus = int(d.get("ng_plus", 0))
	state_loaded.emit()


static func _strings(arr: Array) -> Array[String]:
	var result: Array[String] = []
	for v in arr:
		result.append(String(v) if v != null else "")
	return result
