class_name DebugOverlay
extends CanvasLayer
## F9 overlay: room, camera, timeline, seed, fps, recent flags and noise, and a magenta
## tint over proxies for the occlusion check (docs/01-foundation.md §8.4).
## Not created in builds with the "release" feature tag.

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
