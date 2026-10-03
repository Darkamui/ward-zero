class_name EmitNoise
extends Action

@export var hops: int = 1


func execute() -> void:
	EventBus.noise_emitted.emit(GameState.current_room, hops)
