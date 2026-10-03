class_name P15Logic
extends PuzzleLogic
## P15 Pharmacy balance: the substance sits on the left pan; place weights to balance it at
## the prescribed weight. Weight positions: 0 off, 1 right pan, -1 left pan (Hard only).
## values.target (5-31; every weight set below reaches it). params.weights, two_pans,
## show_total (Easy: the scale's dial shows the running total).

var placement: Array = []


func weights() -> Array:
	return params.get("weights", [1, 2, 5, 10, 20])


func two_pans() -> bool:
	return bool(params.get("two_pans", false))


## Every weight reachable with these rules, sorted.
func reachable() -> Array:
	var sums := {}
	var options := [-1, 0, 1] if two_pans() else [0, 1]
	var states: Array = [[]]
	for w in weights():
		var next: Array = []
		for s in states:
			for o in options:
				next.append(s + [o])
		states = next
	for s in states:
		var total := 0
		for i in s.size():
			total += int(weights()[i]) * int(s[i])
		if total > 0:
			sums[total] = true
	var result := sums.keys()
	result.sort()
	return result


func target() -> int:
	return int(values.get(&"target", 13))


func _setup() -> void:
	placement = []
	for w in weights():
		placement.append(0)


func set_weight(i: int, position: int) -> void:
	if i < 0 or i >= placement.size():
		return
	if position == -1 and not two_pans():
		position = 0
	placement[i] = clampi(position, -1, 1)


func total() -> int:
	var t := 0
	for i in placement.size():
		t += int(weights()[i]) * int(placement[i])
	return t


func weigh() -> bool:
	if total() == target():
		solved = true
	return total() == target()


func serialize() -> Dictionary:
	return {"placement": placement.duplicate()}


func deserialize(d: Dictionary) -> void:
	var p: Array = d.get("placement", [])
	if p.size() == weights().size():
		placement = []
		for x in p:
			placement.append(clampi(int(x), -1, 1))


func solution() -> Variant:
	var options := [-1, 0, 1] if two_pans() else [0, 1]
	var states: Array = [[]]
	for w in weights():
		var next: Array = []
		for s in states:
			for o in options:
				next.append(s + [o])
		states = next
	for s in states:
		var t := 0
		for i in s.size():
			t += int(weights()[i]) * int(s[i])
		if t == target():
			return s
	return []


func apply_solution() -> bool:
	var s: Array = solution()
	for i in s.size():
		set_weight(i, s[i])
	return weigh()


func random_input(rng: RandomNumberGenerator) -> void:
	set_weight(rng.randi() % placement.size(), rng.randi_range(-1, 1))
	if total() != target():
		weigh()
