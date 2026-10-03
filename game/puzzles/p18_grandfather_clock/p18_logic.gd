class_name P18Logic
extends PuzzleLogic
## P18 Director's grandfather clock (Act 3, M4). Stub: only the seeded fire time exists so
## far, because the F02 clipping in Act 1 already shows it (docs/02-milestone-1.md §2.3).
## values: fire_hour (1-4), fire_minute (0-55, step 5)


## "3:40" style time for the clipping (the same digits in both languages).
static func computed_value(v: Dictionary, field: StringName) -> Variant:
	if field == &"fire_time":
		return "%d:%02d" % [int(v.get(&"fire_hour", 3)), int(v.get(&"fire_minute", 0))]
	return null


func solution() -> Variant:
	return [int(values.get(&"fire_hour", 3)), int(values.get(&"fire_minute", 0))]
