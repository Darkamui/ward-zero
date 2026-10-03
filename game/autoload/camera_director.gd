extends Node
## Owns the active fixed camera and its background (GDD §9.2). Filled in during M0.

signal camera_cut(camera_id: StringName)


func cut_to(camera_id: StringName) -> void:
	push_error("CameraDirector.cut_to(%s) not implemented" % camera_id)
