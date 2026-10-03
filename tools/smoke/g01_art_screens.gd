extends RefCounted
## GPU validation of the Blender cameras and detailed occluders in the actual engine.
## Run through tools/run_tool.tscn at --resolution 1920x1080 (not --headless).

const OUT := "res://production/art-review/g01_dayroom/runtime"
const REFERENCE := "res://production/art-review/g01_dayroom/projection-reference.json"

var _tree: SceneTree
var _player: Player
var _room: Room
var _failures := 0
var _projection_error := 0.0


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	_tree = tree
	DirAccess.make_dir_recursive_absolute(OUT)
	GameState.reset()
	GameState.set_flag("intro.done")
	var world := Node3D.new()
	tree.root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color.BLACK
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_energy = 0.0
	env.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.add_child(env)
	_player = load("res://game/core/player/player.tscn").instantiate()
	world.add_child(_player)
	RoomManager.setup(world, _player)
	_room = RoomManager.load_room_now(ContentDB.get_room(&"G01"), &"spawn_start")
	await _wait(0.8)
	_check(tree.root.size == Vector2i(1920, 1080), "1920x1080 validation viewport")
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE))
	for camera_id in [&"cam_a", &"cam_b"]:
		CameraDirector.cut_to(camera_id)
		var cam: Camera3D = _room.cameras[camera_id]
		for sample in reference[String(camera_id)]:
			var xyz: Array = sample["world"]
			var pixel: Array = sample["pixel"]
			var actual := cam.unproject_position(Vector3(xyz[0], xyz[1], xyz[2]))
			_projection_error = maxf(_projection_error, actual.distance_to(Vector2(pixel[0], pixel[1])))
	_check(_projection_error <= 2.0, "Blender/Godot projection error <= 2 px: %.4f" % _projection_error)
	await _place(Vector3(-2.0, 0, -0.2))
	await _shot("cam_a_pillar")
	RenderingServer.global_shader_parameter_set(&"wz_debug_proxies", 1.0)
	await _shot("cam_a_proxies")
	RenderingServer.global_shader_parameter_set(&"wz_debug_proxies", 0.0)
	# West of the recorder table, then behind the chair in camera B.
	await _place(Vector3(-3.95, 0, -3.22))
	await _shot("cam_a_table")
	await _place(Vector3(-4.05, 0, 2.0))
	await _shot("cam_a_couch")
	await _place(Vector3(-3.8, 0, -1.35))
	await _shot("cam_a_bin")
	await _place(Vector3(2.35, 0, 1.15))
	await _shot("cam_b_chair")
	RenderingServer.global_shader_parameter_set(&"wz_debug_proxies", 1.0)
	await _shot("cam_b_proxies")
	RenderingServer.global_shader_parameter_set(&"wz_debug_proxies", 0.0)
	await _place(Vector3(4.1, 0, -2.45))
	await _shot("cam_b_radio")
	await _place(Vector3(-2.5, 0, -1.0))
	var cuts: Array[StringName] = []
	var on_cut := func(id: StringName) -> void: cuts.append(id)
	CameraDirector.camera_cut.connect(on_cut)
	var arrived := [false]
	_player.walk_to(Vector3(2.5, 0, -2.6), false, func() -> void: arrived[0] = true)
	for i in 900:
		if arrived[0]:
			break
		await tree.physics_frame
	CameraDirector.camera_cut.disconnect(on_cut)
	_check(arrived[0], "walk across room reaches door")
	_check(cuts == [&"cam_b"], "exactly one camera cut during walk")
	await _shot("cam_b_door")
	# Both chain states use the same background sampler as every detailed proxy.
	# Disable automatic cuts while reviewing camera A from the door-side spawn.
	CameraDirector.set_physics_process(false)
	_player.visible = false
	for camera_id in [&"cam_a", &"cam_b"]:
		CameraDirector.cut_to(camera_id)
		for released in [false, true]:
			GameState.set_flag("g01.chain_released", released)
			var def := _room.room_data.get_camera(camera_id)
			var expected := def.state_background if released else def.background
			_check(CameraDirector.background_for(camera_id) == expected, "chain state selects matching art")
			await _wait(0.1)
			await _shot("%s_chain_%s" % [camera_id, "released" if released else "locked"])
	CameraDirector.set_physics_process(true)
	_player.visible = true
	var report := {
		"failures": _failures,
		"max_projection_error_px": _projection_error,
		"walk_reached_door": arrived[0],
		"camera_cuts": cuts,
		"screenshots": 13,
		"engine": Engine.get_version_info()["string"],
		"asset_sha256":
		{
			"game/rooms/g01_dayroom/bg/cam_a.webp":
			FileAccess.get_sha256("res://game/rooms/g01_dayroom/bg/cam_a.webp"),
			"game/rooms/g01_dayroom/bg/cam_b.webp":
			FileAccess.get_sha256("res://game/rooms/g01_dayroom/bg/cam_b.webp"),
			"game/rooms/g01_dayroom/bg/cam_a_released.webp":
			FileAccess.get_sha256("res://game/rooms/g01_dayroom/bg/cam_a_released.webp"),
			"game/rooms/g01_dayroom/bg/cam_b_released.webp":
			FileAccess.get_sha256("res://game/rooms/g01_dayroom/bg/cam_b_released.webp"),
			"game/rooms/g01_dayroom/proxy.glb":
			FileAccess.get_sha256("res://game/rooms/g01_dayroom/proxy.glb"),
		},
	}
	var file := FileAccess.open(OUT.path_join("validation.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	CameraDirector.unregister_room()
	RoomManager.current = null
	RoomManager.setup(null, null)
	world.queue_free()
	await tree.process_frame
	print("g01_art_screens: %d failures" % _failures)
	return 1 if _failures else 0


func _place(pos: Vector3) -> void:
	var marker := Marker3D.new()
	marker.position = pos
	_tree.root.add_child(marker)
	_player.teleport(marker)
	marker.queue_free()
	await _wait(0.3)


func _shot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var img := _tree.root.get_texture().get_image()
	var err := img.save_png(OUT.path_join(filename + ".png"))
	_check(err == OK, "saved " + filename)


func _wait(seconds: float) -> void:
	await _tree.create_timer(seconds).timeout


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		_failures += 1
