class_name P12Logic
extends PuzzleLogic
## P12 Isolation cells: knocks come from the five cell doors in a sequence; open the
## peepholes in that order. Each knock also shakes dust from its door (visual alternative,
## rule R6). A wrong door makes noise and starts the sequence over (never locks).
## params.length (3/4/6). values: knocks (6 values 0-4).

const DOORS := 5

var progress := 0


func length() -> int:
	return int(params.get("length", 4))


## The sequence, with no door knocking twice in a row.
func sequence() -> Array:
	var raw: Array = values.get(&"knocks", [0, 1, 2, 3, 4, 0])
	var result := []
	for i in length():
		var d := int(raw[i % raw.size()])
		if not result.is_empty() and d == result[-1]:
			d = (d + 1) % DOORS
		result.append(d)
	return result


## Opens a peephole. Returns false (and restarts) on a wrong door.
func open(door: int) -> bool:
	if solved:
		return true
	if door == sequence()[progress]:
		progress += 1
		if progress >= length():
			solved = true
		return true
	progress = 0
	return false


func serialize() -> Dictionary:
	return {"progress": progress}


func deserialize(d: Dictionary) -> void:
	progress = clampi(int(d.get("progress", 0)), 0, length() - 1)


func solution() -> Variant:
	return sequence()


func apply_solution() -> bool:
	progress = 0
	for d in sequence():
		open(d)
	return solved


func random_input(rng: RandomNumberGenerator) -> void:
	var d := rng.randi() % DOORS
	if progress == length() - 1 and d == sequence()[progress]:
		d = (d + 1) % DOORS
	open(d)
