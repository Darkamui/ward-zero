extends RefCounted
## G05 Administrator's Office greybox: the P04 wall safe.

const GB := preload("res://tools/greybox/greybox_lib.gd")
const DIR := "res://game/rooms/g05_admin_office"
const W := 7.0
const D := 6.0
const H := 3.0


func run(_tree: SceneTree, _args: PackedStringArray) -> int:
	var g := GB.new("G05")
	var geo := g.geometry
	g.shell(W, D, H, Color(0.55, 0.5, 0.45), [{"wall": "w", "at": -1.0, "width": 1.4}])
	g.door("col_door_g04", "w", -1.0, 1.4, W, D)
	g.box(geo, "art_safe", Vector3(0.7, 0.7, 0.05), Vector3(1.5, 1.3, -D / 2 + 0.03), Color(0.25, 0.25, 0.27))
	g.box(geo, "occ_desk", Vector3(2.0, 0.75, 1.0), Vector3(0.4, 0.375, 0.6), Color(0.38, 0.26, 0.18))
	g.box(geo, "occ_bookcase", Vector3(0.4, 2.2, 2.0), Vector3(3.25, 1.1, 0.8), Color(0.36, 0.26, 0.18))
	g.box(geo, "occ_armchair", Vector3(0.8, 0.9, 0.8), Vector3(-2.2, 0.45, 1.8), Color(0.4, 0.2, 0.18))
	g.camera("cam_a", Vector3(3.0, 2.7, 2.6), Vector3(-1.5, 0.6, -1.5), 56.0)
	g.camera("cam_b", Vector3(-3.0, 2.7, 2.6), Vector3(1.5, 0.6, -1.5), 56.0)
	g.trigger("cam_a", Vector3(-1.9, 1.0, 0), Vector3(3.8, 2.0, D))
	g.trigger("cam_b", Vector3(1.9, 1.0, 0), Vector3(3.8, 2.0, D))
	var sun_rot := Vector3(-45, 250, 0)
	g.render_sun(sun_rot, 0.9, Color(1.0, 0.9, 0.75))
	g.render_omni(Vector3(0.4, 2.7, 0.6), 1.0, 7.0)
	g.light_rigs(sun_rot)
	g.spawn("spawn_from_g04", Vector3(-3.0, 0, -1.0), -90.0)
	var kind := Interactable.Kind
	g.hotspot_exit(
		"hs_door_g04", Vector3(-3.45, 1.1, -1.0), Vector3(0.3, 2.2, 1.4), Vector3(-3.0, 0, -1.0), &"to_g04"
	)
	g.hotspot(
		"hs_safe",
		kind.USE,
		Vector3(1.5, 1.3, -2.9),
		Vector3(0.8, 0.8, 0.2),
		Vector3(1.5, 0, -2.2),
		[GB.puzzle_or_text("P04", "rooms.g05.safe.open")]
	)
	g.hotspot(
		"hs_desk",
		kind.EXAMINE,
		Vector3(0.4, 0.8, 0.6),
		Vector3(2.0, 0.3, 1.0),
		Vector3(0.4, 0, -0.3),
		[GB.text("rooms.g05.desk.examine")]
	)
	var data := g.room_data(DIR, ["cam_a", "cam_b"], [g.exit_def("to_g04", "G04", "spawn_from_g05")])
	data.name_key = "rooms.g05.name"
	data.access = RoomData.Access.SCRIPTED
	data.map_rect = Rect2(180, 60, 120, 80)
	var err := g.save(DIR, "g05_admin_office", data)
	print("build_g05: ", error_string(err))
	return 0 if err == OK else 1
