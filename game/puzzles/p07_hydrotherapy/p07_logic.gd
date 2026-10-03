class_name P07Logic
extends PuzzleLogic
## P07 Hydrotherapy tubs (water jugs): pour tub to tub, drain a tub, use the tap (Easy),
## or open the main valve to reset (so nothing is ever lost for good, rule R7). Solved
## when every tub shows its marked level. Needs the valve wheel (checked by the hotspot).
## params.configs: candidate configs; values.config: which one (seeded).

const DEFAULT_CONFIGS := [
	{"caps": [8, 5, 3], "start": [8, 0, 0], "goal": [4, 4, 0]},
	{"caps": [10, 7, 3], "start": [10, 0, 0], "goal": [5, 5, 0]},
]

var levels: Array = []


func config() -> Dictionary:
	var configs: Array = params.get("configs", DEFAULT_CONFIGS)
	return configs[int(values.get(&"config", 0)) % configs.size()]


func caps() -> Array:
	return config()["caps"]


func goal() -> Array:
	return config()["goal"]


func has_tap() -> bool:
	return bool(config().get("tap", false))


func _setup() -> void:
	reset()


func reset() -> void:
	levels = (config()["start"] as Array).duplicate()


func pour(from: int, to: int) -> void:
	if from == to or from < 0 or to < 0 or from >= levels.size() or to >= levels.size():
		return
	var amount := mini(levels[from], caps()[to] - levels[to])
	levels[from] -= amount
	levels[to] += amount


func drain(i: int) -> void:
	if i >= 0 and i < levels.size():
		levels[i] = 0


func fill(i: int) -> void:
	if has_tap() and i >= 0 and i < levels.size():
		levels[i] = caps()[i]


func check() -> bool:
	if levels == goal():
		solved = true
	return solved


func serialize() -> Dictionary:
	return {"levels": levels.duplicate()}


func deserialize(d: Dictionary) -> void:
	var l: Array = d.get("levels", [])
	if l.size() == caps().size():
		levels = []
		for x in l:
			levels.append(int(x))


## Shortest list of operations from the current state: ["pour", a, b] / ["drain", a] /
## ["fill", a] / ["reset"]. Empty if already solved or (should never happen) unsolvable.
func solution() -> Variant:
	var start := levels.duplicate()
	var queue := [[start, []]]
	var seen := {str(start): true}
	while not queue.is_empty():
		var item: Array = queue.pop_front()
		var state: Array = item[0]
		if state == goal():
			return item[1]
		for op in _ops():
			var next := _apply(state, op)
			var key := str(next)
			if not seen.has(key):
				seen[key] = true
				queue.append([next, item[1] + [op]])
	return []


func apply_solution() -> bool:
	for op in solution():
		levels = _apply(levels, op)
	return check()


func random_input(rng: RandomNumberGenerator) -> void:
	var ops := _ops()
	levels = _apply(levels, ops[rng.randi() % ops.size()])
	check()


func _ops() -> Array:
	var ops := [["reset"]]
	for a in caps().size():
		ops.append(["drain", a])
		if has_tap():
			ops.append(["fill", a])
		for b in caps().size():
			if a != b:
				ops.append(["pour", a, b])
	return ops


func _apply(state: Array, op: Array) -> Array:
	var saved := levels
	levels = state.duplicate()
	match op[0]:
		"reset":
			reset()
		"drain":
			drain(op[1])
		"fill":
			fill(op[1])
		"pour":
			pour(op[1], op[2])
	var result := levels
	levels = saved
	return result
