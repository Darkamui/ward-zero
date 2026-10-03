class_name MemoryShift
extends Action
## Switches the current room between the present and its 1976 version (GDD §4).


func execute() -> void:
	MemoryShiftSystem.toggle()
