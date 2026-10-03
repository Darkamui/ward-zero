class_name StalkerLevel
extends RefCounted
## Registers the stalker test level rooms (T01-T05) with ContentDB for tests and debug.

const DIR := "res://tests/levels/stalker"
const ROOMS := ["t01", "t02", "t03", "t04", "t05"]


static func register() -> void:
	for r in ROOMS:
		var data: RoomData = load("%s/%s/room_data.tres" % [DIR, r])
		ContentDB.register_room(data)
