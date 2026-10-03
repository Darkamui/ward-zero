class_name CodeLockLogic
extends PuzzleLogic
## A combination lock with N number wheels. The code comes from an int value (e.g. 4827)
## named by params.code_field (default "code_number"), padded to params.digits.

var wheels: Array = []


func digits() -> int:
	return int(params.get("digits", 4))


func code() -> Array:
	var n := int(values.get(StringName(params.get("code_field", "code_number")), 0))
	var s := str(n).pad_zeros(digits())
	var result := []
	for ch in s.substr(s.length() - digits()):
		result.append(int(ch))
	return result


func _setup() -> void:
	wheels = []
	for i in digits():
		wheels.append(0)


func turn_wheel(i: int, step: int) -> void:
	if i >= 0 and i < wheels.size():
		wheels[i] = posmod(wheels[i] + step, 10)


func set_wheel(i: int, digit: int) -> void:
	if i >= 0 and i < wheels.size():
		wheels[i] = posmod(digit, 10)


func try_open() -> bool:
	if wheels == code():
		solved = true
	return wheels == code()


func serialize() -> Dictionary:
	return {"wheels": wheels.duplicate()}


func deserialize(d: Dictionary) -> void:
	var w: Array = d.get("wheels", [])
	if w.size() == digits():
		wheels = []
		for x in w:
			wheels.append(posmod(int(x), 10))


func solution() -> Variant:
	return code()


func apply_solution() -> bool:
	for i in digits():
		set_wheel(i, code()[i])
	return try_open()


func random_input(rng: RandomNumberGenerator) -> void:
	turn_wheel(rng.randi() % digits(), rng.randi_range(-4, 4))
	if wheels != code():
		try_open()


## Document placeholders "digit_<i>" for any code-lock puzzle.
static func digit_of(v: Dictionary, field_name: String, digit_count: int, i: int) -> int:
	var s := str(int(v.get(StringName(field_name), 0))).pad_zeros(digit_count)
	return int(s[s.length() - digit_count + i])


## P10 board placeholders "digit_<i>" (4-digit code_number).
static func computed_value(v: Dictionary, field: StringName) -> Variant:
	var f := String(field)
	if f.begins_with("digit_"):
		return digit_of(v, "code_number", 4, int(f.trim_prefix("digit_")))
	return null
