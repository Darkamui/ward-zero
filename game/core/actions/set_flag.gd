class_name SetFlag
extends Action

@export var flag: StringName
@export var value: bool = true


func execute() -> void:
	GameState.set_flag(flag, value)
