extends RefCounted
## G03 Reception greybox: the P02 switchboard.

const GB := preload("res://tools/greybox/greybox_lib.gd")
const DIR := "res://game/rooms/g03_reception"
const W := 7.0
const D := 5.0
const H := 3.0


func run(_tree: SceneTree, _args: PackedStringArray) -> int:
	var g := GB.new("G03")
	var geo := g.geometry
	g.shell(W, D, H, Color(0.6, 0.62, 0.58), [{"wall": "w", "at": 0.0, "width": 1.4}])
	g.door("col_door_g02", "w", 0.0, 1.4, W, D)
	g.box(geo, "occ_desk", Vector3(2.5, 1.0, 0.8), Vector3(1.0, 0.5, -0.5), Color(0.45, 0.33, 0.24))
	g.box(geo, "art_memo", Vector3(0.3, 0.02, 0.2), Vector3(1.0, 1.01, -0.5), Color(0.9, 0.9, 0.85))
	g.box(geo, "occ_switchboard", Vector3(1.6, 1.6, 0.4), Vector3(1.6, 0.8, -2.3), Color(0.2, 0.18, 0.16))
	g.box(
		geo,
		"art_directory",
		Vector3(0.6, 0.8, 0.02),
		Vector3(-1.5, 1.6, -D / 2 + 0.01),
		Color(0.9, 0.88, 0.8)
	)
	g.box(geo, "occ_chair", Vector3(0.5, 0.9, 0.5), Vector3(-1.8, 0.45, 1.2), Color(0.45, 0.33, 0.24))
	g.camera("cam_a", Vector3(-3.1, 2.7, 2.1), Vector3(1.4, 0.6, -1.4), 58.0)
	g.trigger("cam_a", Vector3(0, 1.0, 0), Vector3(W, 2.0, D))
	var sun_rot := Vector3(-50, 120, 0)
	g.render_sun(sun_rot, 0.9)
	g.render_omni(Vector3(0, 2.8, 0), 1.2, 7.0)
	g.light_rigs(sun_rot)
	g.spawn("spawn_from_g02", Vector3(-2.9, 0, 0.0), -90.0)
	var kind := Interactable.Kind
	g.hotspot_exit(
		"hs_door_g02", Vector3(-3.45, 1.1, 0.0), Vector3(0.3, 2.2, 1.4), Vector3(-2.9, 0, 0.0), &"to_g02"
	)
	g.hotspot(
		"hs_switchboard",
		kind.USE,
		Vector3(1.6, 0.9, -2.2),
		Vector3(1.7, 1.7, 0.5),
		Vector3(1.6, 0, -1.65),
		[GB.puzzle_or_text("P02", "rooms.g03.switchboard.solved")]
	)
	g.hotspot(
		"hs_directory",
		kind.EXAMINE,
		Vector3(-1.5, 1.6, -2.4),
		Vector3(0.7, 0.9, 0.2),
		Vector3(-1.5, 0, -1.8),
		[GB.doc("doc_staff_directory")]
	)
	g.hotspot(
		"hs_memo",
		kind.EXAMINE,
		Vector3(1.0, 1.05, -0.5),
		Vector3(0.5, 0.2, 0.4),
		Vector3(1.0, 0, 0.45),
		[GB.doc("doc_desk_memo")]
	)
	var cassette_rule := DifficultyIs.new()
	cassette_rule.threat = "committed"
	var cassette := g.hotspot(
		"hs_blank_cassette",
		kind.TAKE,
		Vector3(-1.8, 1.0, 1.2),
		Vector3(0.5, 0.4, 0.5),
		Vector3(-1.8, 0, 0.5),
		[],
		[cassette_rule]
	)
	cassette.item_id = &"item_blank_cassette"
	var data := g.room_data(DIR, ["cam_a"], [g.exit_def("to_g02", "G02", "spawn_from_g03")])
	data.name_key = "rooms.g03.name"
	data.access = RoomData.Access.SCRIPTED
	data.map_rect = Rect2(280, 180, 100, 80)
	var err := g.save(DIR, "g03_reception", data)
	print("build_g03: ", error_string(err))
	return 0 if err == OK else 1
