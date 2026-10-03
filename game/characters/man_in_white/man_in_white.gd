class_name ManInWhite
extends CharacterBody3D
## The stalker's 3D body (GDD §5.1). Exists only while he is in the player's room.
## Modes: SEARCH (visit hiding spots and a few points, then leave), CHASE (saw the
## player: run at them), LEAVE (walk out through a door), plus PURSUE for scripted chases.
## Silent by design. StalkerDirector owns his lifetime and reacts to his signals.

signal caught_player
signal approaching_spot(spot: HidingSpot)
signal checking_spot(spot: HidingSpot)
signal left_room(through_exit: StringName)
signal saw_player
signal lost_player

enum Mode { IDLE, PURSUE, SEARCH, CHASE, LEAVE }

const CATCH_DISTANCE := 0.8
const GRAVITY := 9.8
const SIGHT_RANGE := 15.0
const SIGHT_HALF_ANGLE := 55.0
const EYE_HEIGHT := 1.75
const LOSE_TIME := 8.0
const SPOT_PAUSE := 0.6

var mode := Mode.IDLE
var speed := 1.5
var walk_speed := 1.5
var run_speed := 2.8
var target: Node3D
## Scripted chases ignore sight and hiding.
var scripted := false
## While a breath check runs he waits at the spot.
var waiting_on_check := false
var _waypoints: Array = []  # Vector3 or HidingSpot
var _exit_point := Vector3.ZERO
var _exit_id: StringName = &""
var _unseen := 0.0
var _pause := 0.0

@onready var agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	collision_layer = 1 << 5
	collision_mask = (1 << 0) | (1 << 1)
	agent.path_desired_distance = 0.3
	agent.target_desired_distance = 0.35
	agent.radius = 0.3


## Scripted chase (Act 1): walks at the given speed straight at the target.
func pursue(new_target: Node3D, walk: float) -> void:
	scripted = true
	target = new_target
	speed = walk
	mode = Mode.PURSUE


## AI entry: search the room (visiting `spots`, then `points`), then leave via exit.
func search(spots: Array, points: Array, exit_point: Vector3, exit_id: StringName) -> void:
	scripted = false
	_waypoints = spots + points
	_exit_point = exit_point
	_exit_id = exit_id
	speed = walk_speed
	mode = Mode.SEARCH
	_next_waypoint()


func chase(player: Node3D) -> void:
	target = player
	speed = run_speed
	_unseen = 0.0
	mode = Mode.CHASE
	saw_player.emit()


## Line of sight to the player's head within his view cone (not through walls/furniture).
func can_see(player: Player) -> bool:
	if player == null or player.is_hidden():
		return false
	var eye := global_position + Vector3(0, EYE_HEIGHT, 0)
	var head := player.global_position + Vector3(0, 1.55, 0)
	var to := head - eye
	if to.length() > SIGHT_RANGE:
		return false
	var forward := -global_transform.basis.z
	var flat_to := Vector3(to.x, 0, to.z).normalized()
	if rad_to_deg(forward.angle_to(flat_to)) > SIGHT_HALF_ANGLE:
		return false
	var q := PhysicsRayQueryParameters3D.create(eye, head, 1 << 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _physics_process(delta: float) -> void:
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	var player := RoomManager.player
	match mode:
		Mode.PURSUE:
			if _close_to(target):
				_catch()
				return
			_move_to(target.global_position, delta)
		Mode.SEARCH:
			if player and can_see(player):
				chase(player)
				return
			if waiting_on_check:
				_stand()
				return
			if _pause > 0.0:
				_pause -= delta
				_stand()
				return
			if _arrived():
				_reach_waypoint()
			else:
				_move_to(agent.target_position, delta)
		Mode.CHASE:
			if player == null or player.is_hidden():
				_unseen += delta
			elif can_see(player):
				_unseen = 0.0
			else:
				_unseen += delta
			if _unseen >= LOSE_TIME:
				lost_player.emit()
				search(_spots_in_room(), [], _exit_point, _exit_id)
				return
			if player and not player.is_hidden() and _close_to(player):
				_catch()
				return
			_move_to(player.global_position if player else global_position, delta)
		Mode.LEAVE:
			if _arrived():
				mode = Mode.IDLE
				left_room.emit(_exit_id)
				return
			_move_to(_exit_point, delta)
		_:
			_stand()


func _next_waypoint() -> void:
	if _waypoints.is_empty():
		mode = Mode.LEAVE
		agent.target_position = _exit_point
		return
	var w: Variant = _waypoints[0]
	agent.target_position = w.approach_position() if w is HidingSpot else w
	if w is HidingSpot and is_instance_valid(w) and w.occupied():
		approaching_spot.emit(w)


func _reach_waypoint() -> void:
	var w: Variant = _waypoints.pop_front()
	_pause = SPOT_PAUSE
	if w is HidingSpot and is_instance_valid(w):
		_face(w.global_position)
		if w.occupied():
			if w.compromised:
				_catch()
				return
			waiting_on_check = true
			checking_spot.emit(w)
			return
	_next_waypoint()


## Director: the breath check at the current spot ended without him finding the player.
func check_passed() -> void:
	waiting_on_check = false
	_next_waypoint()


func _spots_in_room() -> Array:
	var result := []
	if RoomManager.current:
		for h in RoomManager.current.hotspots():
			if h is HidingSpot:
				result.append(h)
	return result


func _arrived() -> bool:
	var d := agent.target_position - global_position
	d.y = 0.0
	return d.length() <= 0.45


func _close_to(node: Node3D) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	var flat := node.global_position - global_position
	flat.y = 0.0
	return flat.length() <= CATCH_DISTANCE


func _catch() -> void:
	mode = Mode.IDLE
	_stand()
	caught_player.emit()


func _move_to(point: Vector3, delta: float) -> void:
	agent.target_position = point
	var next := agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() > 0.001:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(8.0 * delta, 0.0, 1.0))
	move_and_slide()


func _stand() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	move_and_slide()


func _face(point: Vector3) -> void:
	var d := point - global_position
	if Vector2(d.x, d.z).length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)
