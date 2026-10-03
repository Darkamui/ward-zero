class_name BreathCheck
extends RefCounted
## Breath-hold when the stalker checks the player's hiding spot (GDD §5.3).
## While he walks to the spot the player may already hold (APPROACH). At the spot the
## CHECK lasts `required` seconds and the player must hold throughout (a short grace to
## start). Breath is limited: holding longer than `capacity` in total means a gasp.
## So the tolerance window is capacity - required (set by threat difficulty).

enum Phase { APPROACH, CHECK, PASSED, FAILED }

const START_GRACE := 0.6

var required := 2.5
var capacity := 4.5
var phase := Phase.APPROACH
var held := 0.0
var check_time := 0.0
var fail_reason := ""


func _init(required_s := 2.5, capacity_s := 4.5) -> void:
	required = required_s
	capacity = capacity_s


## He has reached the spot: the check starts now.
func begin_check() -> void:
	if phase == Phase.APPROACH:
		phase = Phase.CHECK
		check_time = 0.0


func update(delta: float, holding: bool) -> Phase:
	if phase == Phase.PASSED or phase == Phase.FAILED:
		return phase
	if holding:
		held += delta
		if held > capacity:
			return _fail("gasp")
	if phase == Phase.CHECK:
		check_time += delta
		if not holding and check_time > START_GRACE:
			return _fail("breathed")
		if check_time >= required:
			phase = Phase.PASSED
	return phase


## 0..1 breath left, for the meter.
func breath_left() -> float:
	return clampf(1.0 - held / capacity, 0.0, 1.0)


func _fail(reason: String) -> Phase:
	fail_reason = reason
	phase = Phase.FAILED
	return phase
