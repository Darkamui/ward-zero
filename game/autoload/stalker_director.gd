extends Node
## The Man in White: room-graph simulation, noise propagation, state machine and 3D
## spawning (GDD §5.1, ADR-006). M1 implements the scripted Act 1 reveal chase; the full
## AI arrives in M2.

signal state_changed(state: State)
signal noise_heard(room_id: StringName, hops: int)
signal chase_started
signal chase_ended(escaped: bool)
signal player_caught
signal observer_recovered(safe_room: StringName)

enum State { DORMANT, PATROL, INVESTIGATE, SEARCH, CHASE, LOSE }

## Minimum warning before any entry into the player's room (rule R9).
const MIN_TELEGRAPH_SECONDS := 3.0
## Act 1 chase: faster than the player's walk, slower than their run, so it teaches that
## running saves you (docs/02-milestone-1.md M1-18). 1.1x (the plan's first guess) never
## caught a walking player across the Lobby; 1.6x (2.56 m/s vs 3.6 m/s running) does,
## while a player who reacts to the telegraph can still walk out.
const ACT1_SPEED_FACTOR := 1.6
const STALKER_SCENE := preload("res://game/characters/man_in_white/man_in_white.tscn")
const ACT1_CHASE_ROOM := &"G02"

var state: State = State.DORMANT
## Recent noise events for the debug overlay: [{ room, hops, time }].
var noise_log: Array[Dictionary] = []
var chase_active := false
## Save string captured when the chase starts: the retry checkpoint (decision D1).
var checkpoint := ""
var stalker: ManInWhite
var cue: ThreatCue
var _telegraph_started_at := 0.0


func _ready() -> void:
	EventBus.noise_emitted.connect(_on_noise_emitted)
	EventBus.script_requested.connect(_on_script_requested)
	RoomManager.room_exited.connect(_on_room_exited)
	cue = ThreatCue.new()
	add_child(cue)


func _on_noise_emitted(room_id: StringName, hops: int) -> void:
	noise_log.append({"room": room_id, "hops": hops, "time": Time.get_ticks_msec() / 1000.0})
	if noise_log.size() > 20:
		noise_log.pop_front()
	noise_heard.emit(room_id, hops)


func _on_script_requested(script_name: StringName) -> void:
	if script_name == &"act1_chase":
		start_act1_chase()


func set_state(new_state: State) -> void:
	if new_state != state:
		state = new_state
		state_changed.emit(new_state)


## Act 1 reveal (GDD §5.2): the barricade gives way and he walks out of the north-east
## door. Telegraphed for at least MIN_TELEGRAPH_SECONDS before he appears.
func start_act1_chase() -> void:
	var room := RoomManager.current
	if chase_active or room == null or room.room_id() != ACT1_CHASE_ROOM:
		return
	chase_active = true
	checkpoint = SaveSystem.export_string()
	var spawn := room.get_spawn(&"spawn_stalker")
	cue.start(_screen_side(spawn.global_position) if spawn else 0.0)
	_telegraph_started_at = Time.get_ticks_msec() / 1000.0
	set_state(State.CHASE)
	chase_started.emit()
	await get_tree().create_timer(MIN_TELEGRAPH_SECONDS + 0.5, false).timeout
	if not chase_active or RoomManager.current != room or spawn == null:
		return
	GameState.set_flag("g02.barricade_broken", true)
	stalker = STALKER_SCENE.instantiate()
	room.add_child(stalker)
	stalker.global_position = spawn.global_position
	stalker.caught_player.connect(_on_caught)
	stalker.pursue(RoomManager.player, Player.WALK_SPEED * ACT1_SPEED_FACTOR)


## Seconds between the start of the telegraph and the stalker appearing (for tests).
func telegraph_elapsed() -> float:
	return Time.get_ticks_msec() / 1000.0 - _telegraph_started_at


func _on_room_exited(_room_id: StringName) -> void:
	if chase_active:
		_end(true)


func _on_caught() -> void:
	if not chase_active:
		return
	var was_act1 := RoomManager.current != null and RoomManager.current.room_id() == ACT1_CHASE_ROOM
	chase_active = false
	cue.stop()
	set_state(State.DORMANT)
	if RoomManager.player:
		RoomManager.player.stop()
	RoomManager.flash(Color(0.95, 0.95, 0.92), 0.6)
	if Difficulty.tuning().catch_lethal:
		player_caught.emit()
		return
	if was_act1:
		GameState.set_flag("act1.chase_done", true)
		GameState.set_flag("g02.barricade_broken", true)
	observer_recover()


## Observer catch (GDD §8.1): the screen whites out and the player wakes in the nearest
## safe room; one droppable slot item stays where they were caught; composure drops.
func observer_recover() -> void:
	var room := RoomManager.current
	if room == null:
		return
	var droppable: Array[String] = []
	for item_id in GameState.inventory:
		var item: ItemData = ContentDB.get_item(item_id)
		if item and item.droppable:
			droppable.append(item_id)
	if not droppable.is_empty() and RoomManager.player:
		var lost := droppable[randi() % droppable.size()]
		GameState.remove_item(lost)
		room.add_dropped_item(lost, RoomManager.player.global_position)
	GameState.set_composure(GameState.composure - Difficulty.tuning().observer_composure_penalty)
	var safe := RoomGraph.nearest(room.room_id(), func(d: RoomData) -> bool: return d.safe_room)
	if safe == &"":
		return
	var scene := ContentDB.get_room(safe).scene.instantiate() as Room
	var spawn: StringName = scene.spawn_names()[0]
	scene.free()
	observer_recovered.emit(safe)
	await get_tree().create_timer(0.8).timeout
	RoomManager.go_to(safe, spawn)


func _end(escaped: bool) -> void:
	chase_active = false
	cue.stop()
	set_state(State.DORMANT)
	stalker = null
	if escaped:
		GameState.set_flag("act1.chase_done", true)
		GameState.set_flag("g02.barricade_broken", true)
	chase_ended.emit(escaped)


## Ends any chase without consequences (new game, loading a save).
func reset() -> void:
	chase_active = false
	cue.stop()
	stalker = null
	set_state(State.DORMANT)


func _screen_side(point: Vector3) -> float:
	var cam := CameraDirector.active_camera()
	if cam == null:
		return 0.0
	var screen := cam.unproject_position(point)
	return clampf(screen.x / cam.get_viewport().get_visible_rect().size.x * 2.0 - 1.0, -1.0, 1.0)
