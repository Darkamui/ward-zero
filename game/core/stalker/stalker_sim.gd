class_name StalkerSim
extends RefCounted
## Off-screen Man in White (GDD §5.1, ADR-006): a position on the room graph that patrols,
## investigates noises and searches. Pure logic, advanced by tick(). When his next step
## would enter the player's room he stops and emits `approaching_player`; StalkerDirector
## then telegraphs and spawns him in 3D, and calls `enter_player_room()`.

signal arrived(room_id: StringName)
signal approaching_player(from_room: StringName)
signal state_changed(state: int)

enum State { DORMANT, PATROL, INVESTIGATE, SEARCH }

## Metres per room-to-room edge (time per edge = EDGE_LENGTH / speed).
const EDGE_LENGTH := 10.0

var state := State.DORMANT
var room: StringName = &""
var next_room: StringName = &""
var progress := 0.0
var patrol_route: Array[StringName] = []
var patrol_index := 0
var target_room: StringName = &""
var search_left := 0.0
var tuning: StalkerTuning
## True while he waits at a door to enter the player's room (or is there in 3D).
var holding := false
## Player position on the graph and whether they are in a memory (which he can't enter).
var player_room: StringName = &""
var player_in_memory := false
## Extra hearing hops (composure Breaking adds 1).
var hearing_extra := 0


func start(route: Array[StringName], tuning_res: StalkerTuning, at := &"") -> void:
	patrol_route = route
	tuning = tuning_res
	room = at if at != &"" else route[0]
	patrol_index = maxi(0, route.find(room))
	next_room = &""
	progress = 0.0
	holding = false
	_set_state(State.PATROL)


func stop() -> void:
	_set_state(State.DORMANT)
	next_room = &""
	holding = false


## Can he walk into this room? Never into `never` rooms, scripted rooms or a memory.
func passable(room_id: StringName) -> bool:
	var data: RoomData = ContentDB.get_room(room_id)
	if data == null or data.access != RoomData.Access.OPEN:
		return false
	return not (room_id == player_room and player_in_memory)


func tick(delta: float) -> void:
	if state == State.DORMANT or holding:
		return
	if next_room != &"":
		progress += delta * _speed() / EDGE_LENGTH
		if progress >= 1.0:
			room = next_room
			next_room = &""
			progress = 0.0
			arrived.emit(room)
			_on_arrived()
		return
	match state:
		State.PATROL:
			_step_toward(patrol_route[patrol_index])
		State.INVESTIGATE:
			_step_toward(target_room)
		State.SEARCH:
			search_left -= delta
			if search_left <= 0.0:
				_resume_patrol()


## A noise of `hops` in `noise_room` (GDD §5.1). Returns whether he heard it.
func hear(noise_room: StringName, hops: int) -> bool:
	if state == State.DORMANT or holding:
		return false
	var reach := hops + (tuning.hearing_bonus if tuning else 0) + hearing_extra
	if reach < 0:
		return false
	# Sound travels through every room; only his movement is limited by access flags.
	var d := RoomGraph.distance(room, noise_room)
	if d < 0 or d > reach:
		return false
	target_room = noise_room
	_set_state(State.INVESTIGATE)
	if room == noise_room:
		_begin_search()
	return true


## Chase continues through a door: head for that room now (the director telegraphs).
func follow(to_room: StringName) -> void:
	if state == State.DORMANT:
		return
	target_room = to_room
	holding = false
	next_room = &""
	_set_state(State.INVESTIGATE)


## Called by the director once he has been spawned in the player's room.
func enter_player_room() -> void:
	if next_room == &"":
		return
	room = next_room
	next_room = &""
	progress = 0.0


## Called by the director when the 3D stalker leaves the player's room through a door.
func leave_player_room(to_room: StringName) -> void:
	holding = false
	room = to_room
	next_room = &""
	_resume_patrol()


func _speed() -> float:
	var walk := tuning.walk_speed if tuning else 1.5
	return walk * (1.3 if state == State.INVESTIGATE else 1.0)


func _step_toward(goal: StringName) -> void:
	if room == goal:
		_on_arrived()
		return
	var p := RoomGraph.path(room, goal, _passable_or_target.bind(goal))
	if p.size() < 2 or not passable(p[1]):
		# Goal unreachable (e.g. the player moved into a memory): give up.
		_resume_patrol()
		return
	next_room = p[1]
	progress = 0.0
	if next_room == player_room:
		holding = true
		approaching_player.emit(room)


func _on_arrived() -> void:
	match state:
		State.PATROL:
			if room == patrol_route[patrol_index]:
				patrol_index = (patrol_index + 1) % patrol_route.size()
		State.INVESTIGATE:
			if room == target_room:
				_begin_search()


func _begin_search() -> void:
	search_left = tuning.search_time if tuning else 10.0
	_set_state(State.SEARCH)


func _resume_patrol() -> void:
	var best := 0
	var best_d := 1 << 30
	for i in patrol_route.size():
		var d := RoomGraph.distance(room, patrol_route[i])
		if d >= 0 and d < best_d:
			best_d = d
			best = i
	patrol_index = best
	_set_state(State.PATROL)


func _passable_or_target(room_id: StringName, target: StringName) -> bool:
	return room_id == target or passable(room_id)


func _set_state(s: State) -> void:
	if s != state:
		state = s
		state_changed.emit(s)
