extends RoomTestBase
## Content contract for every room (docs/02-milestone-1.md M1-09): backgrounds, exits
## and spawns line up, exit hotspots match RoomData, and every hotspot is reachable on
## the navmesh from every spawn.

const ACT1_ROOMS := [&"G01", &"G02", &"G03", &"G04", &"G05", &"G06"]


func test_act1_rooms_registered() -> void:
	for id in ACT1_ROOMS:
		assert_true(ContentDB.get_room(id) != null, "%s registered" % id)


func test_backgrounds_and_cameras() -> void:
	for id in ContentDB.rooms:
		var data: RoomData = ContentDB.rooms[id]
		assert_false(data.cameras.is_empty(), "%s has cameras" % id)
		for c in data.cameras:
			assert_true(c.background != null, "%s/%s background" % [id, c.id])
			if data.has_memory_variant:
				assert_true(c.memory_background != null, "%s/%s memory background" % [id, c.id])
		var room := load_room(id, &"")
		expect_errors(1)  # no spawn named "" (expected)
		for c in data.cameras:
			assert_true(room.cameras.has(c.id), "%s scene has camera %s" % [id, c.id])
		CameraDirector.unregister_room()


func test_exits_lead_to_real_spawns() -> void:
	for id in ContentDB.rooms:
		var data: RoomData = ContentDB.rooms[id]
		for e in data.exits:
			var target: RoomData = ContentDB.get_room(e.target_room)
			assert_true(target != null, "%s.%s targets a room" % [id, e.id])
			if target:
				var scene := target.scene.instantiate() as Room
				assert_true(
					scene.get_node_or_null("Spawns/" + String(e.target_spawn)) != null,
					"%s.%s spawn %s exists" % [id, e.id, e.target_spawn]
				)
				scene.free()


func test_exit_hotspots_match_room_data() -> void:
	for id in ContentDB.rooms:
		var data: RoomData = ContentDB.rooms[id]
		var scene := data.scene.instantiate() as Room
		for h in scene.get_node("Hotspots").get_children():
			var hs := h as Interactable
			if hs.kind == Interactable.Kind.EXIT and hs.exit_id != &"":
				assert_true(
					data.get_exit(hs.exit_id) != null, "%s/%s exit %s defined" % [id, hs.name, hs.exit_id]
				)
		scene.free()


func test_hotspots_reachable_from_every_spawn() -> void:
	for id in ContentDB.rooms:
		var first: StringName = (ContentDB.rooms[id].scene.instantiate() as Room).spawn_names()[0]
		var room := load_room(id, first)
		await wait_nav_sync(room)
		var map := room.get_world_3d().navigation_map
		for spawn_name in room.spawn_names():
			var from := room.get_spawn(spawn_name).global_position
			for h in room.hotspots():
				var target: Vector3 = (h as Interactable).approach_position()
				var path := NavigationServer3D.map_get_path(map, from, target, true)
				var ok := path.size() > 0 and path[path.size() - 1].distance_to(target) < 0.35
				assert_true(ok, "%s: %s reachable from %s" % [id, h.name, spawn_name])
		CameraDirector.unregister_room()
