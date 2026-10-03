class_name NotCondition
extends Condition

@export var condition: Condition


func is_met() -> bool:
	return condition != null and not condition.is_met()
