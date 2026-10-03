class_name ExitDef
extends Resource
## A door or passage out of a room.

@export var id: StringName
@export var target_room: StringName
## Name of the spawn Marker3D in the target room, usually "spawn_from_<this room id>".
@export var target_spawn: StringName
## Item id needed to pass. Empty means unlocked (flags can still lock it, see lock_flag).
@export var required_key: StringName
## If set, the exit stays locked until this flag is true.
@export var lock_flag: StringName
@export var locked_message_key: String = "ui.door.locked"
