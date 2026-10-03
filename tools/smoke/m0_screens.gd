extends RefCounted
## M0 visual smoke test: runs the game scene, places the player behind occluders on both
## cameras, walks across the camera cut, and saves screenshots to production/screens/.
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --audio-driver Dummy \
##       --resolution 1920x1080 res://tools/run_tool.tscn -- res://tools/smoke/m0_screens.gd

const OUT := "res://production/screens"

var _tree: SceneTree
var _failures := 0


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	_tree = tree
	DirAccess.make_dir_recursive_absolute(OUT)
	var game: Node = load("res://game/main/game.tscn").instantiate()
	tree.root.add_child(game)
	await _wait(1.2)
	var player: Player = game.get_node("Player")
	_check(CameraDirector.active_id == &"cam_a", "starts on cam_a")
	await _shot("m0_01_cam_a_spawn")

	await _place(player, Vector3(-2.0, 0, -0.2), 0.0)
	_check(CameraDirector.active_id == &"cam_a", "behind pillar uses cam_a")
	await _shot("m0_02_cam_a_behind_pillar")
	RenderingServer.global_shader_parameter_set(&"wz_debug_proxies", 1.0)
	await _shot("m0_03_cam_a_debug_proxies")
	RenderingServer.global_shader_parameter_set(&"wz_debug_proxies", 0.0)

	await _place(player, Vector3(2.35, 0, 1.15), 90.0)
	_check(CameraDirector.active_id == &"cam_b", "east half cuts to cam_b")
	await _shot("m0_04_cam_b_behind_chair")

	# Walk from the west half to the door: the path must survive the cut to cam_b.
	await _place(player, Vector3(-2.5, 0, -1.0), 0.0)
	var cuts: Array[StringName] = []
	var on_cut := func(id: StringName) -> void: cuts.append(id)
	CameraDirector.camera_cut.connect(on_cut)
	var arrived := [false]
	player.walk_to(Vector3(2.5, 0, -2.6), false, func() -> void: arrived[0] = true)
	var t := 0.0
	while not arrived[0] and t < 10.0:
		await _tree.physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
	CameraDirector.camera_cut.disconnect(on_cut)
	_check(arrived[0], "walk across the cut arrives (%.1fs, ended at %s)" % [t, player.global_position])
	_check(cuts == [&"cam_b"], "exactly one cut during the walk, got %s" % [cuts])
	await _shot("m0_05_arrived_at_door")
	print("m0_screens: %d failure(s)" % _failures)
	return 1 if _failures else 0


func _place(player: Player, pos: Vector3, yaw: float) -> void:
	var m := Marker3D.new()
	m.position = pos
	m.rotation_degrees.y = yaw
	_tree.root.add_child(m)
	player.teleport(m)
	m.queue_free()
	await _wait(0.3)


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := _tree.root.get_texture().get_image()
	var path := OUT.path_join(shot_name + ".png")
	img.save_png(ProjectSettings.globalize_path(path))
	print("m0_screens: saved %s %s" % [path, img.get_size()])


func _check(ok: bool, what: String) -> void:
	print("m0_screens: %s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func _wait(seconds: float) -> void:
	await _tree.create_timer(seconds).timeout
