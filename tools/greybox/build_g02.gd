extends RefCounted
## G02 Main Lobby greybox (docs/02-milestone-1.md §2-3). 3 cameras, the Act 1 chase
## arena: the stalker comes out of the north-east door, the player escapes south-west.

const GB := preload("res://tools/greybox/greybox_lib.gd")
const DIR := "res://game/rooms/g02_main_lobby"
const W := 12.0
const D := 10.0
const H := 4.0


func run(_tree: SceneTree, _args: PackedStringArray) -> int:
	var g := GB.new("G02")
	var geo := g.geometry
	var wall := Color(0.66, 0.62, 0.55)
	(
		g
		. shell(
			W,
			D,
			H,
			wall,
			[
				{"wall": "s", "at": -3.0, "width": 1.4},
				{"wall": "n", "at": -3.0, "width": 1.8},
				{"wall": "n", "at": 3.5, "width": 1.4},
				{"wall": "e", "at": 1.0, "width": 1.4},
				{"wall": "w", "at": 1.0, "width": 1.6},
			],
			2.6
		)
	)
	g.door("col_door_g01", "s", -3.0, 1.4, W, D, Color(0.36, 0.26, 0.18), 2.6)
	g.door("col_gate_g04", "n", -3.0, 1.8, W, D, Color(0.3, 0.3, 0.32), 2.6)
	g.door("col_door_g09", "n", 3.5, 1.4, W, D, Color(0.33, 0.24, 0.17), 2.6)
	g.box(
		geo, "art_barricade", Vector3(1.6, 1.2, 0.3), Vector3(3.5, 0.9, -D / 2 + 0.25), Color(0.4, 0.34, 0.26)
	)
	g.door("col_door_g03", "e", 1.0, 1.4, W, D, Color(0.36, 0.26, 0.18), 2.6)
	g.door("col_door_g06", "w", 1.0, 1.6, W, D, Color(0.42, 0.3, 0.2), 2.6)
	g.box(geo, "occ_pillar_w", Vector3(0.6, H, 0.6), Vector3(-1.6, H / 2, -1.6), Color(0.72, 0.70, 0.66))
	g.box(geo, "occ_pillar_e", Vector3(0.6, H, 0.6), Vector3(1.6, H / 2, -1.6), Color(0.72, 0.70, 0.66))
	g.box(geo, "occ_planter", Vector3(1.6, 0.7, 1.6), Vector3(0.0, 0.35, 1.8), Color(0.35, 0.32, 0.28))
	g.box(geo, "occ_bench", Vector3(2.0, 0.5, 0.6), Vector3(3.8, 0.25, 3.9), Color(0.45, 0.33, 0.24))
	g.box(
		geo, "art_plaque", Vector3(0.04, 0.7, 1.0), Vector3(W / 2 - 0.02, 1.7, -2.5), Color(0.62, 0.52, 0.3)
	)
	g.box(
		geo, "art_notice", Vector3(0.02, 0.8, 0.6), Vector3(-W / 2 + 0.01, 1.6, -2.5), Color(0.9, 0.88, 0.8)
	)

	g.camera("cam_a", Vector3(5.5, 3.4, 4.5), Vector3(-3.0, 0.6, -2.5), 55.0)
	g.camera("cam_b", Vector3(-5.5, 3.4, 4.5), Vector3(3.0, 0.6, -2.5), 55.0)
	g.camera("cam_c", Vector3(0.0, 3.7, -4.7), Vector3(0.0, 0.4, 3.0), 60.0)
	g.trigger("cam_a", Vector3(-2.85, 1.0, -2.1), Vector3(6.3, 2.0, 5.8))
	g.trigger("cam_b", Vector3(2.85, 1.0, -2.1), Vector3(6.3, 2.0, 5.8))
	g.trigger("cam_c", Vector3(0.0, 1.0, 2.6), Vector3(W, 2.0, 4.8))

	var sun_rot := Vector3(-55, 200, 0)
	g.render_sun(sun_rot, 1.2)
	g.render_omni(Vector3(0, 3.8, 0), 1.4, 12.0)
	g.render_omni(Vector3(-3, 3.6, 3), 0.6, 7.0)
	g.light_rigs(sun_rot)

	g.spawn("spawn_from_g01", Vector3(-3.0, 0, 4.2), 0.0)
	g.spawn("spawn_from_g03", Vector3(5.2, 0, 1.0), 90.0)
	g.spawn("spawn_from_g04", Vector3(-3.0, 0, -4.2), 180.0)
	g.spawn("spawn_from_g06", Vector3(-5.2, 0, 1.0), -90.0)
	g.spawn("spawn_stalker", Vector3(3.5, 0, -4.2), 180.0)

	var kind := Interactable.Kind
	g.hotspot_exit(
		"hs_door_g01", Vector3(-3.0, 1.3, 4.95), Vector3(1.4, 2.6, 0.3), Vector3(-3.0, 0, 4.2), &"to_g01"
	)
	g.hotspot_exit(
		"hs_door_g03", Vector3(5.95, 1.3, 1.0), Vector3(0.3, 2.6, 1.4), Vector3(5.2, 0, 1.0), &"to_g03"
	)
	g.hotspot_exit(
		"hs_gate", Vector3(-3.0, 1.3, -4.95), Vector3(1.8, 2.6, 0.3), Vector3(-3.0, 0, -4.2), &"to_g04"
	)
	g.hotspot_exit(
		"hs_door_g06", Vector3(-5.95, 1.3, 1.0), Vector3(0.3, 2.6, 1.6), Vector3(-5.2, 0, 1.0), &"to_g06"
	)
	g.hotspot(
		"hs_plaque",
		kind.EXAMINE,
		Vector3(5.9, 1.7, -2.5),
		Vector3(0.3, 0.8, 1.1),
		Vector3(5.0, 0, -2.5),
		[GB.doc("doc_founding_plaque")]
	)
	g.hotspot(
		"hs_visitor_notice",
		kind.EXAMINE,
		Vector3(-5.9, 1.6, -2.5),
		Vector3(0.3, 0.9, 0.7),
		Vector3(-5.0, 0, -2.5),
		[GB.doc("doc_visitor_notice")]
	)
	g.hotspot(
		"hs_barricade",
		kind.EXAMINE,
		Vector3(3.5, 1.3, -4.9),
		Vector3(1.6, 2.6, 0.4),
		Vector3(3.5, 0, -4.2),
		[GB.text("rooms.g02.barricade")],
		[GB.flag("g02.barricade_broken", false)]
	)
	g.hotspot(
		"hs_corridor",
		kind.USE,
		Vector3(3.5, 1.3, -4.9),
		Vector3(1.6, 2.6, 0.4),
		Vector3(3.5, 0, -4.2),
		[
			GB.when(
				[GB.has("item_choleric_key")], [GB.ui("end_of_slice")], [GB.text("rooms.g02.corridor.locked")]
			)
		],
		[GB.flag("g02.barricade_broken")]
	)

	var data := (
		g
		. room_data(
			DIR,
			["cam_a", "cam_b", "cam_c"],
			[
				g.exit_def("to_g01", "G01", "spawn_from_g02"),
				g.exit_def("to_g03", "G03", "spawn_from_g02"),
				g.exit_def("to_g04", "G04", "spawn_from_g02", "g02.gate_open", "rooms.g02.gate.locked"),
				g.exit_def("to_g06", "G06", "spawn_from_g02"),
			]
		)
	)
	data.name_key = "rooms.g02.name"
	data.access = RoomData.Access.OPEN
	data.map_rect = Rect2(40, 140, 240, 160)
	data.enter_triggers = [
		GB.on_enter(
			[GB.has("item_choleric_key"), GB.flag("act1.chase_done", false)], [GB.script("act1_chase")]
		),
	]
	var err := g.save(DIR, "g02_main_lobby", data)
	print("build_g02: ", error_string(err))
	return 0 if err == OK else 1
