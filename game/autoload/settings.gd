extends Node
## Player options (GDD §11-12), saved to user://settings.cfg, separate from save games.
## Creates the audio buses if the project has no bus layout yet.

signal changed(key: String)

const PATH := "user://settings.cfg"
const BUSES := ["Music", "Ambience", "SFX", "Voice", "UI"]
const LOCALES := ["en", "fr_CA"]
const SUBTITLE_SIZES := {"small": 24, "medium": 30, "large": 38}

var values := {
	"locale": "",
	"subtitles": true,
	"subtitle_size": "medium",
	"subtitle_background": true,
	"volume_Master": 1.0,
	"volume_Music": 0.8,
	"volume_Ambience": 0.9,
	"volume_SFX": 1.0,
	"volume_Voice": 1.0,
	"volume_UI": 0.8,
	"skip_door_animation": false,
	"fullscreen": false,
	"photosensitivity": false,
	"grain": 1.0,
	"aberration": 1.0,
}


func _ready() -> void:
	_ensure_buses()
	load_settings()
	if values["locale"] == "":
		var os_locale := OS.get_locale_language()
		values["locale"] = "fr_CA" if os_locale == "fr" else "en"
	apply_all()


func get_value(key: String) -> Variant:
	return values.get(key)


func set_value(key: String, value: Variant) -> void:
	values[key] = value
	_apply(key)
	save_settings()
	changed.emit(key)


func subtitle_font_size() -> int:
	return SUBTITLE_SIZES.get(values["subtitle_size"], 30)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for key in values:
		if cfg.has_section_key("settings", key):
			var v: Variant = cfg.get_value("settings", key)
			if typeof(v) == typeof(values[key]) or (v is float and values[key] is float):
				values[key] = v


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in values:
		cfg.set_value("settings", key, values[key])
	cfg.save(PATH)


func apply_all() -> void:
	for key in values:
		_apply(key)


func _apply(key: String) -> void:
	var v: Variant = values[key]
	if key == "locale":
		TranslationServer.set_locale(v if v in LOCALES else "en")
	elif key.begins_with("volume_"):
		var bus := AudioServer.get_bus_index(key.trim_prefix("volume_"))
		if bus != -1:
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(float(v), 0.0001)))
	elif key == "skip_door_animation":
		RoomManager.skip_door_animation = bool(v)
	elif key == "fullscreen" and not Engine.is_editor_hint() and DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if v else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)


func _ensure_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")
