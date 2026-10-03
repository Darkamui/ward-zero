class_name P09Logic
extends PuzzleLogic
## P09 Children's Dormitory: hang Claire's six drawings in story order, which is the order
## of the dates on their backs (Easy: on the front). Drawing 5 is missing in the present;
## in 1976 it can be hidden behind the radiator (persistent object, GDD §4.1) and then
## taken in the present. params.missing_available is set by the UI from that flag.
## values: dates (6 unique 1-28).

const COUNT := 6

var slots: Array = []
var missing_available := false


func _setup() -> void:
	slots = []
	for i in COUNT:
		slots.append(-1)


func date_of(piece: int) -> int:
	return int(values[&"dates"][piece])


func available_pieces() -> Array:
	var result := []
	for p in COUNT:
		if p < COUNT - 1 or missing_available:
			result.append(p)
	return result


func story_order() -> Array:
	var order := range(COUNT)
	order.sort_custom(func(a: int, b: int) -> bool: return date_of(a) < date_of(b))
	return order


func place(slot: int, piece: int) -> void:
	if slot < 0 or slot >= COUNT or not available_pieces().has(piece):
		return
	var old := slots.find(piece)
	if old != -1:
		slots[old] = -1
	slots[slot] = piece


func clear(slot: int) -> void:
	if slot >= 0 and slot < COUNT:
		slots[slot] = -1


func submit() -> bool:
	if slots.has(-1):
		return false
	if slots == story_order():
		solved = true
	return solved


func serialize() -> Dictionary:
	return {"slots": slots.duplicate()}


func deserialize(d: Dictionary) -> void:
	var s: Array = d.get("slots", [])
	if s.size() == COUNT:
		slots = []
		for x in s:
			slots.append(int(x))


func solution() -> Variant:
	return story_order()


func apply_solution() -> bool:
	missing_available = true
	var order := story_order()
	for i in COUNT:
		place(i, order[i])
	return submit()


func random_input(rng: RandomNumberGenerator) -> void:
	if rng.randf() < 0.25:
		clear(rng.randi() % COUNT)
	else:
		var pieces := available_pieces()
		place(rng.randi() % COUNT, pieces[rng.randi() % pieces.size()])
	if not slots.has(-1) and slots != story_order():
		submit()
