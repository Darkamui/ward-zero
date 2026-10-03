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
	GameState.flag_changed.connect(_on_music_flag_changed)
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
	AudioDirector.clear_room_audio()
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
		AudioDirector.play_sfx(AudioDirector.DOOR, -8.0)
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
	run_enter_triggers(data)


func run_enter_triggers(data: RoomData) -> void:
	GameState.set_flag("%s.visited" % String(data.id).to_lower(), true)
	for t in data.enter_triggers:
		if t.should_run():
			t.run()
	# Observer autosaves on every room entry (GDD §8.1).
	if Difficulty.tuning().autosave_every_room and not StalkerDirector.chase_active:
		SaveSystem.save(SaveSystem.AUTOSAVE_SLOT)


## Synchronous swap without fades (used by go_to, save loading and tests).
func load_room_now(data: RoomData, spawn: StringName) -> Room:
	if current:
		var old_id := current.room_id()
		MapStatus.store(current)
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
	AudioDirector.play_ambience(data.ambience_present)
	_refresh_music()
	return current


func set_timeline(memory: bool) -> void:
	GameState.set_memory(memory)
	if current:
		current.set_timeline(memory)
		var data := current.room_data
		AudioDirector.play_ambience(data.ambience_memory if memory else data.ambience_present)
		_refresh_music()
	timeline_switched.emit(memory)


func _on_music_flag_changed(flag: String, _value: Variant) -> void:
	if current and flag == String(current.room_data.music_unlock_flag):
		_refresh_music()


func _refresh_music() -> void:
	var data := current.room_data
	var unlocked: bool = data.music_unlock_flag == &"" or GameState.get_flag(String(data.music_unlock_flag))
	AudioDirector.play_music(data.music_present if unlocked and not GameState.in_memory() else null)


## Brief full-screen flash (memory shift, being caught). Colour and timings are
## reduced with the photosensitivity option.
func flash(color: Color, hold := 0.15) -> void:
	var gentle: bool = Settings.get_value("photosensitivity")
	_fader.color = color
	await _fade(0.6 if gentle else 1.0, 0.35 if gentle else 0.12)
	await get_tree().create_timer(hold).timeout
	await _fade(0.0, 0.6)
	_fader.color = Color.BLACK


func _fade(target: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fader, "modulate:a", target, duration)
	await tween.finished
