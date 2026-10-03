class_name EnterTrigger
extends Resource
## Actions run when the player enters a room, if the conditions hold. With once_flag set,
## it runs only until that flag is true (the flag is set when it runs).

@export var conditions: Array[Condition] = []
@export var actions: Array[Action] = []
@export var once_flag: StringName


func should_run() -> bool:
	if once_flag != &"" and GameState.get_flag(once_flag, false):
		return false
	return Condition.all_met(conditions)


func run() -> void:
	if once_flag != &"":
		GameState.set_flag(once_flag, true)
	Action.run_all(actions)
