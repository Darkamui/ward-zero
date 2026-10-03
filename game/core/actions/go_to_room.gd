class_name GoToRoom
extends Action

@export var room_id: StringName
@export var spawn: StringName


func execute() -> void:
	RoomManager.go_to(room_id, spawn)
