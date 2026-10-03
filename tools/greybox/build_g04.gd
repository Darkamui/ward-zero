extends RefCounted
## G04 Records Office greybox: the P03 card catalog and the P04 cipher memo.

const GB := preload("res://tools/greybox/greybox_lib.gd")
const DIR := "res://game/rooms/g04_records"
const W := 8.0
const D := 6.0
const H := 3.0


func run(_tree: SceneTree, _args: PackedStringArray) -> int:
	var g := GB.new("G04")
	var geo := g.geometry
	g.shell(
		W,
		D,
		H,
		Color(0.58, 0.6, 0.6),
		[{"wall": "s", "at": 0.0, "width": 1.8}, {"wall": "e", "at": -1.0, "width": 1.4}]
	)
	g.door("col_gate_g02", "s", 0.0, 1.8, W, D, Color(0.3, 0.3, 0.32))
	g.door("col_door_g05", "e", -1.0, 1.4, W, D)
	g.box(geo, "occ_catalog", Vector3(2.0, 1.2, 0.6), Vector3(-2.5, 0.6, -2.6), Color(0.42, 0.3, 0.2))
	g.box(geo, "occ_cabinets", Vector3(0.6, 1.4, 3.0), Vector3(-3.6, 0.7, 0.6), Color(0.45, 0.47, 0.45))
	g.box(geo, "occ_desk", Vector3(1.4, 0.75, 0.7), Vector3(2.0, 0.375, 1.5), Color(0.45, 0.33, 0.24))
	g.box(geo, "art_memo", Vector3(0.3, 0.02, 0.2), Vector3(2.0, 0.76, 1.5), Color(0.9, 0.9, 0.85))
	g.box(geo, "occ_shelf", Vector3(2.4, 2.0, 0.4), Vector3(1.6, 1.0, -2.75), Color(0.4, 0.3, 0.22))
	g.camera("cam_a", Vector3(3.6, 2.7, 2.6), Vector3(-2.0, 0.5, -1.5), 56.0)
	g.camera("cam_b", Vector3(-3.6, 2.7, 2.6), Vector3(2.0, 0.5, -1.5), 56.0)
	g.trigger("cam_a", Vector3(-2.15, 1.0, 0), Vector3(4.3, 2.0, D))
	g.trigger("cam_b", Vector3(2.15, 1.0, 0), Vector3(4.3, 2.0, D))
	var sun_rot := Vector3(-50, 30, 0)
	g.render_sun(sun_rot, 0.8)
	g.render_omni(Vector3(0, 2.8, 0), 1.2, 8.0)
	g.light_rigs(sun_rot)
	g.spawn("spawn_from_g02", Vector3(0.0, 0, 2.4), 0.0)
	g.spawn("spawn_from_g05", Vector3(3.4, 0, -1.0), 90.0)
	var kind := Interactable.Kind
	g.hotspot_exit(
		"hs_gate_g02", Vector3(0.0, 1.1, 2.95), Vector3(1.8, 2.2, 0.3), Vector3(0.0, 0, 2.4), &"to_g02"
	)
	g.hotspot_exit(
		"hs_door_g05", Vector3(3.95, 1.1, -1.0), Vector3(0.3, 2.2, 1.4), Vector3(3.4, 0, -1.0), &"to_g05"
	)
	g.hotspot(
		"hs_catalog",
		kind.USE,
		Vector3(-2.5, 0.7, -2.5),
		Vector3(2.1, 1.3, 0.7),
		Vector3(-2.5, 0, -1.8),
		[GB.puzzle_or_text("P03", "rooms.g04.catalog.solved")]
	)
	g.hotspot(
		"hs_cipher_memo",
		kind.EXAMINE,
		Vector3(2.0, 0.8, 1.5),
		Vector3(0.6, 0.2, 0.5),
		Vector3(2.0, 0, 0.75),
		[GB.doc("doc_cipher_memo")]
	)
	g.hotspot(
		"hs_cabinets",
		kind.EXAMINE,
		Vector3(-3.6, 0.8, 0.6),
		Vector3(0.7, 1.5, 3.1),
		Vector3(-2.9, 0, 0.6),
		[GB.text("rooms.g04.cabinets.examine")]
	)
	var sedatives := g.hotspot(
		"hs_sedatives", kind.TAKE, Vector3(1.6, 1.1, -2.6), Vector3(0.6, 0.4, 0.4), Vector3(1.6, 0, -1.9)
	)
	sedatives.item_id = &"item_sedatives"
	var data := g.room_data(
		DIR,
		["cam_a", "cam_b"],
		[g.exit_def("to_g02", "G02", "spawn_from_g04"), g.exit_def("to_g05", "G05", "spawn_from_g04")]
	)
	data.name_key = "rooms.g04.name"
	data.access = RoomData.Access.SCRIPTED
	data.map_rect = Rect2(40, 60, 140, 80)
	var err := g.save(DIR, "g04_records", data)
	print("build_g04: ", error_string(err))
	return 0 if err == OK else 1
