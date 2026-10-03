class_name P11Logic
extends PuzzleLogic
## P11 Playroom music box: with the crank and cylinder fitted, set one pin per step to the
## lullaby hummed on the tape. The lid sheet and subtitles name the notes (visual
## alternative to the audio, rule R6). params.length (4/6/8). values: melody (8 notes 0-4).

const NOTES := ["c", "d", "e", "g", "a"]

var pins: Array = []


func length() -> int:
	return int(params.get("length", 6))


func melody() -> Array:
	return (values.get(&"melody", [0, 1, 2, 3, 4, 0, 1, 2]) as Array).slice(0, length())


func _setup() -> void:
	pins = []
	for i in length():
		pins.append(-1)


func set_pin(step: int, note: int) -> void:
	if step >= 0 and step < pins.size() and note >= -1 and note < NOTES.size():
		pins[step] = note


func play() -> bool:
	if pins == melody():
		solved = true
	return solved


func serialize() -> Dictionary:
	return {"pins": pins.duplicate()}


func deserialize(d: Dictionary) -> void:
	var p: Array = d.get("pins", [])
	if p.size() == length():
		pins = []
		for x in p:
			pins.append(int(x))


func solution() -> Variant:
	return melody()


func apply_solution() -> bool:
	var m := melody()
	for i in m.size():
		set_pin(i, m[i])
	return play()


func random_input(rng: RandomNumberGenerator) -> void:
	set_pin(rng.randi() % length(), rng.randi_range(-1, NOTES.size() - 1))
	if not pins.has(-1) and pins != melody():
		play()


## note_key_<i>: translated note name keys for the lid sheet and the tape.
static func computed_value(v: Dictionary, field: StringName) -> Variant:
	var f := String(field)
	if f.begins_with("note_key_"):
		var m: Array = v.get(&"melody", [])
		var i := int(f.trim_prefix("note_key_"))
		return "note.%s" % NOTES[int(m[i])] if i < m.size() else ""
	return null
