class_name P04Logic
extends PuzzleLogic
## P04 Administrator's wall safe: code = each digit of the founding year (lobby plaque)
## shifted by the memo's number, mod 10. Hard also reverses the digits.
## values: founding_year (1890-1925), shift (1-9). params.reverse: bool

var wheels: Array = [0, 0, 0, 0]


func code() -> Array:
	var year := str(int(values.get(&"founding_year", 1900)))
	var shift := int(values.get(&"shift", 1))
	var digits := []
	for ch in year:
		digits.append((int(ch) + shift) % 10)
	if params.get("reverse", false):
		digits.reverse()
	return digits


func set_wheel(i: int, digit: int) -> void:
	if i >= 0 and i < wheels.size():
		wheels[i] = posmod(digit, 10)


func turn_wheel(i: int, step: int) -> void:
	if i >= 0 and i < wheels.size():
		set_wheel(i, wheels[i] + step)


## Pull the handle. True if the wheels show the code.
func pull() -> bool:
	if wheels == code():
		solved = true
	return wheels == code()


func serialize() -> Dictionary:
	return {"wheels": wheels.duplicate()}


func deserialize(d: Dictionary) -> void:
	var w: Array = d.get("wheels", [])
	if w.size() == 4:
		wheels = []
		for x in w:
			wheels.append(posmod(int(x), 10))


func solution() -> Variant:
	return code()


func apply_solution() -> bool:
	for i in 4:
		set_wheel(i, code()[i])
	return pull()


func random_input(rng: RandomNumberGenerator) -> void:
	turn_wheel(rng.randi() % 4, rng.randi_range(-3, 3))
	if wheels != code():
		pull()
