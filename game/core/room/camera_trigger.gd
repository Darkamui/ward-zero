@tool
class_name CameraTrigger
extends Area3D
## Floor zone for camera_id (GDD §3.3). CameraDirector tests the player's position
## against these boxes every physics frame. Zones should overlap slightly: the current
## camera holds inside the overlap, so cuts can't ping-pong at a boundary.
## Only BoxShape3D children are supported.

@export var camera_id: StringName


func _ready() -> void:
	collision_layer = 1 << 3  # camera_triggers
	collision_mask = 0
	monitoring = false
	monitorable = false
