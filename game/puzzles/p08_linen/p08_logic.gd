class_name P08Logic
extends PuzzleLogic
## P08 Linen Room (stealth): find the stained sheet while he patrols. A note gives the bed
## and day; the laundry ledger maps bed + day to a tag (Easy: the note gives the tag).
## Each wrong pull makes noise. The right sheet's label carries the E05 lockbox code.
## values: tags (12 unique 0-35), target (0-11), bed (1-12), day (0-6), lockbox_code.

const SHEETS := 12
const DAYS := ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]

var pulled: Array = []


func tag(i: int) -> String:
	var n := int(values[&"tags"][i])
	return "%s%d" % [char(65 + n / 4), n % 4 + 1]


func target() -> int:
	return int(values.get(&"target", 0))


func pull(i: int) -> bool:
	if i < 0 or i >= SHEETS:
		return false
	if not pulled.has(i):
		pulled.append(i)
	if i == target():
		solved = true
	return i == target()


func serialize() -> Dictionary:
	return {"pulled": pulled.duplicate()}


func deserialize(d: Dictionary) -> void:
	pulled = []
	for i in d.get("pulled", []):
		pulled.append(int(i))


func solution() -> Variant:
	return target()


func apply_solution() -> bool:
	return pull(target())


func random_input(rng: RandomNumberGenerator) -> void:
	var i := rng.randi() % SHEETS
	if i != target():
		pull(i)


## Ledger rows row_<k> (6 rows; the target's row is among bed/day near-misses), the note's
## bed/day/tag, and the lockbox code digits. Day names are translated.
static func computed_value(v: Dictionary, field: StringName) -> Variant:
	var f := String(field)
	var bed := int(v.get(&"bed", 1))
	var day := int(v.get(&"day", 0))
	var t := int(v.get(&"target", 0))
	var tags: Array = v.get(&"tags", [])
	if f == "day_name":
		return TranslationServer.translate("ui.day.%s" % DAYS[day])
	if f == "target_tag":
		return _tag_name(int(tags[t]))
	if f.begins_with("row_"):
		var k := int(f.trim_prefix("row_"))
		# Row 3 is the real one; the others share either the bed or the day.
		var r_bed := bed if k % 2 == 0 or k == 3 else (bed % 12) + 1
		var r_day := day if k % 2 == 1 or k == 3 else (day + k) % 7
		if k != 3 and r_bed == bed and r_day == day:
			r_day = (day + 1) % 7
		var r_tag := int(tags[t]) if k == 3 else int(tags[(t + k + 1) % SHEETS])
		return (
			"%s %d — %s — %s"
			% [
				TranslationServer.translate("ui.bed"),
				r_bed,
				TranslationServer.translate("ui.day.%s" % DAYS[r_day]),
				_tag_name(r_tag)
			]
		)
	if f.begins_with("code_"):
		return CodeLockLogic.digit_of(v, "lockbox_code", 3, int(f.trim_prefix("code_")))
	return null


static func _tag_name(n: int) -> String:
	return "%s%d" % [char(65 + n / 4), n % 4 + 1]
