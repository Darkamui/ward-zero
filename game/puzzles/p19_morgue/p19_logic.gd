class_name P19Logic
extends PuzzleLogic
## P19 Morgue: the death registry lists five entries with drawer numbers; open the drawer
## of "the girl from the fire". (In 1976 that drawer is empty: Claire was never brought
## here.) Wrong drawers rattle (noise). values: drawers (5 unique 1-12). Entry 2 is hers.

const DRAWERS := 12
const TARGET_ENTRY := 2

var opened: Array = []


func target() -> int:
	return int(values[&"drawers"][TARGET_ENTRY])


func open_drawer(n: int) -> bool:
	if n < 1 or n > DRAWERS:
		return false
	if not opened.has(n):
		opened.append(n)
	if n == target():
		solved = true
	return n == target()


func serialize() -> Dictionary:
	return {"opened": opened.duplicate()}


func deserialize(d: Dictionary) -> void:
	opened = []
	for n in d.get("opened", []):
		opened.append(int(n))


func solution() -> Variant:
	return target()


func apply_solution() -> bool:
	return open_drawer(target())


func random_input(rng: RandomNumberGenerator) -> void:
	var n := rng.randi_range(1, DRAWERS)
	if n != target():
		open_drawer(n)


## drawer_<k> for the registry.
static func computed_value(v: Dictionary, field: StringName) -> Variant:
	var f := String(field)
	if f.begins_with("drawer_"):
		return int(v[&"drawers"][int(f.trim_prefix("drawer_"))])
	return null
