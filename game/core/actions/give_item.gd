class_name GiveItem
extends Action

@export var item_id: StringName


func execute() -> void:
	GameState.give_item(item_id)
