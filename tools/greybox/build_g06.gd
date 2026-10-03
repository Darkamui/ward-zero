extends RefCounted
## G06 Chapel greybox: P05 hymn board and the memory-shift tutorial (1976 variant).
## present_only / memory_only art differs between the two renders (ADR-004).

const GB := preload("res://tools/greybox/greybox_lib.gd")
const DIR := "res://game/rooms/g06_chapel"
const W := 8.0
const D := 12.0
const H := 5.0


func run(_tree: SceneTree, _args: PackedStringArray) -> int:
	var g := GB.new("G06")
	var geo := g.geometry
	g.shell(W, D, H, Color(0.7, 0.68, 0.62), [{"wall": "e", "at": 3.0, "width": 1.6}], 2.8)
	g.door("col_door_g02", "e", 3.0, 1.6, W, D, Color(0.42, 0.3, 0.2), 2.8)
	g.box(geo, "occ_altar", Vector3(2.6, 1.0, 1.0), Vector3(0.0, 0.5, -5.0), Color(0.75, 0.72, 0.66))
	g.box(geo, "art_cross", Vector3(0.15, 1.4, 0.1), Vector3(0.0, 2.6, -5.9), Color(0.5, 0.42, 0.3))
	g.box(
		geo,
		"art_hymn_board",
		Vector3(0.05, 1.4, 1.0),
		Vector3(-W / 2 + 0.03, 2.0, -3.5),
		Color(0.3, 0.22, 0.16)
	)
	for i in 3:
		var y := 2.4 - i * 0.4
		g.timeline_only(
			g.box(
				geo,
				"art_hymn_numbers_%d" % i,
				Vector3(0.03, 0.25, 0.7),
				Vector3(-W / 2 + 0.06, y, -3.5),
				Color(0.92, 0.9, 0.82)
			),
			true
		)
	g.timeline_only(
		g.box(
			geo,
			"art_hymn_card_fallen",
			Vector3(0.7, 0.03, 0.25),
			Vector3(-3.3, 0.02, -3.2),
			Color(0.92, 0.9, 0.82)
		),
		false
	)
	for row in 4:
		var z := -2.0 + row * 1.6
		g.box(
			geo, "occ_pew_w_%d" % row, Vector3(2.4, 0.9, 0.6), Vector3(-1.8, 0.45, z), Color(0.4, 0.29, 0.2)
		)
		g.box(geo, "occ_pew_e_%d" % row, Vector3(2.4, 0.9, 0.6), Vector3(1.8, 0.45, z), Color(0.4, 0.29, 0.2))
	g.timeline_only(
		g.box(geo, "art_debris", Vector3(1.4, 0.2, 1.0), Vector3(1.2, 0.1, -3.4), Color(0.45, 0.42, 0.38)),
		false
	)
	for i in 2:
		g.timeline_only(
			g.box(
				geo,
				"art_candle_%d" % i,
				Vector3(0.08, 0.35, 0.08),
				Vector3(-0.8 + i * 1.6, 1.18, -5.0),
				Color(0.98, 0.95, 0.85)
			),
			true
		)
	g.box(geo, "occ_loft_stairs", Vector3(1.2, 1.6, 2.0), Vector3(-3.2, 0.8, 4.6), Color(0.38, 0.28, 0.2))
	g.camera("cam_a", Vector3(3.3, 4.2, 5.4), Vector3(-1.0, 0.8, -3.0), 55.0)
	g.camera("cam_b", Vector3(-3.3, 4.2, -5.4), Vector3(1.0, 0.8, 3.5), 55.0)
	g.trigger("cam_a", Vector3(0, 1.0, -2.85), Vector3(W, 2.0, 6.3))
	g.trigger("cam_b", Vector3(0, 1.0, 2.85), Vector3(W, 2.0, 6.3))
	var sun_rot := Vector3(-40, 100, 0)
	g.timeline_only(g.render_sun(sun_rot, 0.9, Color(0.8, 0.85, 1.0)), false)
	g.timeline_only(g.render_omni(Vector3(0, 4.5, -2), 0.8, 12.0, Color(0.85, 0.9, 1.0)), false)
	g.timeline_only(g.render_sun(sun_rot, 1.3, Color(1.0, 0.85, 0.6)), true)
	g.timeline_only(g.render_omni(Vector3(0, 2.0, -4.6), 2.0, 9.0, Color(1.0, 0.75, 0.45)), true)
	g.timeline_only(g.render_omni(Vector3(0, 4.5, 2), 1.0, 12.0, Color(1.0, 0.85, 0.6)), true)
	g.light_rigs(sun_rot)
	g.spawn("spawn_from_g02", Vector3(3.4, 0, 3.0), 90.0)
	var kind := Interactable.Kind
	g.hotspot_exit(
		"hs_door_g02", Vector3(3.95, 1.4, 3.0), Vector3(0.3, 2.8, 1.6), Vector3(3.4, 0, 3.0), &"to_g02"
	)
	g.hotspot(
		"hs_hymn_board",
		kind.USE,
		Vector3(-3.9, 2.0, -3.5),
		Vector3(0.3, 1.5, 1.1),
		Vector3(-3.2, 0, -3.5),
		[GB.puzzle_or_text("P05", "rooms.g06.board.solved")],
		[GB.in_memory(false)]
	)
	g.hotspot(
		"hs_hymn_board_1976",
		kind.EXAMINE,
		Vector3(-3.9, 2.0, -3.5),
		Vector3(0.3, 1.5, 1.1),
		Vector3(-3.2, 0, -3.5),
		[GB.doc("doc_hymn_board_1976")],
		[GB.in_memory(true)]
	)
	var altar := g.hotspot(
		"hs_altar",
		kind.USE,
		Vector3(0.0, 0.9, -4.9),
		Vector3(2.6, 1.0, 1.0),
		Vector3(0.0, 0, -4.0),
		[
			GB.when(
				[GB.in_memory()],
				[MemoryShift.new()],
				[
					GB.when(
						[GB.has("item_photograph")],
						[GB.text("rooms.g06.altar.use_anchor")],
						[GB.text("rooms.g06.altar.resonant")]
					)
				]
			)
		]
	)
	altar.accepts_items = {&"item_photograph": [MemoryShift.new()]}
	altar.reject_item_key = "rooms.g06.altar.wrong_item"
	g.hotspot(
		"hs_hymnal",
		kind.EXAMINE,
		Vector3(1.8, 0.95, 0.4),
		Vector3(2.4, 0.3, 0.6),
		Vector3(1.8, 0, 1.2),
		[GB.doc("doc_hymnal_page")]
	)
	g.hotspot(
		"hs_loft",
		kind.EXAMINE,
		Vector3(-3.2, 1.0, 4.6),
		Vector3(1.3, 1.8, 2.1),
		Vector3(-2.2, 0, 4.4),
		[GB.text("rooms.g06.loft.locked")],
		[GB.flag("g06.loft_open", false)]
	)
	var crank := g.hotspot(
		"hs_crank",
		kind.TAKE,
		Vector3(-3.2, 1.0, 4.6),
		Vector3(1.3, 1.8, 2.1),
		Vector3(-2.2, 0, 4.4),
		[GB.text("rooms.g06.crank.taken")],
		[GB.flag("g06.loft_open")]
	)
	crank.item_id = &"item_music_box_crank"
	var data := g.room_data(DIR, ["cam_a", "cam_b"], [g.exit_def("to_g02", "G02", "spawn_from_g06")])
	data.name_key = "rooms.g06.name"
	data.access = RoomData.Access.SCRIPTED
	data.has_memory_variant = true
	data.map_rect = Rect2(0, 180, 40, 120)
	var err := g.save(DIR, "g06_chapel", data)
	print("build_g06: ", error_string(err))
	return 0 if err == OK else 1
