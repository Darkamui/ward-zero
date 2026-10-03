extends "res://tools/greybox/build_act2.gd"
## Greybox builder for the Upper Floor (U01-U06) and the Basement (B02-B07), Acts 3-4
## (docs/05-milestone-4.md §1). Same table format and helpers as build_act2.gd.
##   godot --headless res://tools/run_tool.tscn -- res://tools/greybox/build_act34.gd [ROOM_ID...]

const STONE := Color(0.5, 0.5, 0.48)
const ROOMS34 := {
	"U01":
	{
		"dir": "u01_upper_hall",
		"size": [14.0, 5.0, 3.4],
		"cams": 3,
		"access": RoomData.Access.OPEN,
		"floor": RoomData.Floor.UPPER,
		"map": [100, 150, 300, 50],
		"doors":
		[
			["e", 0.0, "G09", {}],
			["n", -4.5, "U02", {}],
			["n", 0.0, "U03", {}],
			["n", 4.5, "U05", {}],
			["s", -3.0, "U04", {}],
		],
	},
	"U02":
	{
		"dir": "u02_library",
		"size": [10.0, 8.0, 3.6],
		"cams": 2,
		"access": RoomData.Access.SCRIPTED,
		"floor": RoomData.Floor.UPPER,
		"map": [100, 40, 110, 100],
		"doors":
		[
			["s", 0.0, "U01", {}],
			["w", 1.0, "U06", {"flag": "u02.secret_open", "locked": "rooms.u02.shelf_d"}],
		],
	},
	"U03":
	{
		"dir": "u03_reading_room",
		"size": [6.0, 5.0, 3.0],
		"cams": 1,
		"access": RoomData.Access.NEVER,
		"floor": RoomData.Floor.UPPER,
		"map": [210, 90, 70, 60],
		"safe": true,
		"doors": [["s", 0.0, "U01", {}]],
	},
	"U04":
	{
		"dir": "u04_pharmacy",
		"size": [7.0, 5.0, 3.0],
		"cams": 1,
		"access": RoomData.Access.SCRIPTED,
		"floor": RoomData.Floor.UPPER,
		"map": [200, 200, 90, 60],
		"doors": [["n", 0.0, "U01", {}]],
	},
	"U05":
	{
		"dir": "u05_observation_theatre",
		"size": [10.0, 8.0, 4.0],
		"cams": 2,
		"access": RoomData.Access.SCRIPTED,
		"floor": RoomData.Floor.UPPER,
		"map": [290, 40, 110, 100],
		"doors": [["s", -3.0, "U01", {}]],
	},
	"U06":
	{
		"dir": "u06_directors_quarters",
		"size": [9.0, 7.0, 3.4],
		"cams": 3,
		"access": RoomData.Access.SCRIPTED,
		"floor": RoomData.Floor.UPPER,
		"map": [0, 40, 100, 100],
		"memory": true,
		"doors":
		[
			["e", 1.0, "U02", {}],
			["n", 3.0, "B03", {"flag": "u06.dumbwaiter_open", "locked": "rooms.u06.dumbwaiter.locked"}],
		],
	},
	"B02":
	{
		"dir": "b02_basement_corridor",
		"size": [4.0, 18.0, 3.0],
		"cams": 3,
		"access": RoomData.Access.OPEN,
		"floor": RoomData.Floor.BASEMENT,
		"map": [290, 40, 30, 220],
		"unlit": true,
		"doors":
		[
			["s", 0.0, "B01", {}],
			["e", -6.0, "B03", {}],
			["e", 0.0, "B04", {"key": "item_sanguine_key", "locked": "rooms.b02.treatment.locked"}],
			["e", 6.0, "B05", {}],
			["n", 0.0, "B07", {"flag": "b06.file_sealed", "locked": "rooms.b02.ward_zero.locked"}],
		],
	},
	"B03":
	{
		"dir": "b03_morgue",
		"size": [8.0, 6.0, 3.0],
		"cams": 2,
		"access": RoomData.Access.SCRIPTED,
		"floor": RoomData.Floor.BASEMENT,
		"map": [320, 40, 100, 70],
		"memory": true,
		"unlit": true,
		"doors": [["w", 0.0, "B02", {}]],
	},
	"B04":
	{
		"dir": "b04_treatment_room",
		"size": [8.0, 6.0, 3.0],
		"cams": 2,
		"access": RoomData.Access.SCRIPTED,
		"floor": RoomData.Floor.BASEMENT,
		"map": [320, 120, 100, 70],
		"memory": true,
		"doors": [["w", 0.0, "B02", {}]],
	},
	"B05":
	{
		"dir": "b05_archive_antechamber",
		"size": [6.0, 5.0, 3.0],
		"cams": 1,
		"access": RoomData.Access.NEVER,
		"floor": RoomData.Floor.BASEMENT,
		"map": [320, 200, 70, 60],
		"safe": true,
		"doors":
		[
			["w", 0.0, "B02", {}],
			["e", 0.0, "B06", {"flag": "b04.vault_open", "locked": "rooms.b05.vault.locked"}],
		],
	},
	"B06":
	{
		"dir": "b06_archive_vault",
		"size": [6.0, 6.0, 3.0],
		"cams": 1,
		"access": RoomData.Access.NEVER,
		"floor": RoomData.Floor.BASEMENT,
		"map": [390, 200, 60, 60],
		"doors": [["w", 0.0, "B05", {}]],
	},
	"B07":
	{
		"dir": "b07_ward_zero",
		"size": [6.0, 16.0, 3.4],
		"cams": 3,
		"access": RoomData.Access.OPEN,
		"floor": RoomData.Floor.BASEMENT,
		# Not on any floor plan (GDD §6.1).
		"map": [0, 0, 0, 0],
		"unlit": true,
		"doors": [["s", 0.0, "B02", {}]],
	},
}


func run(_tree: SceneTree, args: PackedStringArray) -> int:
	only = args
	var failures := 0
	for id in ROOMS34:
		if not only.is_empty() and not only.has(id):
			continue
		var err := _build(id, ROOMS34[id])
		print("build_act34: %s %s" % [id, error_string(err)])
		if err != OK:
			failures += 1
	return 1 if failures else 0


# --- Upper Floor -------------------------------------------------------------------


func _content_u01(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_bench", Vector3(1.6, 0.5, 0.5), Vector3(-1.5, 0.25, 2.1), WOOD)
	g.box(g.geometry, "occ_cabinet", Vector3(0.8, 2.0, 0.5), Vector3(2.0, 1.0, 2.25), METAL)
	g.hiding_spot(
		"hs_cabinet",
		Vector3(2.0, 1.0, 2.2),
		Vector3(0.9, 2.0, 0.6),
		Vector3(2.0, 0, 1.4),
		Vector3(2.0, 0, 2.25)
	)
	g.box(g.geometry, "art_portrait", Vector3(1.0, 1.2, 0.03), Vector3(-6.98, 1.8, 0.0), Color(0.4, 0.3, 0.2))
	g.hotspot(
		"hs_portrait",
		KIND.EXAMINE,
		Vector3(-6.9, 1.8, 0.0),
		Vector3(0.3, 1.3, 1.1),
		Vector3(-6.2, 0, 0.0),
		[GB.text("rooms.u01.portrait")]
	)
	_cassette(g, Vector3(-1.5, 0.6, 2.1), Vector3(-1.5, 0, 1.3))


func _triggers_u01() -> Array:
	return [GB.on_enter([], [GB.script("act3_start")], "act3.started")]


func _content_u02(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_shelves_n", Vector3(8.0, 2.6, 0.5), Vector3(0.0, 1.3, -3.75), WOOD)
	g.box(g.geometry, "occ_shelf_d", Vector3(0.5, 2.6, 2.0), Vector3(-4.75, 1.3, -1.6), WOOD)
	g.box(g.geometry, "occ_reading_desk", Vector3(2.0, 0.8, 1.0), Vector3(2.0, 0.4, 0.6), WOOD)
	g.box(g.geometry, "occ_cart", Vector3(1.0, 0.9, 0.6), Vector3(-3.4, 0.45, 2.4), METAL)
	g.hotspot(
		"hs_cart",
		KIND.USE,
		Vector3(-3.4, 0.6, 2.4),
		Vector3(1.1, 1.2, 0.7),
		Vector3(-2.6, 0, 2.4),
		[GB.puzzle_or_text("P14", "rooms.u02.cart.solved")]
	)
	g.box(g.geometry, "art_curtain", Vector3(1.6, 2.4, 0.1), Vector3(3.6, 1.2, 3.9), Color(0.35, 0.15, 0.15))
	g.hiding_spot(
		"hs_curtain",
		Vector3(3.6, 1.0, 3.6),
		Vector3(1.6, 2.0, 0.7),
		Vector3(3.6, 0, 2.8),
		Vector3(3.6, 0, 3.7)
	)


func _content_u03(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_armchair", Vector3(1.0, 0.9, 1.0), Vector3(-1.8, 0.45, -1.6), Color(0.4, 0.3, 0.3))
	g.box(g.geometry, "occ_table", Vector3(1.6, 0.75, 0.7), Vector3(1.2, 0.375, -1.9), WOOD)
	g.box(g.geometry, "occ_bin", Vector3(0.6, 0.6, 1.0), Vector3(-2.6, 0.3, 1.5), Color(0.3, 0.34, 0.3))
	g.hotspot(
		"hs_recorder",
		KIND.USE,
		Vector3(1.6, 0.85, -1.9),
		Vector3(0.5, 0.3, 0.5),
		Vector3(1.6, 0, -1.1),
		[GB.ui("save_screen")]
	)
	g.hotspot(
		"hs_bin",
		KIND.USE,
		Vector3(-2.6, 0.4, 1.5),
		Vector3(0.7, 0.8, 1.1),
		Vector3(-1.8, 0, 1.5),
		[GB.ui("effects_bin")]
	)
	g.hotspot(
		"hs_dictation",
		KIND.USE,
		Vector3(0.8, 0.85, -1.9),
		Vector3(0.5, 0.3, 0.5),
		Vector3(0.8, 0, -1.1),
		[GB.tape("tape_04_director")]
	)
	g.hotspot(
		"hs_reading_list",
		KIND.EXAMINE,
		Vector3(-1.8, 1.0, -1.6),
		Vector3(0.6, 0.3, 0.6),
		Vector3(-1.0, 0, -1.0),
		[GB.doc("doc_reading_list")]
	)
	_cassette(g, Vector3(2.4, 0.2, 1.8), Vector3(1.6, 0, 1.8))


func _content_u04(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_counter", Vector3(4.0, 1.0, 0.7), Vector3(0.0, 0.5, 1.5), WOOD)
	g.box(g.geometry, "occ_shelves", Vector3(0.5, 2.2, 3.0), Vector3(-3.25, 1.1, 0.5), WOOD)
	g.hotspot(
		"hs_scale",
		KIND.USE,
		Vector3(-0.8, 1.15, 1.5),
		Vector3(0.8, 0.4, 0.6),
		Vector3(-0.8, 0, 0.7),
		[GB.puzzle_or_text("P15", "rooms.u04.scale.solved")]
	)
	g.hotspot(
		"hs_prescription",
		KIND.EXAMINE,
		Vector3(1.2, 1.05, 1.5),
		Vector3(0.5, 0.2, 0.5),
		Vector3(1.2, 0, 0.7),
		[GB.doc("doc_prescription")]
	)


func _content_u05(g: GB, _w: float, _d: float, _h: float) -> void:
	for k in 3:
		g.box(
			g.geometry,
			"occ_tier_%d" % k,
			Vector3(5.0, 0.4 * (k + 1), 1.0),
			Vector3(1.5, 0.2 * (k + 1), 1.0 + k * 1.0),
			WOOD
		)
	g.box(g.geometry, "art_screen", Vector3(3.0, 2.0, 0.03), Vector3(0.0, 2.0, -3.98), Color(0.92, 0.92, 0.9))
	g.box(g.geometry, "occ_projector", Vector3(0.6, 1.0, 0.6), Vector3(3.5, 0.5, -0.5), METAL)
	g.box(g.geometry, "occ_lectern", Vector3(0.6, 1.1, 0.5), Vector3(-2.5, 0.55, -2.8), WOOD)
	g.hotspot(
		"hs_projector",
		KIND.USE,
		Vector3(3.5, 0.8, -0.5),
		Vector3(0.7, 1.2, 0.7),
		Vector3(3.5, 0, -1.3),
		[
			GB.when(
				[GB.has("item_projector_key")],
				[GB.puzzle_or_text("P16", "rooms.u05.projector.solved")],
				[GB.text("rooms.u05.projector.locked")]
			)
		]
	)
	g.hotspot(
		"hs_lecture_notes",
		KIND.EXAMINE,
		Vector3(-2.5, 1.15, -2.8),
		Vector3(0.6, 0.3, 0.6),
		Vector3(-2.5, 0, -2.0),
		[GB.doc("doc_lecture_notes")]
	)
	g.hotspot(
		"hs_screen",
		KIND.EXAMINE,
		Vector3(0.0, 2.0, -3.9),
		Vector3(3.0, 2.0, 0.3),
		Vector3(0.0, 0, -3.0),
		[
			GB.when(
				[GB.flag("u05.slides_aligned")],
				[GB.doc("doc_slide_overlay")],
				[GB.text("rooms.u05.screen.blank")]
			)
		]
	)
	g.box(g.geometry, "art_curtain", Vector3(0.1, 2.6, 1.6), Vector3(-4.9, 1.3, 0.5), Color(0.35, 0.15, 0.15))
	g.hiding_spot(
		"hs_curtain",
		Vector3(-4.6, 1.0, 0.5),
		Vector3(0.7, 2.0, 1.6),
		Vector3(-3.8, 0, 0.5),
		Vector3(-4.7, 0, 0.5)
	)
	_cassette(g, Vector3(3.0, 0.5, 1.0), Vector3(3.0, 0, 0.2))


func _content_u06(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_desk", Vector3(2.0, 0.8, 1.0), Vector3(-1.5, 0.4, -2.2), WOOD)
	g.box(g.geometry, "occ_armchair", Vector3(1.0, 0.9, 1.0), Vector3(-3.3, 0.45, 2.2), Color(0.45, 0.2, 0.2))
	g.box(g.geometry, "occ_clock", Vector3(0.6, 2.2, 0.4), Vector3(4.2, 1.1, -2.0), WOOD)
	g.box(g.geometry, "art_safe", Vector3(0.8, 0.8, 0.05), Vector3(0.6, 1.4, -3.47), METAL)
	g.hotspot(
		"hs_safe",
		KIND.USE,
		Vector3(0.6, 1.4, -3.35),
		Vector3(0.9, 0.9, 0.3),
		Vector3(0.6, 0, -2.6),
		[GB.puzzle_or_text("P17", "rooms.u06.safe.solved")],
		[GB.in_memory(false)]
	)
	g.hotspot(
		"hs_clock",
		KIND.USE,
		Vector3(4.2, 1.1, -1.75),
		Vector3(0.7, 2.2, 0.3),
		Vector3(3.4, 0, -1.6),
		[GB.puzzle_or_text("P18", "rooms.u06.clock.solved")],
		[GB.in_memory(false)]
	)
	g.hotspot(
		"hs_clock_note",
		KIND.EXAMINE,
		Vector3(-1.0, 0.85, -2.2),
		Vector3(0.5, 0.2, 0.5),
		Vector3(-1.0, 0, -1.4),
		[GB.doc("doc_clock_note")],
		[GB.in_memory(false)]
	)
	g.hotspot(
		"hs_session_1976",
		KIND.EXAMINE,
		Vector3(-1.5, 1.0, -2.2),
		Vector3(2.0, 1.0, 1.0),
		Vector3(-1.5, 0, -1.4),
		[GB.text("rooms.u06.session_1976")],
		[GB.in_memory()]
	)
	_resonant(
		g,
		"hs_armchair",
		Vector3(-3.3, 0.6, 2.2),
		Vector3(1.1, 1.0, 1.1),
		Vector3(-2.4, 0, 2.2),
		"item_photograph",
		"rooms.u06.resonant"
	)


# --- Basement ----------------------------------------------------------------------


func _content_b02(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_locker", Vector3(0.5, 2.0, 0.8), Vector3(-1.75, 1.0, 3.0), METAL)
	g.hiding_spot(
		"hs_locker",
		Vector3(-1.7, 1.0, 3.0),
		Vector3(0.6, 2.0, 0.9),
		Vector3(-0.9, 0, 3.0),
		Vector3(-1.75, 0, 3.0)
	)
	g.box(g.geometry, "occ_gurney", Vector3(0.7, 0.9, 2.0), Vector3(-1.4, 0.45, -3.0), METAL)
	_cassette(g, Vector3(-1.4, 1.0, -3.0), Vector3(-0.6, 0, -3.0))


func _triggers_b02() -> Array:
	return [GB.on_enter([], [GB.script("act4_start")], "act4.started")]


func _content_b03(g: GB, _w: float, _d: float, _h: float) -> void:
	# The dumbwaiter from the Director's Quarters drops here (one way).
	g.spawn("spawn_from_u06", Vector3(2.8, 0, -2.0), 180.0)
	g.box(g.geometry, "art_dumbwaiter", Vector3(0.8, 0.8, 0.05), Vector3(2.8, 1.2, -2.97), METAL)
	g.box(g.geometry, "occ_drawers", Vector3(0.6, 2.2, 4.0), Vector3(3.7, 1.1, 0.8), METAL)
	g.box(g.geometry, "occ_slab", Vector3(1.0, 0.9, 2.0), Vector3(-1.0, 0.45, -0.6), STONE)
	g.box(g.geometry, "occ_desk", Vector3(1.2, 0.8, 0.6), Vector3(-2.6, 0.4, 2.4), WOOD)
	g.hotspot(
		"hs_drawers",
		KIND.USE,
		Vector3(3.35, 1.1, 0.8),
		Vector3(0.3, 2.2, 4.0),
		Vector3(2.6, 0, 0.8),
		[GB.puzzle_or_text("P19", "rooms.b03.drawers.solved")],
		[GB.in_memory(false)]
	)
	g.hotspot(
		"hs_drawers_1976",
		KIND.EXAMINE,
		Vector3(3.35, 1.1, 0.8),
		Vector3(0.3, 2.2, 4.0),
		Vector3(2.6, 0, 0.8),
		[GB.text("rooms.b03.drawers_1976")],
		[GB.in_memory()]
	)
	g.hotspot(
		"hs_registry",
		KIND.EXAMINE,
		Vector3(-2.6, 0.85, 2.4),
		Vector3(0.6, 0.2, 0.5),
		Vector3(-2.6, 0, 1.6),
		[GB.doc("doc_death_registry")]
	)
	_resonant(
		g,
		"hs_slab",
		Vector3(-1.0, 0.6, -0.6),
		Vector3(1.1, 1.0, 2.1),
		Vector3(-1.0, 0, 0.8),
		"item_ribbon",
		"rooms.b03.resonant"
	)


func _triggers_b03() -> Array:
	return [GB.on_enter([], [GB.script("act4_start")], "act4.started")]


func _content_b04(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_chair", Vector3(1.0, 1.2, 1.6), Vector3(0.0, 0.6, -0.6), Color(0.55, 0.5, 0.45))
	g.box(g.geometry, "art_mural", Vector3(4.0, 1.6, 0.03), Vector3(0.0, 1.8, -2.98), Color(0.6, 0.55, 0.4))
	g.box(g.geometry, "art_panel", Vector3(0.05, 0.8, 1.6), Vector3(3.97, 1.3, 1.0), METAL)
	g.box(g.geometry, "occ_cabinet", Vector3(0.9, 2.0, 0.5), Vector3(-3.0, 1.0, 2.75), METAL)
	g.hiding_spot(
		"hs_cabinet",
		Vector3(-3.0, 1.0, 2.7),
		Vector3(1.0, 2.0, 0.6),
		Vector3(-3.0, 0, 1.9),
		Vector3(-3.0, 0, 2.75)
	)
	g.hotspot(
		"hs_panel",
		KIND.USE,
		Vector3(3.85, 1.3, 1.0),
		Vector3(0.3, 0.9, 1.7),
		Vector3(3.1, 0, 1.0),
		[GB.puzzle_or_text("P20", "rooms.b04.panel.solved")],
		[GB.in_memory(false)]
	)
	g.hotspot(
		"hs_mural",
		KIND.EXAMINE,
		Vector3(0.0, 1.8, -2.85),
		Vector3(4.0, 1.6, 0.3),
		Vector3(1.5, 0, -2.1),
		[GB.doc("doc_mural_damaged")],
		[GB.in_memory(false)]
	)
	g.hotspot(
		"hs_mural_1976",
		KIND.EXAMINE,
		Vector3(0.0, 1.8, -2.85),
		Vector3(4.0, 1.6, 0.3),
		Vector3(1.5, 0, -2.1),
		[GB.doc("doc_humors_mural")],
		[GB.in_memory()]
	)
	_resonant(
		g,
		"hs_chair",
		Vector3(0.0, 0.7, -0.6),
		Vector3(1.1, 1.3, 1.7),
		Vector3(0.0, 0, 0.9),
		"item_crayon_drawing",
		"rooms.b04.resonant"
	)


func _content_b05(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_table", Vector3(1.6, 0.75, 0.7), Vector3(0.0, 0.375, -1.9), WOOD)
	g.box(g.geometry, "occ_bin", Vector3(0.6, 0.6, 1.0), Vector3(-2.6, 0.3, 1.5), Color(0.3, 0.34, 0.3))
	g.hotspot(
		"hs_recorder",
		KIND.USE,
		Vector3(0.4, 0.85, -1.9),
		Vector3(0.5, 0.3, 0.5),
		Vector3(0.4, 0, -1.1),
		[GB.ui("save_screen")]
	)
	g.hotspot(
		"hs_bin",
		KIND.USE,
		Vector3(-2.6, 0.4, 1.5),
		Vector3(0.7, 0.8, 1.1),
		Vector3(-1.8, 0, 1.5),
		[GB.ui("effects_bin")]
	)
	g.hotspot(
		"hs_rules",
		KIND.EXAMINE,
		Vector3(-0.4, 0.85, -1.9),
		Vector3(0.5, 0.3, 0.5),
		Vector3(-0.4, 0, -1.1),
		[GB.doc("doc_vault_rules")]
	)
	_cassette(g, Vector3(2.2, 0.2, 1.6), Vector3(1.4, 0, 1.6))


func _content_b06(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_cabinets", Vector3(5.0, 2.2, 0.5), Vector3(0.0, 1.1, -2.75), METAL)
	g.box(g.geometry, "occ_file_table", Vector3(1.6, 0.8, 1.0), Vector3(0.6, 0.4, 0.4), WOOD)
	g.hotspot(
		"hs_file",
		KIND.USE,
		Vector3(0.6, 0.9, 0.4),
		Vector3(1.7, 0.4, 1.1),
		Vector3(-0.6, 0, 0.4),
		[GB.puzzle_or_text("P21", "rooms.b06.file.sealed")]
	)


func _content_b07(g: GB, _w: float, d: float, _h: float) -> void:
	g.spawn("spawn_stalker", Vector3(2.0, 0, d / 2 - 0.8), 0.0)
	for z in [-4.0, 0.0, 4.0]:
		g.box(g.geometry, "occ_bed_%d" % int(z), Vector3(1.0, 0.6, 2.0), Vector3(-2.2, 0.3, z), STONE)
	g.box(g.geometry, "art_exit_door", Vector3(1.4, 2.2, 0.05), Vector3(0.0, 1.1, -d / 2 + 0.03), WOOD)
	g.hotspot(
		"hs_exit",
		KIND.USE,
		Vector3(0.0, 1.1, -d / 2 + 0.2),
		Vector3(1.4, 2.2, 0.4),
		Vector3(0.0, 0, -d / 2 + 0.8),
		[GB.script("finale_exit")]
	)


func _triggers_b07() -> Array:
	return [GB.on_enter([], [GB.script("finale_start")])]
