extends RefCounted
## Clay-renders every camera of a room to WebP backgrounds (greybox stand-ins for the
## Blender renders, docs/02-milestone-1.md §7). Needs a real GPU context, e.g.:
##   xvfb-run -a godot --rendering-driver opengl3 res://tools/run_tool.tscn -- \
##       res://tools/greybox/render_room.gd G01 [--memory]
## Writes game/rooms/<dir>/bg/<cam>.webp (or bg_mem/ with --memory). Afterwards run
## `godot --headless --import` and the room's build script again to link the textures.

const SIZE := Vector2i(1920, 1080)
const WEBP_QUALITY := 0.85


func run(tree: SceneTree, args: PackedStringArray) -> int:
	if args.is_empty():
		push_error("usage: <ROOM_ID> [--memory]")
		return 1
	var room_id := StringName(args[0])
	var memory := args.has("--memory")
	var root := tree.root
	var data: RoomData = ContentDB.get_room(room_id)
	if data == null or data.scene == null:
		push_error("render_room: unknown room %s" % room_id)
		return 1
	GameState.set_memory(memory)
	Room.render_mode = true
	var room: Room = data.scene.instantiate()
	room.room_data = data
	root.add_child(room)

	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.05, 0.05, 0.06)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.57, 0.6) if not memory else Color(0.7, 0.6, 0.45)
	env.environment.ambient_light_energy = 0.45
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	root.add_child(env)

	# Game light rigs are for the live character only.
	for cam in room.cameras.values():
		var rig: Node3D = cam.get_node_or_null("LightRig")
		if rig:
			rig.visible = false

	var vp := SubViewport.new()
	vp.size = SIZE
	vp.world_3d = root.world_3d
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var shot_cam := Camera3D.new()
	vp.add_child(shot_cam)
	root.add_child(vp)

	var room_dir := data.scene.resource_path.get_base_dir()
	var out_dir := room_dir.path_join("bg_mem" if memory else "bg")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var failures := 0 if not room.cameras.is_empty() else 1
	for id in room.cameras:
		var src: Camera3D = room.cameras[id]
		shot_cam.global_transform = src.global_transform
		shot_cam.fov = src.fov
		shot_cam.near = src.near
		shot_cam.far = src.far
		shot_cam.keep_aspect = Camera3D.KEEP_HEIGHT
		shot_cam.current = true
		for i in 4:
			await tree.process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		if img.get_size() != SIZE:
			img.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)
		var path := out_dir.path_join("%s.webp" % id)
		var err := img.save_webp(ProjectSettings.globalize_path(path), true, WEBP_QUALITY)
		print("render_room: %s -> %s (%s)" % [id, path, error_string(err)])
		if err != OK:
			failures += 1
	return 1 if failures else 0
