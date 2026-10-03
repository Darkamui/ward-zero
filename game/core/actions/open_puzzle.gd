class_name OpenPuzzle
extends Action

@export var puzzle_id: StringName


func execute() -> void:
	EventBus.puzzle_requested.emit(puzzle_id)
