class_name P20Logic
extends PuzzleLogic
## P20 Treatment Room humors panel: place the four temperament keys in the slots of their
## seasons, as the mural shows (Choleric/fire/summer, Melancholic/earth/autumn,
## Phlegmatic/water/winter, Sanguine/air/spring). Slot seasons are in a seeded order.
## values: season_order (4 unique 0-3).

const KEYS := ["choleric", "melancholic", "phlegmatic", "sanguine"]
const SEASON_OF_KEY := [1, 2, 3, 0]  # summer, autumn, winter, spring
const SEASONS := ["spring", "summer", "autumn", "winter"]
const ELEMENTS := ["air", "fire", "earth", "water"]  # by season index

var slots: Array = [-1, -1, -1, -1]


func slot_season(slot: int) -> int:
	return int(values.get(&"season_order", [0, 1, 2, 3])[slot])


func place(slot: int, key: int) -> void:
	if slot < 0 or slot > 3 or key < -1 or key > 3:
		return
	var old := slots.find(key)
	if key >= 0 and old != -1:
		slots[old] = -1
	slots[slot] = key


func submit() -> bool:
	for s in 4:
		if slots[s] < 0 or SEASON_OF_KEY[slots[s]] != slot_season(s):
			return false
	solved = true
	return true


func serialize() -> Dictionary:
	return {"slots": slots.duplicate()}


func deserialize(d: Dictionary) -> void:
	var s: Array = d.get("slots", [])
	if s.size() == 4:
		slots = []
		for x in s:
			slots.append(int(x))


func solution() -> Variant:
	var result := []
	for s in 4:
		result.append(SEASON_OF_KEY.find(slot_season(s)))
	return result


func apply_solution() -> bool:
	var sol: Array = solution()
	for s in 4:
		place(s, sol[s])
	return submit()


func random_input(rng: RandomNumberGenerator) -> void:
	place(rng.randi() % 4, rng.randi_range(-1, 3))
	if not slots.has(-1):
		submit()
