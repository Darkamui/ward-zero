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
signal breath_check_started(check: BreathCheck)
signal breath_check_ended(passed: bool)
signal stalker_spawned
signal stalker_despawned

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
## Act 2 patrol (docs/04-milestone-3.md §2): East and West wings and the Dining Hall.
const ACT2_ROUTE: Array[StringName] = [
	&"G07",
	&"G09",
	&"E01",
	&"E05",
	&"E04",
	&"E01",
	&"G09",
	&"W01",
	&"W05",
	&"W01",
	&"G09",
]
const ACT2_START := &"E05"

var state: State = State.DORMANT
## Recent noise events for the debug overlay: [{ room, hops, time }].
var noise_log: Array[Dictionary] = []
var chase_active := false
## Save string captured when the chase starts: the retry checkpoint (decision D1).
var checkpoint := ""
var stalker: ManInWhite
var cue: ThreatCue
## Room-graph AI (M2). Inactive in scripted-only zones (Act 1).
var sim: StalkerSim
var ai_active := false
var breath: BreathCheck
## Tests set this to simulate holding Space; null means read the input.
var breath_override: Variant = null
var _telegraph_started_at := 0.0
var _approach_token := 0
var _follow_pending := false


func _ready() -> void:
	EventBus.noise_emitted.connect(_on_noise_emitted)
	EventBus.script_requested.connect(_on_script_requested)
	RoomManager.room_exited.connect(_on_room_exited)
	RoomManager.room_entered.connect(_on_room_entered)
	cue = ThreatCue.new()
	add_child(cue)


func _on_noise_emitted(room_id: StringName, hops: int) -> void:
	noise_log.append({"room": room_id, "hops": hops, "time": Time.get_ticks_msec() / 1000.0})
	if noise_log.size() > 20:
		noise_log.pop_front()
	noise_heard.emit(room_id, hops)
	if ai_active and sim and stalker == null:
		sim.hear(room_id, hops)


# --- Room-graph AI (docs/03-milestone-2.md §3) ---------------------------------


## Starts the AI patrolling `route` (rooms), optionally from a given room.
func activate(route: Array[StringName], at := &"") -> void:
	sim = StalkerSim.new()
	sim.approaching_player.connect(_on_approaching)
	sim.state_changed.connect(func(st: int) -> void: set_state(_map_state(st)))
	sim.player_room = StringName(GameState.current_room)
	sim.start(route, Difficulty.tuning(), at)
	ai_active = true


## AI state for saving (GameState.stalker). Restored by restore().
func snapshot() -> Dictionary:
	if not ai_active or sim == null:
		return {"active": false}
	return {
		"active": true,
		"route": sim.patrol_route.map(func(r: StringName) -> String: return String(r)),
		"room": String(sim.room),
		"patrol_index": sim.patrol_index,
		"state": int(sim.state),
		"target": String(sim.target_room),
		"search_left": sim.search_left,
	}


## Resumes the AI from a saved snapshot (after loading a game).
func restore(d: Dictionary) -> void:
	reset()
	if not d.get("active", false):
		return
	var route: Array[StringName] = []
	for r in d.get("route", []):
		route.append(StringName(r))
	if route.is_empty():
		return
	activate(route, StringName(d.get("room", route[0])))
	sim.patrol_index = clampi(int(d.get("patrol_index", 0)), 0, route.size() - 1)
	sim.target_room = StringName(d.get("target", ""))
	sim.search_left = float(d.get("search_left", 0.0))
	var st := int(d.get("state", StalkerSim.State.PATROL))
	if st == StalkerSim.State.INVESTIGATE and sim.target_room == &"":
		st = StalkerSim.State.PATROL
	sim._set_state(st as StalkerSim.State)


func deactivate() -> void:
	ai_active = false
	if sim:
		sim.stop()
	sim = null
	_despawn()


func _physics_process(delta: float) -> void:
	if not ai_active or sim == null or get_tree().paused:
		return
	sim.player_room = StringName(GameState.current_room)
	sim.player_in_memory = GameState.in_memory()
	sim.hearing_extra = 1 if ComposureSystem.band() == ComposureSystem.Band.BREAKING else 0
	sim.tick(delta)
	GameState.stalker = snapshot()
	if breath:
		var holding: bool = (
			breath_override if breath_override != null else Input.is_action_pressed(&"hold_breath")
		)
		match breath.update(delta, holding):
			BreathCheck.Phase.PASSED:
				breath = null
				breath_check_ended.emit(true)
				if stalker:
					stalker.check_passed()
			BreathCheck.Phase.FAILED:
				breath = null
				breath_check_ended.emit(false)
				_handle_catch()


## True when the 3D stalker can see the player right now.
func stalker_sees_player() -> bool:
	return stalker != null and is_instance_valid(stalker) and stalker.can_see(RoomManager.player)


## He is at the door of the player's room: telegraph (rule R9), then spawn in 3D.
func _on_approaching(from_room: StringName) -> void:
	var room := RoomManager.current
	if room == null:
		sim.holding = false
		return
	_approach_token += 1
	var token := _approach_token
	var spawn_name := RoomGraph.spawn_from(room.room_id(), from_room)
	var spawn := room.get_spawn(spawn_name)
	cue.start(_screen_side(spawn.global_position) if spawn else 0.0)
	_telegraph_started_at = Time.get_ticks_msec() / 1000.0
	await get_tree().create_timer(MIN_TELEGRAPH_SECONDS + 0.2, false).timeout
	if token != _approach_token or not ai_active or sim == null:
		return
	if RoomManager.current != room or spawn == null or GameState.in_memory():
		# The player left (or shifted into a memory): he stays out.
		cue.stop()
		sim.holding = false
		sim.next_room = &""
		return
	sim.enter_player_room()
	_spawn_ai(room, spawn, from_room)


func _spawn_ai(room: Room, spawn: Marker3D, from_room: StringName) -> void:
	var t := Difficulty.tuning()
	stalker = STALKER_SCENE.instantiate()
	room.add_child(stalker)
	stalker.global_position = spawn.global_position
	stalker.rotation.y = spawn.global_rotation.y
	stalker.walk_speed = t.walk_speed
	stalker.run_speed = t.run_speed
	stalker.caught_player.connect(_handle_catch)
	stalker.left_room.connect(_on_stalker_left)
	stalker.approaching_spot.connect(_on_approaching_spot)
	stalker.checking_spot.connect(_on_checking_spot)
	var exit := _exit_toward(room, from_room)
	var spots := []
	var points := []
	for h in room.hotspots():
		if h is HidingSpot:
			spots.append(h)
	var map := room.get_world_3d().navigation_map
	for i in 2:
		var p := room.global_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		points.append(NavigationServer3D.map_get_closest_point(map, p))
	stalker_spawned.emit()
	if stalker.can_see(RoomManager.player):
		stalker.search(spots, points, exit["point"], exit["id"])
		stalker.chase(RoomManager.player)
		set_state(State.CHASE)
	else:
		stalker.search(spots, points, exit["point"], exit["id"])
		set_state(State.SEARCH)


## Exit he leaves by: toward the next room on his patrol, else back where he came from.
func _exit_toward(room: Room, preferred: StringName) -> Dictionary:
	var goal := preferred
	if sim and not sim.patrol_route.is_empty():
		goal = sim.patrol_route[sim.patrol_index]
	var best := {}
	for h in room.hotspots():
		var hs := h as Interactable
		if hs and hs.kind == Interactable.Kind.EXIT and hs.exit_def():
			var target := hs.exit_def().target_room
			var entry := {"id": hs.exit_id, "point": hs.approach_position(), "room": target}
			if best.is_empty() or target == preferred:
				best = entry
			var d := RoomGraph.distance(target, goal)
			if d >= 0 and d < RoomGraph.distance(StringName(best["room"]), goal):
				best = entry
	if best.is_empty():
		best = {"id": &"", "point": room.global_position, "room": preferred}
	return best


func _on_stalker_left(exit_id: StringName) -> void:
	var room := RoomManager.current
	var to_room: StringName = &""
	if room and room.room_data and room.room_data.get_exit(exit_id):
		to_room = room.room_data.get_exit(exit_id).target_room
	_despawn()
	if sim:
		sim.leave_player_room(to_room if to_room != &"" else sim.room)


func _on_approaching_spot(spot: HidingSpot) -> void:
	if spot.occupied() and not spot.compromised:
		var t := Difficulty.tuning()
		breath = BreathCheck.new(t.breath_required, t.breath_capacity)
		breath_check_started.emit(breath)


func _on_checking_spot(_spot: HidingSpot) -> void:
	if breath == null:
		var t := Difficulty.tuning()
		breath = BreathCheck.new(t.breath_required, t.breath_capacity)
		breath_check_started.emit(breath)
	breath.begin_check()


## Shared by the scripted chase and the AI: lethal → game over, Observer → recover.
func _handle_catch() -> void:
	if chase_active:
		_on_caught()
		return
	breath = null
	cue.stop()
	set_state(State.DORMANT)
	var player := RoomManager.player
	if player:
		if player.is_hidden():
			player.leave_hiding()
		player.stop()
	RoomManager.flash(Color(0.95, 0.95, 0.92), 0.6)
	_despawn()
	if sim:
		sim.holding = false
	if Difficulty.tuning().catch_lethal:
		player_caught.emit()
	else:
		observer_recover()


func _despawn() -> void:
	if stalker and is_instance_valid(stalker):
		stalker.queue_free()
		stalker_despawned.emit()
	stalker = null
	breath = null
	cue.stop()


static func _map_state(sim_state: int) -> State:
	match sim_state:
		StalkerSim.State.PATROL:
			return State.PATROL
		StalkerSim.State.INVESTIGATE:
			return State.INVESTIGATE
		StalkerSim.State.SEARCH:
			return State.SEARCH
	return State.DORMANT


func _on_script_requested(script_name: StringName) -> void:
	match script_name:
		&"act1_chase":
			start_act1_chase()
		&"act2_start":
			GameState.set_flag("act", 2)
			if not ai_active:
				activate(ACT2_ROUTE, ACT2_START)


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


func _on_room_entered(room_id: StringName) -> void:
	if _follow_pending and ai_active and sim:
		_follow_pending = false
		sim.player_room = room_id
		sim.follow(room_id)


func _on_room_exited(room_id: StringName) -> void:
	if chase_active:
		_end(true)
		return
	if not ai_active or sim == null:
		return
	_approach_token += 1
	if stalker and is_instance_valid(stalker):
		# He stays in the room the player left; if he was chasing he follows, announced
		# by the usual telegraph at the next door (GDD §5.1: "after a short delay").
		var was_chasing := stalker.mode == ManInWhite.Mode.CHASE
		_despawn()
		sim.room = room_id
		sim.holding = false
		sim.next_room = &""
		_follow_pending = was_chasing
	elif sim.holding:
		cue.stop()
		sim.holding = false
		sim.next_room = &""


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


## Ends any chase and the AI without consequences (new game, loading a save, tests).
func reset() -> void:
	chase_active = false
	ai_active = false
	sim = null
	breath = null
	breath_override = null
	_approach_token += 1
	_despawn()
	set_state(State.DORMANT)


func _screen_side(point: Vector3) -> float:
	var cam := CameraDirector.active_camera()
	if cam == null:
		return 0.0
	var screen := cam.unproject_position(point)
	return clampf(screen.x / cam.get_viewport().get_visible_rect().size.x * 2.0 - 1.0, -1.0, 1.0)
