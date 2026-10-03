class_name HasItem
extends Condition

@export var item_id: StringName


func is_met() -> bool:
	return GameState.has_item(item_id)
