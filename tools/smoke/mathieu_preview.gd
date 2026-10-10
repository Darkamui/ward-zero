extends RefCounted
## Render the imported skinned asset in Godot's Compatibility renderer.


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(900, 1000)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	tree.root.add_child(viewport)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.16, 0.18, 0.20)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.8, 0.85, 1.0)
	environment.environment.ambient_light_energy = 0.55
	viewport.add_child(environment)
	var model: Node3D = load("res://game/characters/mathieu/mathieu.glb").instantiate()
	viewport.add_child(model)
	model.print_tree_pretty()
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(2.0, 1.35, -3.8)
	camera.look_at(Vector3(0, 0.88, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.1
	var light := DirectionalLight3D.new()
	viewport.add_child(light)
	light.rotation_degrees = Vector3(-35, -35, 0)
	light.light_energy = 1.5
	var animation: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	print("ANIMATIONS ", animation.get_animation_list())
	DirAccess.make_dir_recursive_absolute("res://production/art-review/mathieu")
	for clip in [&"idle", &"walk", &"run"]:
		animation.play(clip)
		animation.seek(0.2, true)
		animation.pause()
		await tree.process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://production/art-review/mathieu/" + clip + ".png")
	viewport.queue_free()
	await tree.process_frame
	await tree.process_frame
	return 0
