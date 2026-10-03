class_name PuzzleSolved
extends Condition

@export var puzzle_id: StringName


func is_met() -> bool:
	return GameState.is_puzzle_solved(puzzle_id)
