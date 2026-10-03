class_name P13Logic
extends PuzzleLogic
## P13 Boiler Room: with the fuse fitted, set three valves (0-6) so every gauge sits in the
## green band. Each valve moves two gauges (Easy: one). A gauge in the red is loud (2-hop
## noise, by design). Gauges are numbered and banded, not colour-only (rule R5).
## values: solution (3 values 1-5).

const GREEN_LOW := 10
const GREEN_HIGH := 14
const RED_ABOVE := 18
const MAX_SETTING := 6
const TARGET := 12

var valves: Array = [0, 0, 0]


func matrix() -> Array:
	if params.get("simple", false):
		return [[2, 0, 0], [0, 2, 0], [0, 0, 2]]
	return [[2, 1, 0], [0, 2, 1], [1, 0, 2]]


func target_settings() -> Array:
	return values.get(&"solution", [3, 3, 3])


## Base pressures chosen so the seeded settings put every gauge exactly on TARGET.
func base() -> Array:
	var m := matrix()
	var s := target_settings()
	var result := []
	for g in 3:
		var sum := 0
		for v in 3:
			sum += m[g][v] * int(s[v])
		result.append(TARGET - sum)
	return result


func gauges() -> Array:
	var m := matrix()
	var b := base()
	var result := []
	for g in 3:
		var sum: int = b[g]
		for v in 3:
			sum += m[g][v] * int(valves[v])
		result.append(sum)
	return result


func in_red() -> bool:
	for g in gauges():
		if g > RED_ABOVE:
			return true
	return false


func all_green() -> bool:
	for g in gauges():
		if g < GREEN_LOW or g > GREEN_HIGH:
			return false
	return true


## Turns a valve. Returns false if that pushed a gauge into the red (a loud attempt).
func set_valve(i: int, setting: int) -> bool:
	if i < 0 or i >= 3:
		return true
	valves[i] = clampi(setting, 0, MAX_SETTING)
	if all_green():
		solved = true
	return not in_red()


func serialize() -> Dictionary:
	return {"valves": valves.duplicate()}


func deserialize(d: Dictionary) -> void:
	var v: Array = d.get("valves", [])
	if v.size() == 3:
		valves = []
		for x in v:
			valves.append(clampi(int(x), 0, MAX_SETTING))


func solution() -> Variant:
	return target_settings()


func apply_solution() -> bool:
	for i in 3:
		set_valve(i, int(target_settings()[i]))
	return solved


func random_input(rng: RandomNumberGenerator) -> void:
	var before := valves.duplicate()
	set_valve(rng.randi() % 3, rng.randi_range(0, MAX_SETTING))
	if solved and before != target_settings():
		# A random turn may land in the green band by chance; that's a real solve.
		pass
