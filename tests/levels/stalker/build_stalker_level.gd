extends RefCounted
## Greybox test level for the stalker AI (docs/03-milestone-2.md M2-09). Not shipped.
##   godot --headless res://tools/run_tool.tscn -- res://tests/levels/stalker/build_stalker_level.gd
##
##   T01 (safe) - T02 (corridor, locker) - T03 - T05 (scripted)
##                  \\                     /
##                   +------ T04 (bed) --+

const GB := preload("res://tools/greybox/greybox_lib.gd")
const DIR := "res://tests/levels/stalker"
const W := 8.0
const D := 6.0
const H := 3.0
const DOOR := 1.4


func run(_tree: SceneTree, _args: PackedStringArray) -> int:
	var rooms := {
		"T01": {"doors": [["e", 0.0, "T02"]], "access": RoomData.Access.NEVER, "safe": true},
		"T02":
		{"doors": [["w", 0.0, "T01"], ["e", 0.0, "T03"], ["n", 0.0, "T04"]], "access": RoomData.Access.OPEN},
		"T03":
		{"doors": [["w", 0.0, "T02"], ["n", 0.0, "T04"], ["e", 0.0, "T05"]], "access": RoomData.Access.OPEN},
		"T04":
		{"doors": [["s", -2.0, "T02"], ["s", 2.0, "T03"]], "access": RoomData.Access.OPEN, "unlit": true},
		"T05": {"doors": [["w", 0.0, "T03"]], "access": RoomData.Access.SCRIPTED},
	}
	for id in rooms:
		var err := _build(id, rooms[id])
		if err != OK:
			return 1
	print("build_stalker_level: OK")
	return 0


func _build(id: String, spec: Dictionary) -> Error:
	var g := GB.new(id)
	var gaps := []
	for d in spec["doors"]:
		gaps.append({"wall": d[0], "at": d[1], "width": DOOR})
	g.shell(W, D, H, Color(0.6, 0.6, 0.58), gaps)
	var exits := []
	var i := 0
	for d in spec["doors"]:
		var wall: String = d[0]
		var at: float = d[1]
		var target: String = d[2]
		var spawn_pos := _inside(wall, at)
		var exit_id := "to_%s_%d" % [target.to_lower(), i]
		g.spawn("spawn_from_%s" % target.to_lower(), spawn_pos, _yaw(wall))
		g.hotspot_exit(
			"hs_%s" % exit_id, _door_center(wall, at), Vector3(1.4, 2.2, 1.4), spawn_pos, StringName(exit_id)
		)
		exits.append(g.exit_def(exit_id, target, "spawn_from_%s" % id.to_lower()))
		i += 1
	if id == "T02":
		g.box(
			g.geometry,
			"occ_locker",
			Vector3(0.8, 2.0, 0.6),
			Vector3(-2.5, 1.0, -2.65),
			Color(0.4, 0.45, 0.45)
		)
		g.hiding_spot(
			"hs_locker",
			Vector3(-2.5, 1.0, -2.5),
			Vector3(0.9, 2.0, 0.8),
			Vector3(-2.5, 0, -1.7),
			Vector3(-2.5, 0, -2.6)
		)
		g.box(g.geometry, "occ_pillar", Vector3(0.5, H, 0.5), Vector3(1.0, H / 2, 1.8), Color(0.7, 0.7, 0.66))
	if id == "T04":
		g.box(g.geometry, "occ_bed", Vector3(2.0, 0.5, 1.0), Vector3(-2.4, 0.25, -2.3), Color(0.5, 0.5, 0.55))
		g.hiding_spot(
			"hs_bed",
			Vector3(-2.4, 0.4, -2.3),
			Vector3(2.1, 0.7, 1.1),
			Vector3(-2.4, 0, -1.3),
			Vector3(-2.4, 0, -2.3)
		)
	g.camera("cam_a", Vector3(3.6, 2.7, 2.6), Vector3(-1.5, 0.5, -1.2), 60.0)
	g.trigger("cam_a", Vector3(0, 1.0, 0), Vector3(W, 2.0, D))
	g.render_sun(Vector3(-50, 30, 0), 1.0)
	g.light_rigs(Vector3(-50, 30, 0))
	var data := g.room_data("%s/%s" % [DIR, id.to_lower()], ["cam_a"], exits)
	data.name_key = "ui.title"
	data.access = spec["access"]
	data.safe_room = spec.get("safe", false)
	data.unlit = spec.get("unlit", false)
	return g.save("%s/%s" % [DIR, id.to_lower()], id.to_lower(), data)


static func _inside(wall: String, at: float) -> Vector3:
	match wall:
		"w":
			return Vector3(-W / 2 + 0.6, 0, at)
		"e":
			return Vector3(W / 2 - 0.6, 0, at)
		"n":
			return Vector3(at, 0, -D / 2 + 0.6)
	return Vector3(at, 0, D / 2 - 0.6)


static func _door_center(wall: String, at: float) -> Vector3:
	match wall:
		"w":
			return Vector3(-W / 2, 1.1, at)
		"e":
			return Vector3(W / 2, 1.1, at)
		"n":
			return Vector3(at, 1.1, -D / 2)
	return Vector3(at, 1.1, D / 2)


static func _yaw(wall: String) -> float:
	match wall:
		"w":
			return -90.0
		"e":
			return 90.0
		"n":
			return 180.0
	return 0.0
