class_name DifficultyIs
extends Condition
## Matches the current threat and/or puzzle difficulty (empty = any).

@export var threat: String = ""
@export var puzzle: String = ""


func is_met() -> bool:
	if threat != "" and GameState.threat_difficulty != threat:
		return false
	return puzzle == "" or GameState.puzzle_difficulty == puzzle
