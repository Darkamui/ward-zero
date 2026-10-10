extends RefCounted
## Exercise the live controller and capture both fixed cameras with the Mixamo hero.

const OUT := "res://production/art-review/mathieu/"

var _tree: SceneTree
var _failures := 0


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	_tree = tree
	var game: Node = load("res://game/main/game.tscn").instantiate()
	tree.root.add_child(game)
	await tree.create_timer(1.5).timeout
	var player: Player = game.get_node("Player")
	var animation: AnimationPlayer = player.get_node("Mathieu/Model/AnimationPlayer")
	await _shot("gameplay_idle")
	player.walk_to(Vector3(2.5, 0, -2.6))
	await tree.create_timer(0.6).timeout
	_check(animation.current_animation == "walk", "walk clip follows navigation")
	await _shot("gameplay_walk")
	await _arrive(player)
	_check(CameraDirector.active_id == &"cam_b", "crossed into second fixed camera")
	_check(animation.current_animation == "idle", "arrival returns to idle")
	# The doorway is behind the central pillar from cam_b; capture a visible spot.
	var camera_b_marker := Marker3D.new()
	camera_b_marker.position = Vector3(2.35, 0, 1.15)
	camera_b_marker.rotation_degrees.y = 90
	tree.root.add_child(camera_b_marker)
	player.teleport(camera_b_marker)
	camera_b_marker.queue_free()
	await tree.create_timer(0.3).timeout
	await _shot("gameplay_cam_b")
	player.walk_to(Vector3(-2.4, 0, -1.4), true)
	await tree.create_timer(0.4).timeout
	_check(animation.current_animation == "run", "run clip follows navigation")
	await _shot("gameplay_run")
	await _arrive(player)
	player.stop()
	var marker := Marker3D.new()
	marker.position = Vector3(-2.0, 0, -0.2)
	tree.root.add_child(marker)
	player.teleport(marker)
	marker.queue_free()
	await tree.create_timer(0.3).timeout
	await _shot("gameplay_occlusion")
	CameraDirector.unregister_room()
	RoomManager.current = null
	RoomManager.setup(null, null)
	game.queue_free()
	await tree.process_frame
	await tree.process_frame
	print("mathieu_gameplay: %d failure(s)" % _failures)
	return 1 if _failures else 0


func _arrive(player: Player) -> void:
	var elapsed := 0.0
	while player.is_moving() and elapsed < 12:
		await _tree.physics_frame
		elapsed += 1.0 / Engine.physics_ticks_per_second
	_check(not player.is_moving(), "navigation arrives without animation root drift")


func _shot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	_tree.root.get_texture().get_image().save_png(OUT + filename + ".png")


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		_failures += 1
