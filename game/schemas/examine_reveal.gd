class_name ExamineReveal
extends Resource
## Detail revealed by turning an item in the 3D examine view (GDD §3.4).

## Direction (in model space) the camera has to look from, normalized.
@export var view_direction: Vector3 = Vector3.BACK
## Maximum angle between the view and view_direction, in degrees.
@export var tolerance_degrees: float = 25.0
@export var sets_flag: StringName
@export var adds_document: StringName
@export var message_key: String
