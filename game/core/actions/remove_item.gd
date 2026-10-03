class_name RemoveItem
extends Action

@export var item_id: StringName


func execute() -> void:
	GameState.remove_item(item_id)
