class_name GrowInventory
extends Action
## The Orderly's Satchel: main slots grow to `slots` (GDD §3.4).

@export var slots: int = GameState.SATCHEL_SLOTS


func execute() -> void:
	GameState.set_slot_count(slots)
