class_name P21Logic
extends PuzzleLogic
## P21 Archive Vault: rebuild your own file. Place each collected truth fragment on the
## timeline, 1975 to 1998. Placing them always "solves" the vault; the number placed
## correctly decides the ending (GDD §2.4). params.available is set from the fragments the
## player holds.

const TIMELINE := ["F04", "F02", "F11", "F01", "F05", "F03", "F06", "F08", "F10", "F07", "F09", "F12"]
const YEARS := [1975, 1976, 1976, 1976, 1976, 1977, 1978, 1979, 1984, 1998, 1998, 1998]

var slots: Array = []
var available: Array = []
var score := -1


func _setup() -> void:
	slots = []
	for i in TIMELINE.size():
		slots.append("")
	available = params.get("available", TIMELINE.duplicate())


func place(slot: int, fragment: String) -> void:
	if slot < 0 or slot >= TIMELINE.size() or (fragment != "" and not available.has(fragment)):
		return
	var old := slots.find(fragment)
	if fragment != "" and old != -1:
		slots[old] = ""
	slots[slot] = fragment


func correct_count() -> int:
	var n := 0
	for i in slots.size():
		if slots[i] != "" and slots[i] == TIMELINE[i]:
			n += 1
	return n


## Seals the file. Always succeeds; records the score.
func seal() -> bool:
	score = correct_count()
	solved = true
	return true


func serialize() -> Dictionary:
	return {"slots": slots.duplicate(), "score": score}


func deserialize(d: Dictionary) -> void:
	var s: Array = d.get("slots", [])
	if s.size() == TIMELINE.size():
		slots = []
		for x in s:
			slots.append(String(x))
	score = int(d.get("score", -1))


func solution() -> Variant:
	var result := []
	for i in TIMELINE.size():
		result.append(TIMELINE[i] if available.has(TIMELINE[i]) else "")
	return result


func apply_solution() -> bool:
	var s: Array = solution()
	for i in s.size():
		place(i, s[i])
	return seal()


func random_input(rng: RandomNumberGenerator) -> void:
	if available.is_empty():
		return
	place(rng.randi() % TIMELINE.size(), available[rng.randi() % available.size()])
