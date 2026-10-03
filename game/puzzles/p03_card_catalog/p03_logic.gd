class_name P03Logic
extends PuzzleLogic
## P03 Records card catalog: files are indexed by birth month. Two drawer labels are
## swapped (not on Easy): the drawer labelled with Mathieu's month holds another month's
## cards, which leads to the drawer that holds his. His card names the cabinet; opening
## the wrong cabinet rattles (noise), never locks anything (rule R7).
##
## values: birth_day (1-28), birth_month (1-12), cabinet (1-12), swap_offset (1-11)
## params.swapped: bool (default true)

var opened_drawers: Array = []  # label months opened
var card_found := false


func birth_month() -> int:
	return int(values.get(&"birth_month", 1))


func swapped_month() -> int:
	return ((birth_month() - 1 + int(values.get(&"swap_offset", 1))) % 12) + 1


func cabinet() -> int:
	return int(values.get(&"cabinet", 1))


func labels_swapped() -> bool:
	return bool(params.get("swapped", true))


## Month whose cards are really inside the drawer labelled label_month.
func drawer_contents(label_month: int) -> int:
	if labels_swapped():
		if label_month == birth_month():
			return swapped_month()
		if label_month == swapped_month():
			return birth_month()
	return label_month


## Opens a drawer. Returns the month of the cards inside. Finds the card if it is there.
func open_drawer(label_month: int) -> int:
	if not opened_drawers.has(label_month):
		opened_drawers.append(label_month)
	var month := drawer_contents(label_month)
	if month == birth_month():
		card_found = true
	return month


## Tries a cabinet. True if it is the right one (solves the puzzle).
func open_cabinet(n: int) -> bool:
	if n == cabinet():
		solved = true
	return n == cabinet()


func serialize() -> Dictionary:
	return {"opened": opened_drawers.duplicate(), "card_found": card_found}


func deserialize(d: Dictionary) -> void:
	opened_drawers = []
	for m in d.get("opened", []):
		opened_drawers.append(int(m))
	card_found = bool(d.get("card_found", false))


func solution() -> Variant:
	for label in range(1, 13):
		if drawer_contents(label) == birth_month():
			return {"drawer": label, "cabinet": cabinet()}
	return null


func apply_solution() -> bool:
	var s: Dictionary = solution()
	open_drawer(s["drawer"])
	return open_cabinet(s["cabinet"])


func random_input(rng: RandomNumberGenerator) -> void:
	open_drawer(rng.randi_range(1, 12))
	var c := rng.randi_range(1, 12)
	if c != cabinet():
		open_cabinet(c)


## Birthdate shown on the wristband and in F01, e.g. "14/03/1967".
static func computed_value(v: Dictionary, field: StringName) -> Variant:
	if field == &"birthdate":
		return "%02d/%02d/1967" % [int(v.get(&"birth_day", 1)), int(v.get(&"birth_month", 1))]
	if field == &"birth_month_key":
		return "ui.month.%d" % int(v.get(&"birth_month", 1))
	return null
