@tool
class_name Interactable
extends Area3D
## Data-driven hotspot (GDD §3.2, §9.2). Click → walk to the approach point → interact.

enum Kind { EXAMINE, TAKE, USE, EXIT }
enum Cursor { NONE, EXAMINE, HAND, EXIT, LOCKED }

@export var kind: Kind = Kind.EXAMINE
## Optional localized action label shown in the room (e.g. "Tune radio").
@export var prompt_key: String = ""
## Hotspot exists only while all these are met.
@export var visible_if: Array[Condition] = []
## Run on interact (after the built-in TAKE/EXIT behaviour).
@export var actions: Array[Action] = []
## TAKE: item given, then the hotspot is marked taken and hides for good.
@export var item_id: StringName
## EXIT: id of the ExitDef in the room's RoomData.
@export var exit_id: StringName
## Use-item mode: item id -> actions run when that item is used here.
@export var accepts_items: Dictionary[StringName, Array] = {}
@export var reject_item_key: String = "ui.use.nothing"
## Where the player stands to interact. Defaults to a child named "Approach", then to the
## closest navmesh point.
@export var approach_point: NodePath


func _ready() -> void:
	collision_layer = 1 << 2  # hotspots
	collision_mask = 0
	monitoring = false
	if Engine.is_editor_hint():
		return
	if kind == Kind.TAKE and GameState.is_taken(GameState.current_room, pickup_id()):
		_hide()


func pickup_id() -> String:
	return String(name)


func is_active() -> bool:
	if not visible or not input_ray_pickable:
		return false
	if kind == Kind.TAKE and GameState.is_taken(GameState.current_room, pickup_id()):
		return false
	return Condition.all_met(visible_if)


func cursor() -> Cursor:
	if not is_active():
		return Cursor.NONE
	match kind:
		Kind.EXAMINE:
			return Cursor.EXAMINE
		Kind.EXIT:
			return Cursor.LOCKED if is_locked() else Cursor.EXIT
	return Cursor.HAND


func approach_position() -> Vector3:
	var marker := get_node_or_null(approach_point) if approach_point != NodePath() else null
	if marker == null:
		marker = get_node_or_null("Approach")
	if marker is Node3D:
		return (marker as Node3D).global_position
	var map := get_world_3d().navigation_map
	return NavigationServer3D.map_get_closest_point(map, global_position)


func exit_def() -> ExitDef:
	var room := _room()
	if room == null or room.room_data == null:
		return null
	return room.room_data.get_exit(exit_id)


## True if the exit can't be passed right now (no key held, or lock flag unset).
func is_locked() -> bool:
	var e := exit_def()
	if e == null:
		return false
	var room_id := GameState.current_room
	if GameState.is_exit_opened(room_id, String(exit_id)):
		return false
	if e.lock_flag != &"" and not GameState.get_flag(e.lock_flag, false):
		return true
	return e.required_key != &"" and not GameState.has_item(e.required_key)


func interact() -> void:
	match kind:
		Kind.TAKE:
			if item_id != &"" and not GameState.give_item(item_id):
				EventBus.text_requested.emit("ui.inventory.full")
				return
			GameState.mark_taken(GameState.current_room, pickup_id())
			_hide()
		Kind.EXIT:
			_use_exit()
			return
	Action.run_all(actions)


func use_item(used_item: StringName) -> void:
	if accepts_items.has(used_item):
		var list: Array[Action] = []
		list.assign(accepts_items[used_item])
		Action.run_all(list)
	else:
		EventBus.text_requested.emit(reject_item_key)


func _use_exit() -> void:
	var e := exit_def()
	if e == null:
		push_error("Interactable %s: no exit '%s' in room data" % [name, exit_id])
		return
	var room_id := GameState.current_room
	if is_locked():
		EventBus.text_requested.emit(e.locked_message_key)
		return
	if e.required_key != &"" and not GameState.is_exit_opened(room_id, String(exit_id)):
		# Keys are used automatically on their own door (docs/02-milestone-1.md M1-04).
		GameState.mark_exit_opened(room_id, String(exit_id))
	Action.run_all(actions)
	RoomManager.go_to(e.target_room, e.target_spawn)


func _hide() -> void:
	visible = false
	input_ray_pickable = false
	for c in get_children():
		if c is CollisionShape3D:
			c.set_deferred("disabled", true)


func _room() -> Room:
	var n: Node = self
	while n:
		if n is Room:
			return n
		n = n.get_parent()
	return null
