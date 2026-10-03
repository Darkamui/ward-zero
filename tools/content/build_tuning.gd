extends RefCounted
## Writes game/data/tuning/<threat>.tres from the table in docs/03-milestone-2.md §2.
##   godot --headless res://tools/run_tool.tscn -- res://tools/content/build_tuning.gd [--force]

const TABLE := {
	"observer":
	{
		"catch_lethal": false,
		"autosave_every_room": true,
		"close_ups_pause": true,
		"walk_speed": 1.2,
		"run_speed": 2.2,
		"hearing_bonus": -1,
		"search_time": 6.0,
		"breath_required": 1.5,
		"breath_capacity": 6.0,
	},
	"patient":
	{
		"walk_speed": 1.5,
		"run_speed": 2.8,
		"hearing_bonus": 0,
		"search_time": 10.0,
		"breath_required": 2.5,
		"breath_capacity": 4.5,
	},
	"committed":
	{
		"saves_cost_cassette": true,
		"autosave_act_start": false,
		"walk_speed": 1.7,
		"run_speed": 3.1,
		"hearing_bonus": 1,
		"search_time": 14.0,
		"breath_required": 3.5,
		"breath_capacity": 4.2,
	},
}


func run(_tree: SceneTree, args: PackedStringArray) -> int:
	for threat in TABLE:
		var path := "res://game/data/tuning/%s.tres" % threat
		if FileAccess.file_exists(path) and not args.has("--force"):
			continue
		var t := StalkerTuning.new()
		t.threat = threat
		for key in TABLE[threat]:
			t.set(key, TABLE[threat][key])
		ResourceSaver.save(t, path)
		print("build_tuning: ", path)
	return 0
