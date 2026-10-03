extends RefCounted
## Greybox builder for every Act 2 room (docs/04-milestone-3.md §1):
## G07-G09, E01-E05, W01-W06, B01. One table-driven script instead of one per room.
## build_act34.gd reuses it for the Upper Floor and the Basement.
##   godot --headless res://tools/run_tool.tscn -- res://tools/greybox/build_act2.gd [ROOM_ID...]

const GB := preload("res://tools/greybox/greybox_lib.gd")
const DOOR_W := 1.4
const WALL := Color(0.6, 0.6, 0.57)
const WOOD := Color(0.45, 0.33, 0.24)
const METAL := Color(0.42, 0.45, 0.46)
const KIND := Interactable.Kind

## Room table. doors: [wall, offset along the wall, target room, extra ExitDef settings].
const ROOMS := {
	"G09":
	{
		"dir": "g09_main_corridor",
		"size": [16.0, 4.0, 3.2],
		"cams": 3,
		"access": RoomData.Access.OPEN,
		"floor": RoomData.Floor.GROUND,
		"map": [300, 40, 240, 30],
		"doors":
		[
			["s", -6.0, "G02", {}],
			["w", 0.0, "W01", {"key": "item_melancholic_key", "locked": "rooms.g09.west.locked"}],
			["e", 0.0, "E01", {}],
			["n", -2.0, "G07", {}],
			["n", 4.5, "B01", {"key": "item_phlegmatic_key", "locked": "rooms.g09.stairs.locked"}],
			["n", 7.0, "U01", {"flag": "b01.power_on", "locked": "rooms.g09.elevator.dead"}],
		],
	},
	"G07":
	{
		"dir": "g07_dining_hall",
		"size": [12.0, 10.0, 3.6],
		"cams": 3,
		"access": RoomData.Access.OPEN,
		"floor": RoomData.Floor.GROUND,
		"map": [330, -60, 120, 100],
		"doors": [["s", 0.0, "G09", {}], ["e", 2.0, "G08", {}]],
	},
	"G08":
	{
		"dir": "g08_kitchen",
		"size": [8.0, 6.0, 3.0],
		"cams": 2,
		"access": RoomData.Access.OPEN,
		"floor": RoomData.Floor.GROUND,
		"map": [450, -40, 80, 60],
		"doors":
		[
			["w", 2.0, "G07", {}],
			["n", 2.5, "B01", {"flag": "b01.shortcut_open", "locked": "rooms.g08.shortcut.locked"}],
		],
	},
	"E01":
	{
		"dir": "e01_east_corridor",
		"size": [4.0, 16.0, 3.2],
		"cams": 3,
		"access": RoomData.Access.OPEN,
		"floor": RoomData.Floor.EAST,
		"map": [200, 40, 30, 200],
		"doors":
		[
			["s", 0.0, "G09", {}],
			["w", -5.0, "E02", {}],
			["e", -5.0, "E03", {}],
			["w", 1.0, "E04", {"key": "item_linen_key", "locked": "rooms.e01.linen.locked"}],
			["e", 1.0, "E05", {}],
		],
	},
	"E02":
	{
		"dir": "e02_nurse_station",
		"size": [7.0, 5.0, 3.0],
		"cams": 2,
		"access": RoomData.Access.SCRIPTED,
		"floor": RoomData.Floor.EAST,
		"map": [100, 40, 100, 60],
		"doors": [["e", 0.0, "E01", {}]],
	},
	"E03":
	{
		"dir": "e03_hydrotherapy",
		"size": [8.0, 6.0, 3.0],
		"cams": 2,
		"access": RoomData.Access.SCRIPTED,
		"floor": RoomData.Floor.EAST,
		"map": [230, 40, 100, 70],
		"doors": [["w", 0.0, "E01", {}]],
	},
	"E04":
	{
		"dir": "e04_linen_room",
		"size": [7.0, 6.0, 3.0],
		"cams": 2,
		"access": RoomData.Access.OPEN,
		"floor": RoomData.Floor.EAST,
		"map": [100, 140, 90, 70],
		"doors": [["e", 0.0, "E01", {}]],
	},
	"E05":
	{
		"dir": "e05_womens_ward",
		"size": [10.0, 7.0, 3.2],
		"cams": 2,
		"access": RoomData.Access.OPEN,
		"floor": RoomData.Floor.EAST,
		"map": [230, 140, 120, 80],
		"doors": [["w", 0.0, "E01", {}]],
	},
	"W01":
	{
		"dir": "w01_west_corridor",
		"size": [4.0, 18.0, 3.2],
		"cams": 3,
		"access": RoomData.Access.OPEN,
		"floor": RoomData.Floor.WEST,
		"map": [200, 20, 30, 220],
		"doors":
		[
			["s", 0.0, "G09", {}],
			["e", -6.0, "W02", {}],
			["e", -1.0, "W03", {}],
			["w", -6.0, "W04", {}],
			["w", -1.0, "W05", {}],
			["w", 5.0, "W06", {}],
		],
	},
	"W02":
	{
		"dir": "w02_dormitory",
		"size": [9.0, 6.0, 3.0],
		"cams": 2,
		"access": RoomData.Access.SCRIPTED,
		"floor": RoomData.Floor.WEST,
		"map": [230, 20, 110, 70],
		"memory": true,
		"doors": [["w", 0.0, "W01", {}]],
	},
	"W03":
	{
		"dir": "w03_classroom",
		"size": [9.0, 7.0, 3.2],
		"cams": 2,
		"access": RoomData.Access.SCRIPTED,
		"floor": RoomData.Floor.WEST,
		"map": [230, 110, 110, 80],
		"memory": true,
		"doors": [["w", 0.0, "W01", {}]],
	},
	"W04":
	{
		"dir": "w04_playroom",
		"size": [8.0, 6.0, 3.0],
		"cams": 2,
		"access": RoomData.Access.SCRIPTED,
		"floor": RoomData.Floor.WEST,
		"map": [100, 20, 100, 70],
		"memory": true,
		"doors": [["e", 0.0, "W01", {}]],
	},
	"W05":
	{
		"dir": "w05_isolation_cells",
		"size": [10.0, 5.0, 3.0],
		"cams": 3,
		"access": RoomData.Access.OPEN,
		"floor": RoomData.Floor.WEST,
		"map": [80, 110, 120, 60],
		"unlit": true,
		"doors": [["e", 0.0, "W01", {}]],
	},
	"W06":
	{
		"dir": "w06_staff_lounge",
		"size": [6.0, 5.0, 3.0],
		"cams": 1,
		"access": RoomData.Access.NEVER,
		"floor": RoomData.Floor.WEST,
		"map": [110, 190, 90, 60],
		"safe": true,
		"doors": [["e", 0.0, "W01", {}]],
	},
	"B01":
	{
		"dir": "b01_boiler_room",
		"size": [10.0, 8.0, 3.4],
		"cams": 2,
		"access": RoomData.Access.SCRIPTED,
		"floor": RoomData.Floor.BASEMENT,
		"map": [150, 80, 140, 110],
		"unlit": true,
		"doors":
		[
			["s", -3.0, "G09", {}],
			["e", 2.0, "G08", {"flag": "b01.shortcut_open", "locked": "rooms.b01.shortcut.locked"}],
			["w", 3.0, "B02", {"flag": "act4.started", "locked": "rooms.b01.basement.locked"}],
		],
	},
}

var only: PackedStringArray = []


func run(_tree: SceneTree, args: PackedStringArray) -> int:
	only = args
	var failures := 0
	for id in ROOMS:
		if not only.is_empty() and not only.has(id):
			continue
		var err := _build(id, ROOMS[id])
		print("build_act2: %s %s" % [id, error_string(err)])
		if err != OK:
			failures += 1
	return 1 if failures else 0


func _build(id: String, spec: Dictionary) -> Error:
	var g := GB.new(id)
	var w: float = spec["size"][0]
	var d: float = spec["size"][1]
	var h: float = spec["size"][2]
	var gaps := []
	for door in spec["doors"]:
		gaps.append({"wall": door[0], "at": door[1], "width": DOOR_W})
	g.shell(w, d, h, WALL, gaps)
	var exits := []
	var i := 0
	for door in spec["doors"]:
		var wall: String = door[0]
		var at: float = door[1]
		var target: String = door[2]
		var extra: Dictionary = door[3]
		var exit_id := "to_%s" % target.to_lower()
		var spawn_pos := _inside(wall, at, w, d)
		g.door("col_door_%d" % i, wall, at, DOOR_W, w, d)
		g.spawn("spawn_from_%s" % target.to_lower(), spawn_pos, _yaw(wall))
		var size := Vector3(DOOR_W, 2.2, 0.4) if wall in ["n", "s"] else Vector3(0.4, 2.2, DOOR_W)
		g.hotspot_exit("hs_%s" % exit_id, _door_center(wall, at, w, d), size, spawn_pos, StringName(exit_id))
		var e := g.exit_def(
			exit_id, target, "spawn_from_%s" % id.to_lower(), extra.get("flag", ""), extra.get("locked", "")
		)
		e.required_key = StringName(extra.get("key", ""))
		exits.append(e)
		i += 1
	var cam_ids := _cameras(g, w, d, h, int(spec["cams"]))
	var sun := Vector3(-50, 35, 0)
	g.render_sun(sun, 0.6 if spec.get("unlit", false) else 1.0)
	g.render_omni(Vector3(0, h - 0.3, 0), 0.6 if spec.get("unlit", false) else 1.2, maxf(w, d))
	if spec.get("memory", false):
		g.timeline_only(g.render_omni(Vector3(0, h - 0.5, 0), 1.6, maxf(w, d), Color(1.0, 0.78, 0.5)), true)
	g.light_rigs(sun)
	call("_content_" + id.to_lower(), g, w, d, h)
	var dir := "res://game/rooms/%s" % spec["dir"]
	var data := g.room_data(dir, cam_ids, exits)
	data.name_key = "rooms.%s.name" % id.to_lower()
	data.access = spec["access"]
	data.map_floor = spec["floor"]
	data.safe_room = spec.get("safe", false)
	data.unlit = spec.get("unlit", false)
	data.has_memory_variant = spec.get("memory", false)
	var m: Array = spec["map"]
	data.map_rect = Rect2(m[0], m[1], m[2], m[3])
	if has_method("_triggers_" + id.to_lower()):
		data.enter_triggers.assign(call("_triggers_" + id.to_lower()))
	return g.save(dir, spec["dir"], data)


# --- Room contents ---------------------------------------------------------------


func _content_g09(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_bench", Vector3(1.5, 0.5, 0.5), Vector3(1.0, 0.25, 1.6), WOOD)
	g.box(g.geometry, "occ_locker", Vector3(0.8, 2.0, 0.5), Vector3(-0.5, 1.0, -1.75), METAL)
	g.hiding_spot(
		"hs_locker",
		Vector3(-0.5, 1.0, -1.7),
		Vector3(0.9, 2.0, 0.6),
		Vector3(-0.5, 0, -0.9),
		Vector3(-0.5, 0, -1.75)
	)


func _triggers_g09() -> Array:
	return [GB.on_enter([], [GB.script("act2_start")], "act2.started")]


func _content_g07(g: GB, _w: float, _d: float, _h: float) -> void:
	for p in [Vector3(-3, 0.4, -2), Vector3(3, 0.4, -2), Vector3(-3, 0.4, 2.4), Vector3(3, 0.4, 2.4)]:
		g.box(g.geometry, "occ_table_%d_%d" % [int(p.x), int(p.z)], Vector3(3.0, 0.8, 1.2), p, WOOD)
	g.box(g.geometry, "art_curtain", Vector3(0.1, 2.4, 1.6), Vector3(-5.9, 1.2, 0.0), Color(0.45, 0.2, 0.18))
	g.hiding_spot(
		"hs_alcove",
		Vector3(-5.6, 1.0, 0.0),
		Vector3(0.8, 2.0, 1.6),
		Vector3(-4.8, 0, 0.0),
		Vector3(-5.7, 0, 0.0)
	)
	g.box(g.geometry, "art_menu", Vector3(0.6, 0.8, 0.02), Vector3(0, 1.6, -4.99), Color(0.9, 0.88, 0.8))
	g.hotspot(
		"hs_menu",
		KIND.EXAMINE,
		Vector3(0, 1.6, -4.9),
		Vector3(0.7, 0.9, 0.2),
		Vector3(0, 0, -4.2),
		[GB.doc("doc_dining_menu")]
	)
	_cassette(g, Vector3(3.0, 0.9, 2.4), Vector3(3.0, 0, 3.4))


func _content_g08(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_counter", Vector3(4.0, 0.9, 0.6), Vector3(-1.0, 0.45, -2.6), METAL)
	g.box(g.geometry, "occ_stove", Vector3(1.4, 0.9, 0.7), Vector3(2.0, 0.45, 2.55), METAL)
	g.box(g.geometry, "art_pantry_door", Vector3(0.05, 2.0, 1.0), Vector3(3.97, 1.0, -0.8), WOOD)
	g.hiding_spot(
		"hs_pantry",
		Vector3(3.7, 1.0, -0.8),
		Vector3(0.6, 2.0, 1.1),
		Vector3(2.9, 0, -0.8),
		Vector3(3.9, 0, -0.8)
	)


func _content_e01(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_locker", Vector3(0.5, 2.0, 0.8), Vector3(1.75, 1.0, 5.0), METAL)
	g.hiding_spot(
		"hs_locker",
		Vector3(1.7, 1.0, 5.0),
		Vector3(0.6, 2.0, 0.9),
		Vector3(0.9, 0, 5.0),
		Vector3(1.75, 0, 5.0)
	)
	g.box(g.geometry, "occ_gurney", Vector3(0.7, 0.9, 2.0), Vector3(-1.4, 0.45, -1.5), METAL)


func _content_e02(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_counter", Vector3(3.0, 1.0, 0.8), Vector3(-1.0, 0.5, -1.7), WOOD)
	g.box(g.geometry, "occ_cart", Vector3(1.0, 1.0, 0.6), Vector3(1.6, 0.5, -1.8), METAL)
	g.box(g.geometry, "occ_desk", Vector3(1.0, 0.8, 0.6), Vector3(-2.8, 0.4, 1.8), WOOD)
	g.hotspot(
		"hs_cart",
		KIND.USE,
		Vector3(1.6, 0.6, -1.8),
		Vector3(1.1, 1.2, 0.7),
		Vector3(1.6, 0, -1.0),
		[GB.puzzle_or_text("P06", "rooms.e02.cart.solved")]
	)
	g.hotspot(
		"hs_charts",
		KIND.EXAMINE,
		Vector3(-1.7, 1.05, -1.7),
		Vector3(0.6, 0.2, 0.6),
		Vector3(-1.7, 0, -0.9),
		[GB.doc("doc_med_charts")]
	)
	g.hotspot(
		"hs_shift_log",
		KIND.EXAMINE,
		Vector3(-0.4, 1.05, -1.7),
		Vector3(0.6, 0.2, 0.6),
		Vector3(-0.4, 0, -0.9),
		[GB.doc("doc_shift_log")]
	)
	var log_page := g.hotspot(
		"hs_nurse_log",
		KIND.TAKE,
		Vector3(-2.8, 0.85, 1.8),
		Vector3(0.6, 0.2, 0.5),
		Vector3(-2.8, 0, 1.0),
		[GB.doc("doc_f03_nurse_log")]
	)
	log_page.item_id = &"item_f03_nurse_log"


func _content_e03(g: GB, _w: float, _d: float, _h: float) -> void:
	for x in [-2.0, 0.2, 2.4]:
		g.box(
			g.geometry,
			"occ_tub_%d" % int(x * 10),
			Vector3(1.6, 0.8, 1.0),
			Vector3(x, 0.4, -2.3),
			Color(0.85, 0.85, 0.82)
		)
	g.box(g.geometry, "art_valves", Vector3(0.05, 1.0, 1.0), Vector3(3.97, 1.2, 1.0), METAL)
	g.hotspot(
		"hs_valves",
		KIND.USE,
		Vector3(3.85, 1.2, 1.0),
		Vector3(0.3, 1.0, 1.0),
		Vector3(3.1, 0, 1.0),
		[
			GB.when(
				[GB.has("item_valve_wheel")],
				[GB.puzzle_or_text("P07", "rooms.e03.valves.solved")],
				[GB.text("rooms.e03.valves.no_wheel")]
			)
		]
	)


func _content_e04(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_shelves", Vector3(4.0, 2.0, 0.5), Vector3(-1.0, 1.0, -2.75), WOOD)
	g.box(g.geometry, "occ_cart", Vector3(1.2, 1.0, 0.7), Vector3(1.8, 0.5, 1.6), Color(0.75, 0.75, 0.72))
	g.hiding_spot(
		"hs_cart", Vector3(1.8, 0.6, 1.6), Vector3(1.3, 1.2, 0.8), Vector3(1.8, 0, 0.7), Vector3(1.8, 0, 1.6)
	)
	g.box(g.geometry, "occ_desk", Vector3(1.4, 0.75, 0.6), Vector3(-2.5, 0.375, 1.85), WOOD)
	g.hotspot(
		"hs_shelves",
		KIND.USE,
		Vector3(-1.0, 1.0, -2.6),
		Vector3(4.1, 2.0, 0.6),
		Vector3(-1.0, 0, -1.9),
		[GB.puzzle_or_text("P08", "rooms.e04.shelves.solved")]
	)
	g.hotspot(
		"hs_ledger",
		KIND.EXAMINE,
		Vector3(-2.9, 0.8, 1.85),
		Vector3(0.5, 0.2, 0.5),
		Vector3(-2.9, 0, 1.05),
		[GB.doc("doc_laundry_ledger")]
	)
	g.hotspot(
		"hs_note",
		KIND.EXAMINE,
		Vector3(-2.1, 0.8, 1.85),
		Vector3(0.5, 0.2, 0.5),
		Vector3(-2.1, 0, 1.05),
		[GB.doc("doc_laundry_note")]
	)


func _content_e05(g: GB, _w: float, _d: float, _h: float) -> void:
	for x in [-2.5, -0.5, 1.5, 3.5]:
		g.box(
			g.geometry,
			"occ_bed_%d" % int(x * 10),
			Vector3(1.0, 0.6, 2.0),
			Vector3(x, 0.3, -2.3),
			Color(0.8, 0.8, 0.78)
		)
	g.hiding_spot(
		"hs_bed",
		Vector3(1.5, 0.3, -2.3),
		Vector3(1.1, 0.7, 2.1),
		Vector3(1.5, 0, -0.9),
		Vector3(1.5, 0, -2.3)
	)
	g.box(g.geometry, "occ_nightstand", Vector3(0.6, 0.7, 0.6), Vector3(4.4, 0.35, 1.6), WOOD)
	g.hotspot(
		"hs_lockbox",
		KIND.USE,
		Vector3(4.4, 0.8, 1.6),
		Vector3(0.6, 0.3, 0.6),
		Vector3(3.6, 0, 1.6),
		[GB.puzzle_or_text("P08L", "rooms.e05.lockbox.solved")]
	)
	_cassette(g, Vector3(-4.4, 0.2, 2.6), Vector3(-3.6, 0, 2.6))


func _content_w01(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_locker", Vector3(0.5, 2.0, 0.8), Vector3(1.75, 1.0, 5.0), METAL)
	g.hiding_spot(
		"hs_locker",
		Vector3(1.7, 1.0, 5.0),
		Vector3(0.6, 2.0, 0.9),
		Vector3(0.9, 0, 5.0),
		Vector3(1.75, 0, 5.0)
	)


func _content_w02(g: GB, _w: float, _d: float, _h: float) -> void:
	for x in [-1.0, 1.0, 3.0]:
		g.box(
			g.geometry,
			"occ_cot_%d" % int(x),
			Vector3(0.8, 0.5, 1.6),
			Vector3(x, 0.25, -2.1),
			Color(0.75, 0.75, 0.8)
		)
	g.box(
		g.geometry,
		"art_drawing_wall",
		Vector3(1.6, 1.0, 0.03),
		Vector3(-3.2, 1.6, -2.98),
		Color(0.9, 0.86, 0.75)
	)
	g.box(g.geometry, "occ_radiator", Vector3(0.3, 0.8, 1.2), Vector3(4.3, 0.4, 1.5), METAL)
	g.box(g.geometry, "occ_small_bed", Vector3(0.8, 0.5, 1.4), Vector3(-3.4, 0.25, 2.1), Color(0.8, 0.7, 0.7))
	var drawings_present := GB.in_memory(false)
	g.hotspot(
		"hs_drawings",
		KIND.USE,
		Vector3(-3.2, 1.6, -2.85),
		Vector3(1.6, 1.0, 0.3),
		Vector3(-3.2, 0, -2.1),
		[GB.puzzle_or_text("P09", "rooms.w02.drawings.solved")],
		[drawings_present]
	)
	g.hotspot(
		"hs_drawings_1976",
		KIND.EXAMINE,
		Vector3(-3.2, 1.6, -2.85),
		Vector3(1.6, 1.0, 0.3),
		Vector3(-3.2, 0, -2.1),
		[GB.text("rooms.w02.drawings_1976")],
		[GB.in_memory()]
	)
	g.hotspot(
		"hs_radiator_1976",
		KIND.USE,
		Vector3(4.3, 0.5, 1.5),
		Vector3(0.4, 1.0, 1.3),
		Vector3(3.5, 0, 1.5),
		[GB.set_flag("persist.w02_drawing"), GB.text("rooms.w02.radiator_hide")],
		[GB.in_memory(), GB.flag("persist.w02_drawing", false)]
	)
	g.hotspot(
		"hs_radiator_found",
		KIND.USE,
		Vector3(4.3, 0.5, 1.5),
		Vector3(0.4, 1.0, 1.3),
		Vector3(3.5, 0, 1.5),
		[GB.set_flag("p09.drawing_found"), GB.text("rooms.w02.radiator_found")],
		[GB.in_memory(false), GB.flag("persist.w02_drawing"), GB.flag("p09.drawing_found", false)]
	)
	g.hotspot(
		"hs_radiator",
		KIND.EXAMINE,
		Vector3(4.3, 0.5, 1.5),
		Vector3(0.4, 1.0, 1.3),
		Vector3(3.5, 0, 1.5),
		[GB.text("rooms.w02.radiator")],
		[GB.in_memory(false), GB.flag("persist.w02_drawing", false)]
	)
	_resonant(
		g,
		"hs_small_bed",
		Vector3(-3.4, 0.5, 2.1),
		Vector3(0.9, 0.7, 1.5),
		Vector3(-2.5, 0, 2.1),
		"item_photograph",
		"rooms.w02.resonant"
	)


func _content_w03(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(
		g.geometry,
		"art_chalkboard",
		Vector3(3.0, 1.2, 0.04),
		Vector3(0.0, 1.7, -3.47),
		Color(0.15, 0.22, 0.18)
	)
	for x in [-2.5, -0.5, 1.5]:
		for z in [0.0, 1.8]:
			g.box(
				g.geometry,
				"occ_desk_%d_%d" % [int(x * 10), int(z * 10)],
				Vector3(0.9, 0.7, 0.6),
				Vector3(x, 0.35, z),
				WOOD
			)
	g.box(g.geometry, "occ_teacher_desk", Vector3(1.6, 0.8, 0.8), Vector3(2.8, 0.4, -2.3), WOOD)
	g.box(g.geometry, "art_coat_hook", Vector3(0.3, 0.3, 0.05), Vector3(-4.47, 1.6, 2.6), METAL)
	g.hotspot(
		"hs_padlock",
		KIND.USE,
		Vector3(2.8, 0.85, -2.3),
		Vector3(1.0, 0.3, 0.8),
		Vector3(2.8, 0, -1.5),
		[GB.puzzle_or_text("P10", "rooms.w03.padlock.solved")]
	)
	g.hotspot(
		"hs_board",
		KIND.EXAMINE,
		Vector3(0.0, 1.7, -3.35),
		Vector3(3.0, 1.2, 0.3),
		Vector3(0.0, 0, -2.6),
		[GB.doc("doc_board_1998")],
		[GB.in_memory(false)]
	)
	g.hotspot(
		"hs_board_1976",
		KIND.EXAMINE,
		Vector3(0.0, 1.7, -3.35),
		Vector3(3.0, 1.2, 0.3),
		Vector3(0.0, 0, -2.6),
		[GB.doc("doc_board_1976")],
		[GB.in_memory()]
	)
	_resonant(
		g,
		"hs_coat_hook",
		Vector3(-4.3, 1.6, 2.6),
		Vector3(0.4, 0.5, 0.5),
		Vector3(-3.6, 0, 2.6),
		"item_ribbon",
		"rooms.w03.resonant"
	)


func _content_w04(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_table", Vector3(2.4, 0.7, 0.8), Vector3(-0.4, 0.35, -2.0), WOOD)
	g.box(
		g.geometry,
		"occ_rocking_horse",
		Vector3(0.5, 0.9, 1.1),
		Vector3(-2.8, 0.45, 1.6),
		Color(0.6, 0.45, 0.3)
	)
	g.hotspot(
		"hs_music_box",
		KIND.USE,
		Vector3(-1.0, 0.8, -2.0),
		Vector3(0.6, 0.3, 0.6),
		Vector3(-1.0, 0, -1.2),
		[
			GB.when(
				[GB.has("item_music_box_crank"), GB.has("item_cylinder")],
				[GB.puzzle_or_text("P11", "rooms.w04.music_box.solved")],
				[GB.text("rooms.w04.music_box.missing")]
			)
		]
	)
	g.hotspot(
		"hs_lid",
		KIND.EXAMINE,
		Vector3(0.2, 0.8, -2.0),
		Vector3(0.6, 0.3, 0.6),
		Vector3(0.2, 0, -1.2),
		[GB.doc("doc_lid_sheet")]
	)
	_resonant(
		g,
		"hs_rocking_horse",
		Vector3(-2.8, 0.6, 1.6),
		Vector3(0.6, 1.0, 1.2),
		Vector3(-2.0, 0, 1.6),
		"item_cylinder",
		"rooms.w04.resonant"
	)
	g.hotspot(
		"hs_toy_1976",
		KIND.EXAMINE,
		Vector3(1.8, 0.4, 1.6),
		Vector3(0.6, 0.6, 0.6),
		Vector3(1.8, 0, 0.9),
		[GB.text("rooms.w04.toy_1976")],
		[GB.in_memory()]
	)
	_cassette(g, Vector3(3.2, 0.2, -2.4), Vector3(3.2, 0, -1.6))


func _content_w05(g: GB, _w: float, _d: float, _h: float) -> void:
	for x in [-4.0, -2.0, 0.0, 2.0, 4.0]:
		g.box(g.geometry, "art_cell_door_%d" % int(x), Vector3(1.0, 2.0, 0.06), Vector3(x, 1.0, -2.47), METAL)
	g.hotspot(
		"hs_cells",
		KIND.USE,
		Vector3(0.0, 1.1, -2.35),
		Vector3(9.0, 2.2, 0.3),
		Vector3(0.0, 0, -1.6),
		[GB.puzzle_or_text("P12", "rooms.w05.cells.solved")]
	)
	g.box(g.geometry, "art_open_cell", Vector3(1.0, 2.0, 0.06), Vector3(-3.5, 1.0, 2.47), METAL)
	g.hiding_spot(
		"hs_open_cell",
		Vector3(-3.5, 1.0, 2.3),
		Vector3(1.1, 2.0, 0.4),
		Vector3(-3.5, 0, 1.5),
		Vector3(-3.5, 0, 2.4)
	)


func _content_w06(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_couch", Vector3(2.4, 0.8, 0.9), Vector3(-1.0, 0.4, -1.9), Color(0.35, 0.3, 0.4))
	g.box(g.geometry, "occ_table", Vector3(1.6, 0.75, 0.6), Vector3(1.6, 0.375, -1.95), WOOD)
	g.box(g.geometry, "occ_bin", Vector3(0.6, 0.6, 1.0), Vector3(-2.6, 0.3, 1.6), Color(0.3, 0.34, 0.3))
	g.hotspot(
		"hs_recorder",
		KIND.USE,
		Vector3(2.0, 0.85, -1.95),
		Vector3(0.5, 0.3, 0.5),
		Vector3(2.0, 0, -1.15),
		[GB.ui("save_screen")]
	)
	g.hotspot(
		"hs_bin",
		KIND.USE,
		Vector3(-2.6, 0.4, 1.6),
		Vector3(0.7, 0.8, 1.1),
		Vector3(-1.8, 0, 1.6),
		[GB.ui("effects_bin")]
	)
	g.hotspot(
		"hs_lullaby",
		KIND.USE,
		Vector3(1.2, 0.85, -1.95),
		Vector3(0.5, 0.3, 0.5),
		Vector3(1.2, 0, -1.15),
		[GB.tape("tape_03_lullaby")]
	)
	_cassette(g, Vector3(-1.0, 0.9, -1.9), Vector3(-1.0, 0, -1.1))


func _content_b01(g: GB, _w: float, _d: float, _h: float) -> void:
	g.box(g.geometry, "occ_boiler", Vector3(3.0, 2.4, 1.5), Vector3(0.0, 1.2, -3.0), METAL)
	g.box(g.geometry, "occ_pipes", Vector3(0.4, 3.0, 4.0), Vector3(-4.6, 1.5, -1.5), METAL)
	g.box(g.geometry, "art_manual", Vector3(0.04, 0.6, 0.4), Vector3(-4.38, 1.5, 1.4), Color(0.9, 0.88, 0.8))
	g.hotspot(
		"hs_boiler",
		KIND.USE,
		Vector3(0.0, 1.2, -2.1),
		Vector3(3.0, 2.0, 0.4),
		Vector3(0.0, 0, -1.4),
		[
			GB.when(
				[GB.has("item_fuse")],
				[GB.puzzle_or_text("P13", "rooms.b01.boiler.solved")],
				[GB.text("rooms.b01.boiler.no_fuse")]
			)
		]
	)
	g.hotspot(
		"hs_manual",
		KIND.EXAMINE,
		Vector3(-4.3, 1.5, 1.4),
		Vector3(0.3, 0.7, 0.5),
		Vector3(-3.6, 0, 1.4),
		[GB.doc("doc_boiler_manual")]
	)
	_cassette(g, Vector3(4.0, 0.2, -3.2), Vector3(3.2, 0, -3.2))


## Resonant spot (GDD §4.1): the anchor shifts the room to 1976; using it again (or any
## door) returns to the present.
func _resonant(
	g: GB,
	node_name: String,
	center: Vector3,
	size: Vector3,
	approach: Vector3,
	anchor: String,
	text_key: String
) -> void:
	var h := g.hotspot(
		node_name,
		KIND.USE,
		center,
		size,
		approach,
		[GB.when([GB.in_memory()], [MemoryShift.new()], [GB.text(text_key)])]
	)
	h.accepts_items = {StringName(anchor): [MemoryShift.new()]}
	h.reject_item_key = "rooms.g06.altar.wrong_item"


## Committed-only Blank Cassette pickup (GDD §8.1: about 12 in the whole game).
func _cassette(g: GB, center: Vector3, approach: Vector3) -> void:
	var rule := DifficultyIs.new()
	rule.threat = "committed"
	var h := g.hotspot("hs_blank_cassette", KIND.TAKE, center, Vector3(0.5, 0.4, 0.5), approach, [], [rule])
	h.item_id = &"item_blank_cassette"


# --- Layout helpers ----------------------------------------------------------------


## Fixed cameras: 1 = corner view; 2 or 3 = split along the longer axis, each camera at
## the far end of its own segment looking back across it.
func _cameras(g: GB, w: float, d: float, h: float, count: int) -> Array:
	var ids := []
	var y := h - 0.3
	if count == 1:
		g.camera("cam_a", Vector3(w / 2 - 0.4, y, d / 2 - 0.4), Vector3(-w / 4, 0.5, -d / 4), 60.0)
		g.trigger("cam_a", Vector3(0, 1.0, 0), Vector3(w, 2.0, d))
		return ["cam_a"]
	var along_x := w >= d
	var length := w if along_x else d
	var seg := length / count
	for k in count:
		var id := "cam_%s" % "abc"[k]
		var c0 := -length / 2 + k * seg
		var c1 := c0 + seg
		var center := (c0 + c1) / 2
		if along_x:
			var cam_x := minf(c1 + seg * 0.15, w / 2 - 0.3)
			g.camera(id, Vector3(cam_x, y, d / 2 - 0.3), Vector3(c0 + seg * 0.2, 0.4, -d / 4), 60.0)
			g.trigger(id, Vector3(center, 1.0, 0), Vector3(seg + 0.6, 2.0, d))
		else:
			var cam_z := minf(c1 + seg * 0.15, d / 2 - 0.3)
			g.camera(id, Vector3(w / 2 - 0.3, y, cam_z), Vector3(-w / 4, 0.4, c0 + seg * 0.2), 62.0)
			g.trigger(id, Vector3(0, 1.0, center), Vector3(w, 2.0, seg + 0.6))
		ids.append(id)
	return ids


static func _inside(wall: String, at: float, w: float, d: float) -> Vector3:
	match wall:
		"w":
			return Vector3(-w / 2 + 0.7, 0, at)
		"e":
			return Vector3(w / 2 - 0.7, 0, at)
		"n":
			return Vector3(at, 0, -d / 2 + 0.7)
	return Vector3(at, 0, d / 2 - 0.7)


static func _door_center(wall: String, at: float, w: float, d: float) -> Vector3:
	match wall:
		"w":
			return Vector3(-w / 2 + 0.1, 1.1, at)
		"e":
			return Vector3(w / 2 - 0.1, 1.1, at)
		"n":
			return Vector3(at, 1.1, -d / 2 + 0.1)
	return Vector3(at, 1.1, d / 2 - 0.1)


static func _yaw(wall: String) -> float:
	match wall:
		"w":
			return -90.0
		"e":
			return 90.0
		"n":
			return 180.0
	return 0.0
