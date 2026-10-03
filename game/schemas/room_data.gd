class_name RoomData
extends Resource
## Static description of a room (GDD §9.2). Runtime state lives in GameState.

enum Access { OPEN, SCRIPTED, NEVER }
enum Floor { GROUND, EAST, WEST, UPPER, BASEMENT }

const SCHEMA_VERSION := 1

@export var schema_version: int = SCHEMA_VERSION
@export var id: StringName
@export var name_key: String
@export var scene: PackedScene
@export var cameras: Array[CameraDef] = []
@export var exits: Array[ExitDef] = []
@export var access: Access = Access.SCRIPTED
@export var map_floor: Floor = Floor.GROUND
@export var safe_room: bool = false
@export var has_memory_variant: bool = false
## Paths (inside the room scene) to hiding spot nodes.
@export var hiding_spots: Array[NodePath] = []
## Rectangle on the floor map, in map texture pixels.
@export var map_rect: Rect2
@export var ambience_present: AudioStream
@export var ambience_memory: AudioStream


func get_exit(exit_id: StringName) -> ExitDef:
	for e in exits:
		if e.id == exit_id:
			return e
	return null


func get_camera(camera_id: StringName) -> CameraDef:
	for c in cameras:
		if c.id == camera_id:
			return c
	return null
