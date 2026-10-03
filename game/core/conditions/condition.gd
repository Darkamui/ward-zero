class_name Condition
extends Resource
## Base class for data-driven conditions used by Interactables, exits and puzzles.


func is_met() -> bool:
	push_error("Condition.is_met() not overridden in %s" % get_script().resource_path)
	return false


## True when every condition in the list is met (an empty list is met).
static func all_met(conditions: Array[Condition]) -> bool:
	for c in conditions:
		if c != null and not c.is_met():
			return false
	return true
