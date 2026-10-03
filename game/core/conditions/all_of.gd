class_name AllOf
extends Condition

@export var conditions: Array[Condition] = []


func is_met() -> bool:
	return Condition.all_met(conditions)
