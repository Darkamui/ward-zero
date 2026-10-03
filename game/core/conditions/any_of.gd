class_name AnyOf
extends Condition

@export var conditions: Array[Condition] = []


func is_met() -> bool:
	for c in conditions:
		if c != null and c.is_met():
			return true
	return false
