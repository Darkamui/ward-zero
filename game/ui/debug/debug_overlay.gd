class_name DebugOverlay
extends CanvasLayer
## F9 overlay: room, camera, timeline, seed, fps, recent flags and noise, and a magenta
## tint over proxies for the occlusion check (docs/01-foundation.md §8.4).
## While it is open (docs/02-milestone-1.md M1-08):
##   1-6  warp to G01-G06 (first spawn)      I  give every Act 1 item
##   P    solve the puzzle in this room       M  toggle memory (rooms with a variant)
##   T    stalker test level (T02, AI on)     N  emit a 2-hop noise here
## Not created in builds with the "release" feature tag.

## Test level lives under tests/ (not exported), so this only works in the editor/debug.
const STALKER_LEVEL := "res://tests/levels/stalker/stalker_level.gd"
const WARP_ROOMS := [&"G01", &"G02", &"G03", &"G04", &"G05", &"G06"]
const ACT1_ITEMS := [
	"item_photograph",
	"item_choleric_key",
	"item_music_box_crank",
	"item_f01_admission_file",
	"item_f02_fire_clipping",
]

var _label: Label
var _recent_flags: Array[String] = []


func _ready() -> void:
	layer = 90
	visible = false
	_label = Label.new()
	_label.position = Vector2(16, 16)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)
	GameState.flag_changed.connect(_on_flag)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_overlay"):
		visible = not visible
		RenderingServer.global_shader_parameter_set(&"wz_debug_proxies", 1.0 if visible else 0.0)
		get_viewport().set_input_as_handled()
	elif visible and event is InputEventKey and event.pressed and not event.echo:
		_debug_key(event.physical_keycode)


func _debug_key(key: Key) -> void:
	if key >= KEY_1 and key <= KEY_6:
		var data: RoomData = ContentDB.get_room(WARP_ROOMS[key - KEY_1])
		var spawns := data.scene.instantiate() as Room
		var first: StringName = spawns.spawn_names()[0]
		spawns.free()
		RoomManager.go_to(data.id, first)
	elif key == KEY_I:
		for item in ACT1_ITEMS:
			GameState.give_item(item)
	elif key == KEY_M:
		MemoryShiftSystem.toggle()
	elif key == KEY_T and ResourceLoader.exists(STALKER_LEVEL):
		load(STALKER_LEVEL).register()
		RoomManager.go_to(&"T02", &"spawn_from_t01")
		StalkerDirector.activate([&"T02", &"T03", &"T04"], &"T04")
	elif key == KEY_N:
		EventBus.noise_emitted.emit(StringName(GameState.current_room), 2)
	elif key == KEY_P:
		for p in ContentDB.puzzles.values():
			if String(p.room_id) == GameState.current_room and not GameState.is_puzzle_solved(String(p.id)):
				GameState.mark_puzzle_solved(String(p.id))
				if p.solved_flag != &"":
					GameState.set_flag(p.solved_flag, true)
				Action.run_all(p.rewards)


func _process(_delta: float) -> void:
	if not visible:
		return
	var noise := []
	for n in StalkerDirector.noise_log.slice(-5):
		noise.append("%s:%d" % [n["room"], n["hops"]])
	_label.text = (
		"room %s  cam %s  %s\nseed %d  fps %d  threat %s  puzzle %s\nflags: %s\nnoise: %s"
		% [
			GameState.current_room,
			CameraDirector.active_id,
			"1976" if GameState.in_memory() else "present",
			Seed.current,
			Engine.get_frames_per_second(),
			GameState.threat_difficulty,
			GameState.puzzle_difficulty,
			", ".join(_recent_flags),
			" ".join(noise),
		]
	)


func _on_flag(flag: String, value: Variant) -> void:
	_recent_flags.append("%s=%s" % [flag, value])
	if _recent_flags.size() > 6:
		_recent_flags.pop_front()
