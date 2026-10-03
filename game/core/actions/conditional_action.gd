class_name ConditionalAction
extends Action
## Runs `then_actions` when every condition is met, otherwise `else_actions`.

@export var conditions: Array[Condition] = []
@export var then_actions: Array[Action] = []
@export var else_actions: Array[Action] = []


func execute() -> void:
	Action.run_all(then_actions if Condition.all_met(conditions) else else_actions)
