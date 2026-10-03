class_name ChangeComposure
extends Action
## Adds delta to composure (clamped 0-1). Sedatives use +0.4 (GDD §5.4).

@export var delta: float = 0.0


func execute() -> void:
	GameState.set_composure(GameState.composure + delta)
