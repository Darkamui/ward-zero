class_name P18Logic
extends PuzzleLogic
## P18 Director's grandfather clock: set the hands to the time on the fire clipping (F02,
## seeded since Act 1). Correct time opens the dumbwaiter shortcut to the Morgue.
## values: fire_hour (1-4), fire_minute (0-55, step 5)

var hour := 12
var minute := 0


## "3:40" style time for the clipping (the same digits in both languages).
static func computed_value(v: Dictionary, field: StringName) -> Variant:
	if field == &"fire_time":
		return "%d:%02d" % [int(v.get(&"fire_hour", 3)), int(v.get(&"fire_minute", 0))]
	return null


func turn_hour(step: int) -> void:
	hour = posmod(hour - 1 + step, 12) + 1


func turn_minute(step: int) -> void:
	minute = posmod(minute + step * 5, 60)


func try_time() -> bool:
	if [hour, minute] == solution():
		solved = true
	return solved


func serialize() -> Dictionary:
	return {"hour": hour, "minute": minute}


func deserialize(d: Dictionary) -> void:
	hour = clampi(int(d.get("hour", 12)), 1, 12)
	minute = posmod(int(d.get("minute", 0)), 60) / 5 * 5


func solution() -> Variant:
	return [int(values.get(&"fire_hour", 3)), int(values.get(&"fire_minute", 0))]


func apply_solution() -> bool:
	hour = solution()[0]
	minute = solution()[1]
	return try_time()


func random_input(rng: RandomNumberGenerator) -> void:
	if rng.randf() < 0.5:
		turn_hour(rng.randi_range(-2, 2))
	else:
		turn_minute(rng.randi_range(-3, 3))
	if [hour, minute] != solution():
		try_time()
