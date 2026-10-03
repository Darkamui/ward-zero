class_name CameraDef
extends Resource
## One fixed camera angle in a room. The Camera3D node in the room scene has the same id.

@export var id: StringName
@export var background: Texture2D
## Background for the 1976 variant. Only used when the room has a memory variant.
@export var memory_background: Texture2D
