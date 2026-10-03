class_name Action
extends Resource
## Base class for data-driven actions. Actions change state through GameState or ask
## other systems to act through EventBus, so they stay testable without a scene.


func execute() -> void:
	push_error("Action.execute() not overridden in %s" % get_script().resource_path)


static func run_all(actions: Array[Action]) -> void:
	for a in actions:
		if a != null:
			a.execute()
