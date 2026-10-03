class_name ShowText
extends Action

@export var key: String


func execute() -> void:
	EventBus.text_requested.emit(key)
