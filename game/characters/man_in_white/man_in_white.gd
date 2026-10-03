class_name ManInWhite
extends CharacterBody3D
## The stalker's 3D body (GDD §5.1). Only exists while he is in the player's room; the
## StalkerDirector decides when. Walks toward a target on the navmesh. Silent by design.

signal caught_player

const CATCH_DISTANCE := 0.8
const GRAVITY := 9.8

var speed := 1.76
var target: Node3D
var active := false

@onready var agent: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	collision_layer = 1 << 5
	collision_mask = (1 << 0) | (1 << 1)
	agent.path_desired_distance = 0.3
	agent.target_desired_distance = 0.3
	agent.radius = 0.3


func pursue(new_target: Node3D, walk_speed: float) -> void:
	target = new_target
	speed = walk_speed
	active = true


func _physics_process(delta: float) -> void:
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	if not active or target == null or not is_instance_valid(target):
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	var flat := target.global_position - global_position
	flat.y = 0.0
	if flat.length() <= CATCH_DISTANCE:
		active = false
		caught_player.emit()
		return
	agent.target_position = target.global_position
	var next := agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() > 0.001:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(8.0 * delta, 0.0, 1.0))
	move_and_slide()
