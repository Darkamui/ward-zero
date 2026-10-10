extends Node3D
## Presentation only: the Player keeps ownership of movement and collision.
## Mixamo clips are retargeted to the supplied bind pose and stripped of forward travel.

const CLIP_INFO := preload("res://game/characters/mathieu/animation_info.tres")

@onready var animations: AnimationPlayer = $Model/AnimationPlayer


func _ready() -> void:
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 1 << (ProxyProcessor.VISUAL_CHARACTERS - 1)
	for clip in [&"idle", &"walk", &"run"]:
		if animations.has_animation(clip):
			animations.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	var player := get_parent() as Player
	if player:
		player.locomotion_changed.connect(_on_locomotion_changed)
		_on_locomotion_changed(player.locomotion)
	else:
		_on_locomotion_changed(&"idle")


func _on_locomotion_changed(state: StringName) -> void:
	var clip := state
	if state == &"run" and not animations.has_animation(clip):
		clip = &"walk"
	if not animations.has_animation(clip):
		return
	var native_speed := float(CLIP_INFO.get_meta(String(clip) + "_speed", 0.0))
	var speed := Player.RUN_SPEED if state == &"run" else Player.WALK_SPEED
	# In-place downloads have no measurable travel: retain their authored cadence.
	animations.speed_scale = speed / native_speed if native_speed > 0.1 else 1.0
	animations.play(clip, 0.15)
