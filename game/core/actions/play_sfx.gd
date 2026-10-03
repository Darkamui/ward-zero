class_name PlaySfx
extends Action

@export var stream: AudioStream


func execute() -> void:
	EventBus.sfx_requested.emit(stream)
