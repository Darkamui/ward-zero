extends TestCase
## Loads G01 through RoomManager in a throwaway world and checks the content contract:
## cameras and backgrounds, spawns, camera zones, and that every hotspot's approach point
## is reachable on the navmesh from every spawn (docs/02-milestone-1.md M1-09).

var _world: Node3D
var _player: Player


func before_each() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	_world = Node3D.new()
	tree.root.add_child(_world)
	_player = load("res://game/core/player/player.tscn").instantiate()
	_world.add_child(_player)
	RoomManager.setup(_world, _player)


func after_each() -> void:
	CameraDirector.unregister_room()
	RoomManager.current = null
	RoomManager.setup(null, null)
	_world.queue_free()


func _load(spawn: StringName) -> Room:
	return RoomManager.load_room_now(ContentDB.get_room(&"G01"), spawn)


func test_room_data_complete() -> void:
	var data := ContentDB.get_room(&"G01")
	assert_true(data != null, "G01 registered")
	assert_eq(data.cameras.size(), 2)
	for c in data.cameras:
		assert_true(c.background != null, "background for %s" % c.id)
	assert_eq(data.access, RoomData.Access.NEVER)
	assert_true(data.safe_room)


func test_cameras_match_room_data() -> void:
	var room := _load(&"spawn_start")
	for c in ContentDB.get_room(&"G01").cameras:
		assert_true(room.cameras.has(c.id), "scene has camera %s" % c.id)
	assert_eq(CameraDirector.active_id, &"cam_a")


func test_visual_proxies_keep_collision_separate() -> void:
	var room := _load(&"spawn_start")
	for part in ["chair", "couch", "pillar", "table_radio", "table_recorder", "bin"]:
		var collider := room.get_node("Geometry/col_" + part) as MeshInstance3D
		assert_false(collider.visible, "collision box must not hide the player: " + part)
		assert_true(collider.get_child_count() > 0, "collision body retained: " + part)
		var visual := room.get_node("Geometry/VisualProxies").find_child("vis_" + part, true, false)
		assert_true(visual is MeshInstance3D, "detailed silhouette: " + part)
		if visual is MeshInstance3D:
			assert_true(visual.visible, "visual proxy active: " + part)
			assert_eq(visual.get_child_count(), 0, "visual mesh creates no collision: " + part)
			assert_true(visual.material_override is ShaderMaterial, "background shader: " + part)


func test_zone_hysteresis() -> void:
	_load(&"spawn_start")
	assert_eq(CameraDirector.zone_camera_for(Vector3(-2, 0, 0)), &"cam_a")
	assert_eq(CameraDirector.zone_camera_for(Vector3(0.0, 0, 0)), &"cam_a", "overlap keeps current")
	assert_eq(CameraDirector.zone_camera_for(Vector3(2, 0, 0)), &"cam_b")
	CameraDirector.cut_to(&"cam_b")
	assert_eq(CameraDirector.zone_camera_for(Vector3(0.0, 0, 0)), &"cam_b", "overlap keeps current")


func test_spawn_places_player() -> void:
	var room := _load(&"spawn_from_g02")
	assert_true(_player.global_position.distance_to(room.get_spawn(&"spawn_from_g02").global_position) < 0.01)
	assert_eq(GameState.current_room, "G01")


func test_hotspots_reachable_from_every_spawn() -> void:
	var room := _load(&"spawn_start")
	var tree := Engine.get_main_loop() as SceneTree
	var map := room.get_world_3d().navigation_map
	# The map is shared with earlier tests: wait for two sync iterations after loading.
	var start_iteration := NavigationServer3D.map_get_iteration_id(map)
	for i in 30:
		if NavigationServer3D.map_get_iteration_id(map) >= start_iteration + 2:
			break
		await tree.physics_frame
	assert_true(room.navigation_region().navigation_mesh.get_polygon_count() > 0, "navmesh baked")
	for spawn_name in room.spawn_names():
		var from := room.get_spawn(spawn_name).global_position
		for h in room.hotspots():
			var target: Vector3 = (h as Interactable).approach_position()
			var path := NavigationServer3D.map_get_path(map, from, target, true)
			var ok := path.size() > 0 and path[path.size() - 1].distance_to(target) < 0.35
			assert_true(ok, "%s reachable from %s" % [h.name, spawn_name])
	# No walkable islands on furniture tops.
	for v in room.navigation_region().navigation_mesh.get_vertices():
		assert_between(v.y, -0.2, 0.3, "navmesh vertex at floor height")


func test_examine_hotspot_shows_text() -> void:
	var room := _load(&"spawn_start")
	var got := []
	var on_text := func(k: String) -> void: got.append(k)
	EventBus.text_requested.connect(on_text)
	(room.get_node("Hotspots/hs_couch") as Interactable).interact()
	EventBus.text_requested.disconnect(on_text)
	assert_eq(got, ["rooms.g01.couch.examine"])


func test_notice_opens_seeded_document_and_keeps_it_in_files() -> void:
	var room := _load(&"spawn_start")
	var reader := DocumentViewer.new()
	_world.add_child(reader)
	var notice := room.get_node("Hotspots/hs_notice") as Interactable
	assert_eq(notice.cursor(), Interactable.Cursor.EXAMINE)
	notice.interact()
	assert_true(reader.is_open())
	assert_eq(reader.doc.id, &"doc_quiet_hours")
	assert_has(GameState.documents, "doc_quiet_hours")
	assert_true(reader.shown_text().contains(str(PuzzleValues.value(&"P01", &"frequency"))))
	reader.close()
	notice.interact()
	assert_true(reader.is_open(), "notice can be read again")
	assert_eq(GameState.documents.count("doc_quiet_hours"), 1)
	reader.close()


func test_radio_opens_puzzle_and_solution_unlocks_door() -> void:
	var room := _load(&"spawn_start")
	var host := PuzzleHost.new()
	_world.add_child(host)
	var radio := room.get_node("Hotspots/hs_radio") as Interactable
	var door := room.get_node("Hotspots/hs_door") as Interactable
	assert_eq(radio.cursor(), Interactable.Cursor.HAND)
	assert_true(door.is_locked())
	radio.interact()
	assert_true(host.is_open())
	if host.current == null:
		return
	assert_eq(host.current.data.id, &"P01")
	assert_true(host.current.logic.apply_solution())
	host.current.report_attempt(true)
	assert_true(GameState.is_puzzle_solved("P01"))
	assert_false(door.is_locked())
	host.close()
	var got := []
	var on_text := func(k: String) -> void: got.append(k)
	EventBus.text_requested.connect(on_text)
	radio.interact()
	EventBus.text_requested.disconnect(on_text)
	assert_false(host.is_open(), "solved radio does not restart the puzzle")
	assert_eq(got, ["rooms.g01.radio.solved"])


func test_recorder_opens_save_screen() -> void:
	var room := _load(&"spawn_start")
	var screen := SaveScreen.new()
	_world.add_child(screen)
	var recorder := room.get_node("Hotspots/hs_recorder") as Interactable
	assert_eq(recorder.cursor(), Interactable.Cursor.HAND)
	recorder.interact()
	assert_true(screen.is_open())
	screen.close()


func test_effects_bin_opens_storage_inventory() -> void:
	var room := _load(&"spawn_start")
	var inventory := InventoryUi.new()
	_world.add_child(inventory)
	var bin := room.get_node("Hotspots/hs_bin") as Interactable
	assert_eq(bin.cursor(), Interactable.Cursor.HAND)
	bin.interact()
	assert_true(inventory.is_open())
	assert_true(inventory._bin_mode, "opens storage, not the regular inventory")
	assert_true(is_instance_valid(inventory._bin))
	inventory.close()


func test_chained_door_locked_until_flag() -> void:
	var room := _load(&"spawn_start")
	var door := room.get_node("Hotspots/hs_door") as Interactable
	assert_true(door.is_locked())
	assert_eq(door.cursor(), Interactable.Cursor.LOCKED)
	var got := []
	var on_text := func(k: String) -> void: got.append(k)
	EventBus.text_requested.connect(on_text)
	door.interact()
	EventBus.text_requested.disconnect(on_text)
	assert_eq(got, ["rooms.g01.door.chained"])
	GameState.set_flag("g01.chain_released")
	assert_false(door.is_locked())
	assert_eq(door.cursor(), Interactable.Cursor.EXIT)


func test_walk_across_cut_arrives() -> void:
	var room := _load(&"spawn_start")
	var tree := Engine.get_main_loop() as SceneTree
	var map := room.get_world_3d().navigation_map
	var start_iteration := NavigationServer3D.map_get_iteration_id(map)
	for i in 30:
		if NavigationServer3D.map_get_iteration_id(map) >= start_iteration + 2:
			break
		await tree.physics_frame
	var cuts: Array[StringName] = []
	var on_cut := func(id: StringName) -> void: cuts.append(id)
	CameraDirector.camera_cut.connect(on_cut)
	var arrived := [false]
	var door := room.get_node("Hotspots/hs_door") as Interactable
	_player.walk_to(door.approach_position(), true, func() -> void: arrived[0] = true)
	for i in 600:
		if arrived[0]:
			break
		await tree.physics_frame
	CameraDirector.camera_cut.disconnect(on_cut)
	assert_true(arrived[0], "player reached the door (at %s)" % _player.global_position)
	assert_eq(cuts, [&"cam_b"], "one cut on the way")


func test_radio_reward_updates_both_chain_backgrounds_without_cut() -> void:
	var room := _load(&"spawn_start")
	CameraDirector.cut_to(&"cam_a")
	for def in room.room_data.cameras:
		assert_true(def.state_background != null, "released art for " + String(def.id))
		assert_eq(CameraDirector.background_for(def.id), def.background)
	var cuts: Array[StringName] = []
	var on_cut := func(id: StringName) -> void: cuts.append(id)
	CameraDirector.camera_cut.connect(on_cut)
	var puzzle := PuzzleBase.new()
	puzzle.data = ContentDB.get_puzzle(&"P01")
	puzzle.logic = PuzzleValues.make_logic(puzzle.data)
	assert_true(puzzle.logic.apply_solution())
	puzzle.report_attempt(true)
	puzzle.free()
	for def in room.room_data.cameras:
		assert_eq(
			CameraDirector.background_for(def.id), def.state_background, "radio switches " + String(def.id)
		)
	assert_eq(cuts.size(), 0, "state refresh does not move the camera")
	CameraDirector.camera_cut.disconnect(on_cut)
	CameraDirector.cut_to(&"cam_b")
	assert_eq(CameraDirector.background_for(&"cam_b"), room.room_data.get_camera(&"cam_b").state_background)
	GameState.set_flag("g01.chain_released", false)
	assert_eq(CameraDirector.background_for(&"cam_b"), room.room_data.get_camera(&"cam_b").background)


func test_chain_art_survives_state_restore_and_room_reentry() -> void:
	var room := _load(&"spawn_start")
	GameState.set_flag("g01.chain_released")
	var saved := GameState.to_dict()
	GameState.set_flag("g01.chain_released", false)
	GameState.from_dict(saved)
	assert_eq(CameraDirector.background_for(&"cam_a"), room.room_data.get_camera(&"cam_a").state_background)
	var lobby := RoomManager.load_room_now(ContentDB.get_room(&"G02"), &"spawn_from_g01")
	for def in lobby.room_data.cameras:
		assert_eq(
			CameraDirector.background_for(def.id), def.background, "G01 flag does not change another room"
		)
	room = _load(&"spawn_from_g02")
	for def in room.room_data.cameras:
		assert_eq(CameraDirector.background_for(def.id), def.state_background, "released on return")
	assert_false((room.get_node("Hotspots/hs_door") as Interactable).is_locked())
	GameState.reset()
	room = _load(&"spawn_start")
	for def in room.room_data.cameras:
		assert_eq(CameraDirector.background_for(def.id), def.background, "new game starts chained")
