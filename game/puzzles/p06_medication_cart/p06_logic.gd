class_name P06Logic
extends PuzzleLogic
## P06 Nurse Station medication cart: put each patient's pill in their drawer. Charts give
## the pill's shape, the shift log its colour; both as words (rule R5). Every patient has a
## distinct colour and a distinct shape, so the two clues together are unambiguous.
## values: colors (5 unique 0-4), shapes (5 unique 0-4). params.patients (3/4/5).

const COLORS := ["white", "yellow", "pink", "blue", "green"]
const SHAPES := ["round", "oval", "square", "triangle", "capsule"]
const PATIENTS := ["H. Tremblay", "R. Gagnon", "S. Côté", "L. Pelletier", "M. Fortin"]
const DECOYS := 3

var drawers: Array = []  # per patient: tray index or -1


func patient_count() -> int:
	return int(params.get("patients", 4))


func _setup() -> void:
	drawers = []
	for i in patient_count():
		drawers.append(-1)


## Pill of patient i as [color, shape] indices.
func pill_of(i: int) -> Array:
	return [int(values[&"colors"][i]), int(values[&"shapes"][i])]


## The tray: every patient's pill plus decoys mixing a colour and a shape, in a fixed order.
func tray() -> Array:
	var pills := []
	for i in patient_count():
		pills.append(pill_of(i))
	for i in mini(DECOYS, patient_count()):
		pills.append([int(values[&"colors"][i]), int(values[&"shapes"][(i + 1) % patient_count()])])
	pills.sort_custom(func(a: Array, b: Array) -> bool: return a[1] * 10 + a[0] < b[1] * 10 + b[0])
	return pills


func assign(patient: int, tray_index: int) -> void:
	if patient >= 0 and patient < drawers.size() and tray_index >= -1 and tray_index < tray().size():
		drawers[patient] = tray_index


func submit() -> bool:
	var t := tray()
	for i in drawers.size():
		if drawers[i] < 0 or t[drawers[i]] != pill_of(i):
			return false
	solved = true
	return true


func serialize() -> Dictionary:
	return {"drawers": drawers.duplicate()}


func deserialize(d: Dictionary) -> void:
	var a: Array = d.get("drawers", [])
	if a.size() == patient_count():
		drawers = []
		for x in a:
			drawers.append(int(x))


func solution() -> Variant:
	var t := tray()
	var result := []
	for i in patient_count():
		result.append(t.find(pill_of(i)))
	return result


func apply_solution() -> bool:
	var s: Array = solution()
	for i in s.size():
		assign(i, s[i])
	return submit()


func random_input(rng: RandomNumberGenerator) -> void:
	assign(rng.randi() % patient_count(), rng.randi_range(-1, tray().size() - 1))
	if not drawers.has(-1) and not submit():
		pass


## Documents: color_key_<i>, shape_key_<i>, patient_<i>.
static func computed_value(v: Dictionary, field: StringName) -> Variant:
	var f := String(field)
	if f.begins_with("color_key_"):
		return "pill.color.%s" % COLORS[int(v[&"colors"][int(f.trim_prefix("color_key_"))])]
	if f.begins_with("shape_key_"):
		return "pill.shape.%s" % SHAPES[int(v[&"shapes"][int(f.trim_prefix("shape_key_"))])]
	if f.begins_with("patient_"):
		return PATIENTS[int(f.trim_prefix("patient_"))]
	return null
