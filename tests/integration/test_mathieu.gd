extends TestCase
## Verify the actual imported rig, movement presentation and render budget together.

var _player: Player


func before_each() -> void:
	_player = load("res://game/core/player/player.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(_player)
	_player.set_physics_process(false)


func after_each() -> void:
	_player.free()


func test_imported_character_has_skin_and_fits_budget() -> void:
	var model := _player.get_node("Mathieu/Model")
	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	assert_true(skeleton != null, "import includes skeleton")
	if skeleton == null:
		return
	assert_true(skeleton.get_bone_count() >= 60, "Mixamo humanoid and fingers retained")
	var triangles := 0
	var surfaces := 0
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		assert_true(mesh.skin != null, "mesh is bound to the skeleton")
		assert_eq(mesh.layers, 2, "uses room character lighting layer")
		for surface in mesh.mesh.get_surface_count():
			triangles += mesh.mesh.surface_get_array_index_len(surface) / 3
			surfaces += 1
	assert_between(triangles, 15000, 25000, "browser triangle budget")
	assert_eq(surfaces, 2, "opaque body and masked hair")


func test_locomotion_plays_real_clips_and_stop_returns_to_idle() -> void:
	var animations: AnimationPlayer = _player.get_node("Mathieu/Model/AnimationPlayer")
	var skeleton := _player.get_node("Mathieu/Model").find_child("Skeleton3D", true, false) as Skeleton3D
	assert_eq(animations.current_animation, "idle")
	for state in [&"walk", &"run"]:
		_player.set("locomotion", state)
		_player.locomotion_changed.emit(state)
		assert_eq(animations.current_animation, state)
		assert_eq(animations.get_animation(state).loop_mode, Animation.LOOP_LINEAR)
		animations.advance(0.2)  # Complete the idle -> locomotion crossfade.
		animations.seek(0.0, true)
		var pose := skeleton.get_bone_pose_rotation(skeleton.find_bone("mixamorig7_LeftUpLeg"))
		animations.seek(0.2, true)
		var moved := skeleton.get_bone_pose_rotation(skeleton.find_bone("mixamorig7_LeftUpLeg"))
		assert_false(pose.is_equal_approx(moved), "leg bones animate in " + state)
	_player.stop()
	assert_eq(animations.current_animation, "idle")


func test_locomotion_does_not_move_mesh_away_from_collision() -> void:
	var animations: AnimationPlayer = _player.get_node("Mathieu/Model/AnimationPlayer")
	var skeleton := _player.get_node("Mathieu/Model").find_child("Skeleton3D", true, false) as Skeleton3D
	var hips := skeleton.find_bone("mixamorig7_Hips")
	for clip in [&"walk", &"run"]:
		animations.play(clip, 0.0)
		animations.advance(0.0)
		animations.seek(0.0, true)
		var first := skeleton.get_bone_pose_position(hips)
		animations.seek(animations.get_animation(clip).length - 0.001, true)
		var last := skeleton.get_bone_pose_position(hips)
		# Mixamo's local Hips X/Z axes are horizontal; Y carries the vertical bob.
		assert_between(Vector2(last.x - first.x, last.z - first.z).length(), 0.0, 0.1, clip)
