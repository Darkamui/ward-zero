extends Node
## Loads and unloads room scenes, places the player at the door spawn, and switches the
## present/memory timeline (GDD §9.2). Transitions are a black cut, like RE.

signal room_entered(room_id: StringName)
signal room_exited(room_id: StringName)
signal timeline_switched(memory: bool)

const UI_NAME := &"room_transition"
const FADE_OUT := 0.25
const FADE_IN := 0.3
## When door animations are skipped (Options), transitions take under 1 s in total.
const DOOR_PAUSE := 0.35

var world: Node3D
var player: Player
var current: Room
var skip_door_animation := false
var transitioning := false
var _fader: ColorRect


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	_fader = ColorRect.new()
	_fader.color = Color.BLACK
	_fader.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fader.modulate.a = 0.0
	layer.add_child(_fader)
	add_child(layer)


## Called by the game scene once its World and Player exist.
func setup(world_node: Node3D, player_node: Player) -> void:
	# A new game scene means the old world (and its room) is gone.
	if current and is_instance_valid(current):
		CameraDirector.unregister_room()
	current = null
	transitioning = false
	_fader.modulate.a = 0.0
	world = world_node
	player = player_node


func go_to(room_id: StringName, spawn: StringName) -> void:
	if transitioning:
		return
	var data: RoomData = ContentDB.get_room(room_id)
	if data == null or data.scene == null:
		push_error("RoomManager: unknown room '%s'" % room_id)
		return
	transitioning = true
	EventBus.ui_opened.emit(UI_NAME)
	if current:
		await _fade(1.0, FADE_OUT)
		if not skip_door_animation:
			await get_tree().create_timer(DOOR_PAUSE).timeout
	else:
		_fader.modulate.a = 1.0
	load_room_now(data, spawn)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await _fade(0.0, FADE_IN)
	transitioning = false
	EventBus.ui_closed.emit(UI_NAME)
	room_entered.emit(room_id)


## Synchronous swap without fades (used by go_to, save loading and tests).
func load_room_now(data: RoomData, spawn: StringName) -> Room:
	if current:
		var old_id := current.room_id()
		CameraDirector.unregister_room()
		world.remove_child(current)
		current.queue_free()
		current = null
		room_exited.emit(old_id)
	# Leaving a room always returns to the present (GDD §4.1).
	GameState.set_memory(false)
	GameState.set_location(String(data.id), String(spawn))
	current = data.scene.instantiate() as Room
	current.room_data = data
	world.add_child(current)
	var marker: Node3D = current.get_spawn(spawn)
	if marker == null:
		push_error("RoomManager: room %s has no spawn '%s'" % [data.id, spawn])
		marker = current
	if player:
		player.teleport(marker)
	CameraDirector.register_room(current)
	CameraDirector.cut_to(current.camera_for_point(marker.global_position))
	return current


func set_timeline(memory: bool) -> void:
	GameState.set_memory(memory)
	if current:
		current.set_timeline(memory)
	timeline_switched.emit(memory)


func _fade(target: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fader, "modulate:a", target, duration)
	await tween.finished
