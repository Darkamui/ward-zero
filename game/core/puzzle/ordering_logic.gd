class_name OrderingLogic
extends PuzzleLogic
## Base for "put N things in the right order" puzzles (P14 books, P16 slides).
## Subclasses define count() and correct_order() (an array of piece ids per slot).

var slots: Array = []


func count() -> int:
	return 0


func correct_order() -> Array:
	return []


func _setup() -> void:
	slots = []
	for i in count():
		slots.append(-1)


func place(slot: int, piece: int) -> void:
	if slot < 0 or slot >= count() or piece < 0 or piece >= count():
		return
	var old := slots.find(piece)
	if old != -1:
		slots[old] = -1
	slots[slot] = piece


func clear(slot: int) -> void:
	if slot >= 0 and slot < count():
		slots[slot] = -1


func submit() -> bool:
	if slots.has(-1):
		return false
	if slots == correct_order():
		solved = true
	return solved


func serialize() -> Dictionary:
	return {"slots": slots.duplicate()}


func deserialize(d: Dictionary) -> void:
	var s: Array = d.get("slots", [])
	if s.size() == count():
		slots = []
		for x in s:
			slots.append(int(x))


func solution() -> Variant:
	return correct_order()


func apply_solution() -> bool:
	var order := correct_order()
	for i in order.size():
		place(i, order[i])
	return submit()


func random_input(rng: RandomNumberGenerator) -> void:
	if rng.randf() < 0.25:
		clear(rng.randi() % count())
	else:
		place(rng.randi() % count(), rng.randi() % count())
	if not slots.has(-1) and slots != correct_order():
		submit()
