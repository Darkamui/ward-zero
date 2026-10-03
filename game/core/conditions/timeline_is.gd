class_name TimelineIs
extends Condition

@export var memory: bool = false


func is_met() -> bool:
	return GameState.in_memory() == memory
