class_name StartScript
extends Action

@export var script_name: StringName


func execute() -> void:
	EventBus.script_requested.emit(script_name)
