extends RefCounted
## Render matching transparent icons from the actual examine models in Godot.


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	var out := "res://game/items/icons"
	DirAccess.make_dir_recursive_absolute(out)
	for id in [&"item_dictaphone", &"item_wristband"]:
		var view := ExamineView.new()
		view.size = Vector2(512, 512)
		tree.root.add_child(view)
		view.setup(ContentDB.get_item(id))
		view._camera.fov = 55
		var container := view.get_child(1) as SubViewportContainer
		var viewport := container.get_child(0) as SubViewport
		await tree.create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var error := viewport.get_texture().get_image().save_png(out.path_join(String(id) + ".png"))
		view.queue_free()
		await tree.process_frame
		if error != OK:
			return 1
	return 0
