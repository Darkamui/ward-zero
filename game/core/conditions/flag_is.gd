class_name FlagIs
extends Condition
## Compares a flag to a value. Missing flags read as false.

@export var flag: StringName
@export var value: bool = true


func is_met() -> bool:
	return GameState.values_equal(GameState.get_flag(flag, false), value)
