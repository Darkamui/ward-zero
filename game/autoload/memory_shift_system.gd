extends Node
## Memory shifts (GDD §4): using a Memory Anchor at a resonant spot turns the room into
## its 1976 version. Leaving by anchor or by any door returns to the present (doors are
## handled by RoomManager). The stalker can't follow into a memory.
## Persistent objects (GDD §4.1) carry forward: mark them in 1976 and they exist in the
## present through the "persist.<id>" flag that room content checks.

signal shift_started(room_id: StringName, to_memory: bool)
signal shift_completed(room_id: StringName, to_memory: bool)

var busy := false


func can_shift() -> bool:
	var room := RoomManager.current
	return not busy and room != null and room.room_data != null and room.room_data.has_memory_variant


func toggle() -> void:
	if not can_shift():
		return
	busy = true
	var to_memory := not GameState.in_memory()
	var room_id := RoomManager.current.room_id()
	shift_started.emit(room_id, to_memory)
	EventBus.ui_opened.emit(&"memory_shift")
	# The flash runs on its own; swap the room while the screen is white.
	RoomManager.flash(Color(1.0, 0.95, 0.85) if to_memory else Color(0.9, 0.92, 1.0), 0.4)
	await get_tree().create_timer(0.2).timeout
	RoomManager.set_timeline(to_memory)
	await get_tree().create_timer(1.0).timeout
	if to_memory:
		GameState.set_flag("%s.memory_visited" % String(room_id).to_lower(), true)
	else:
		# Completing a shift restores composure (GDD §5.4; ComposureSystem, M2).
		GameState.set_composure(GameState.composure + 0.15)
	EventBus.ui_closed.emit(&"memory_shift")
	busy = false
	shift_completed.emit(room_id, to_memory)


## Marks a 1976 object as carried into the present (GDD §4.1).
func mark_persistent(object_id: String) -> void:
	GameState.set_flag("persist.%s" % object_id, true)


func is_persistent(object_id: String) -> bool:
	return GameState.get_flag("persist.%s" % object_id, false)
