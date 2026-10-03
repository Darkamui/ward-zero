class_name PlayTape
extends Action

@export var tape_id: StringName


func execute() -> void:
	EventBus.tape_requested.emit(tape_id)
