class_name Player
extends CharacterBody3D
## Click-to-move controller (GDD §3.2). Targets are world-space points, so a walk keeps
## going across camera cuts and controls never flip. Running is faster but noisy.

signal arrived
signal move_cancelled
signal locomotion_changed(state: StringName)

const WALK_SPEED := 1.6
const RUN_SPEED := 3.6
const TURN_SPEED := 10.0
## While running, emit a 1-hop noise this often (GDD §5.1).
const RUN_NOISE_INTERVAL := 1.5
const GRAVITY := 9.8

var running := false
var locomotion: StringName = &"idle"
var _moving := false
var _on_arrive: Callable
var _noise_timer := 0.0

@onready var agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	add_to_group(&"player")
	collision_layer = 1 << 4
	collision_mask = (1 << 0) | (1 << 1)
	# Navmesh polygons sit up to ~0.2 m above the floor (voxel rounding) and these
	# distances are measured in 3D, so they must exceed that offset or the agent stalls.
	agent.path_desired_distance = 0.3
	agent.target_desired_distance = 0.3
	agent.radius = 0.3
	agent.height = 1.8


## Walks (or runs) to a point on the navmesh. on_arrive runs once on arrival, not on cancel.
func walk_to(point: Vector3, run := false, on_arrive := Callable()) -> void:
	running = run
	_on_arrive = on_arrive
	agent.target_position = point
	_moving = true
	if run:
		_noise_timer = 0.0


func stop() -> void:
	var was_moving := _moving
	_moving = false
	_on_arrive = Callable()
	velocity = Vector3.ZERO
	_set_locomotion(&"idle")
	if was_moving:
		move_cancelled.emit()


func is_moving() -> bool:
	return _moving


## Places the player at a spawn marker, facing its -Z.
func teleport(marker: Node3D) -> void:
	stop()
	global_position = marker.global_position
	rotation.y = marker.global_rotation.y
	agent.target_position = global_position


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	if _moving:
		if agent.is_navigation_finished():
			_finish()
		else:
			var next := agent.get_next_path_position()
			var dir := next - global_position
			dir.y = 0.0
			if dir.length() > 0.001:
				dir = dir.normalized()
				var speed := RUN_SPEED if running else WALK_SPEED
				velocity.x = dir.x * speed
				velocity.z = dir.z * speed
				var target_yaw := atan2(-dir.x, -dir.z)
				rotation.y = lerp_angle(rotation.y, target_yaw, clampf(TURN_SPEED * delta, 0.0, 1.0))
			_set_locomotion(&"run" if running else &"walk")
			if running:
				_noise_timer -= delta
				if _noise_timer <= 0.0:
					_noise_timer = RUN_NOISE_INTERVAL
					EventBus.noise_emitted.emit(StringName(GameState.current_room), 1)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
	move_and_slide()


func _finish() -> void:
	_moving = false
	velocity = Vector3.ZERO
	_set_locomotion(&"idle")
	var cb := _on_arrive
	_on_arrive = Callable()
	arrived.emit()
	if cb.is_valid():
		cb.call()


func _set_locomotion(state: StringName) -> void:
	if state != locomotion:
		locomotion = state
		locomotion_changed.emit(state)
