class_name OpenUi
extends Action
## Opens a UI by name: &"save_screen" (tape recorder), &"effects_bin".

@export var ui_name: StringName


func execute() -> void:
	EventBus.ui_requested.emit(ui_name)
