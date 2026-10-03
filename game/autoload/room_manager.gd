extends Node
## Loads and unloads room scenes, places the player at the door spawn, switches between
## the present and memory timelines (GDD §9.2). Filled in during M0/M1.

signal room_entered(room_id: StringName)
signal room_exited(room_id: StringName)
signal timeline_switched(memory: bool)


func go_to(room_id: StringName, spawn: StringName) -> void:
	push_error("RoomManager.go_to(%s, %s) not implemented" % [room_id, spawn])


func set_timeline(memory: bool) -> void:
	push_error("RoomManager.set_timeline(%s) not implemented" % memory)
