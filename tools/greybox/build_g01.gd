extends RefCounted
## Builds the G01 Dayroom greybox: room scene, cameras, triggers, spawns, hotspots and
## RoomData. Run: godot --headless res://tools/run_tool.tscn -- res://tools/greybox/build_g01.gd
## Then render backgrounds with tools/greybox/render_room.gd (see tools/greybox/README.md).
## Re-running overwrites the scene; hand edits belong in the final (non-greybox) room.

const GB := preload("res://tools/greybox/greybox_lib.gd")
const DIR := "res://game/rooms/g01_dayroom"

const W := 9.0  # x extent
const D := 7.0  # z extent
const H := 3.2


func run(_tree: SceneTree, _args: PackedStringArray) -> int:
	var g := GB.new("G01")
	var geo := g.geometry

	# Shell
	g.box(geo, "floor_main", Vector3(W, 0.1, D), Vector3(0, -0.05, 0), Color(0.42, 0.44, 0.40))
	g.box(geo, "art_ceiling", Vector3(W, 0.1, D), Vector3(0, H + 0.05, 0), Color(0.75, 0.74, 0.70))
	g.box(geo, "col_wall_s", Vector3(W, H, 0.2), Vector3(0, H / 2, D / 2 + 0.1), Color(0.62, 0.64, 0.58))
	g.box(geo, "col_wall_w", Vector3(0.2, H, D), Vector3(-W / 2 - 0.1, H / 2, 0), Color(0.62, 0.64, 0.58))
	g.box(geo, "col_wall_e", Vector3(0.2, H, D), Vector3(W / 2 + 0.1, H / 2, 0), Color(0.62, 0.64, 0.58))
	# North wall with the door gap to the Lobby at x = 2.5
	g.box(
		geo, "col_wall_n_a", Vector3(6.4, H, 0.2), Vector3(-1.3, H / 2, -D / 2 - 0.1), Color(0.62, 0.64, 0.58)
	)
	g.box(
		geo, "col_wall_n_b", Vector3(1.4, H, 0.2), Vector3(3.8, H / 2, -D / 2 - 0.1), Color(0.62, 0.64, 0.58)
	)
	g.box(
		geo,
		"art_lintel",
		Vector3(1.2, H - 2.2, 0.2),
		Vector3(2.5, 2.2 + (H - 2.2) / 2, -D / 2 - 0.1),
		Color(0.62, 0.64, 0.58)
	)
	g.box(geo, "col_door", Vector3(1.2, 2.2, 0.08), Vector3(2.5, 1.1, -D / 2 - 0.02), Color(0.36, 0.26, 0.18))
	g.box(
		geo, "art_chain", Vector3(0.5, 0.06, 0.04), Vector3(2.3, 1.1, -D / 2 + 0.05), Color(0.55, 0.55, 0.58)
	)
	# Window strip on the south wall (render light comes through it)
	g.box(
		geo, "art_window", Vector3(2.4, 1.2, 0.02), Vector3(1.5, 1.9, D / 2 - 0.01), Color(0.85, 0.88, 0.92)
	)

	# Furniture: occluders the character can walk behind
	g.box(geo, "occ_pillar", Vector3(0.4, H, 0.4), Vector3(-1.3, H / 2, 0.5), Color(0.70, 0.70, 0.66))
	g.box(geo, "occ_couch", Vector3(2.2, 0.8, 0.9), Vector3(-2.6, 0.4, 2.3), Color(0.40, 0.28, 0.22))
	g.box(geo, "occ_table_radio", Vector3(0.7, 0.75, 1.2), Vector3(4.0, 0.375, -1.4), Color(0.45, 0.33, 0.24))
	g.box(geo, "art_radio", Vector3(0.25, 0.3, 0.45), Vector3(4.05, 0.9, -1.4), Color(0.25, 0.22, 0.2))
	g.box(
		geo,
		"occ_table_recorder",
		Vector3(0.9, 0.75, 0.6),
		Vector3(-3.7, 0.375, -2.8),
		Color(0.45, 0.33, 0.24)
	)
	g.box(geo, "art_recorder", Vector3(0.35, 0.12, 0.25), Vector3(-3.7, 0.81, -2.8), Color(0.15, 0.15, 0.16))
	g.box(geo, "occ_bin", Vector3(0.6, 0.6, 1.0), Vector3(-4.0, 0.3, -0.4), Color(0.30, 0.34, 0.30))
	g.box(
		geo, "art_notice", Vector3(0.6, 0.8, 0.02), Vector3(0.5, 1.6, -D / 2 + 0.01), Color(0.90, 0.88, 0.80)
	)
	g.box(geo, "occ_chair", Vector3(0.5, 0.9, 0.5), Vector3(1.6, 0.45, 1.4), Color(0.45, 0.33, 0.24))

	# Cameras (vertical FOV, 16:9). cam_a covers the west half, cam_b the east half.
	g.camera("cam_a", Vector3(4.2, 2.8, 3.2), Vector3(-2.0, 0.5, -1.2), 55.0)
	g.camera("cam_b", Vector3(-4.2, 2.8, 3.2), Vector3(2.2, 0.5, -1.4), 55.0)
	# Overlapping zones (0.6 m) so the cut can't ping-pong.
	g.trigger("cam_a", Vector3(-2.1, 1.0, 0), Vector3(4.8, 2.0, D))
	g.trigger("cam_b", Vector3(2.1, 1.0, 0), Vector3(4.8, 2.0, D))

	# Lighting: one sun through the south window plus a ceiling lamp.
	var sun_rot := Vector3(-48, 160, 0)
	g.render_sun(sun_rot, 1.6)
	g.render_omni(Vector3(0, 2.9, 0), 1.2, 8.0)
	g.light_rigs(sun_rot)

	g.spawn("spawn_start", Vector3(-1.9, 0, -1.4), 90.0)
	g.spawn("spawn_from_g02", Vector3(2.5, 0, -2.7), 180.0)

	g.hotspot(
		"hs_radio",
		Interactable.Kind.USE,
		Vector3(4.05, 0.9, -1.4),
		Vector3(0.5, 0.5, 0.6),
		Vector3(3.2, 0, -1.4),
		[GB.puzzle_or_text("P01", "rooms.g01.radio.solved")]
	)
	g.hotspot(
		"hs_notice",
		Interactable.Kind.EXAMINE,
		Vector3(0.5, 1.6, -3.4),
		Vector3(0.7, 0.9, 0.2),
		Vector3(0.5, 0, -2.75),
		[GB.doc("doc_quiet_hours")]
	)
	g.hotspot(
		"hs_recorder",
		Interactable.Kind.USE,
		Vector3(-3.7, 0.85, -2.8),
		Vector3(0.5, 0.3, 0.4),
		Vector3(-3.0, 0, -2.4),
		[GB.ui("save_screen")]
	)
	g.hotspot(
		"hs_bin",
		Interactable.Kind.USE,
		Vector3(-4.0, 0.4, -0.4),
		Vector3(0.7, 0.8, 1.1),
		Vector3(-3.3, 0, -0.4),
		[GB.ui("effects_bin")]
	)
	g.hotspot_examine(
		"hs_couch",
		Vector3(-2.6, 0.5, 2.3),
		Vector3(2.2, 0.9, 0.9),
		Vector3(-2.6, 0, 1.45),
		"rooms.g01.couch.examine"
	)
	g.hotspot_exit(
		"hs_door", Vector3(2.5, 1.1, -3.45), Vector3(1.2, 2.2, 0.3), Vector3(2.5, 0, -2.75), &"to_g02"
	)

	var exit := g.exit_def("to_g02", "G02", "spawn_from_g01", "g01.chain_released", "rooms.g01.door.chained")
	var data := g.room_data(DIR, ["cam_a", "cam_b"], [exit])
	data.enter_triggers = [
		GB.on_enter([], [GB.tape("tape_01_claire")], "intro.done"),
		GB.on_enter(
			[GB.flag("act1.chase_done")], [GB.text("rooms.g01.safe_after_chase")], "g01.safe_after_chase"
		),
	]
	data.name_key = "rooms.g01.name"
	data.access = RoomData.Access.NEVER
	data.safe_room = true
	# GDD §6.1 gives G01 a 1976 variant; it is built in M3 (only the Chapel is in M1).
	data.has_memory_variant = false
	data.map_rect = Rect2(40, 300, 180, 140)

	var err := g.save(DIR, "g01_dayroom", data)
	print("build_g01: ", error_string(err))
	return 0 if err == OK else 1
