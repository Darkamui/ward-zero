class_name P01Logic
extends PuzzleLogic
## P01 Dayroom radio (docs/02-milestone-1.md §4): tune to the frequency from the Quiet
## Hours notice. Static fades into the message near the target; a signal needle is the
## visual alternative (rule R6). Solves when the dial is released on the station.

const DIAL_MIN := 530.0
const DIAL_MAX := 1700.0
## Within this many kHz the station is "tuned".
const TOLERANCE := 6.0
## Signal strength reaches zero this far from the station.
const FADE_RANGE := 60.0

var dial: float = 700.0


func _setup() -> void:
	dial = DIAL_MIN + 120.0


func frequency() -> int:
	return int(values.get(&"frequency", 0))


func set_dial(khz: float) -> void:
	dial = clampf(khz, DIAL_MIN, DIAL_MAX)


func signal_strength() -> float:
	return clampf(1.0 - absf(dial - frequency()) / FADE_RANGE, 0.0, 1.0)


func is_tuned() -> bool:
	return absf(dial - frequency()) <= TOLERANCE


## Dial released. Returns true if this tuned in the station.
func release() -> bool:
	if is_tuned():
		solved = true
	return solved


func serialize() -> Dictionary:
	return {"dial": dial}


func deserialize(d: Dictionary) -> void:
	dial = clampf(float(d.get("dial", dial)), DIAL_MIN, DIAL_MAX)


func solution() -> Variant:
	return float(frequency())
