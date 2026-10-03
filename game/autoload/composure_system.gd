extends Node
## Hidden composure meter (GDD §5.4, docs/03-milestone-2.md §5). Drives the post shader
## (wz_composure), hearing (+1 hop when Breaking, via StalkerDirector), and harmless
## hallucinations: fake item glints that vanish when clicked. Rule R2: nothing here ever
## touches nodes in the "puzzle_critical" group.

signal band_changed(band: Band)

enum Band { STEADY, SHAKEN, BREAKING }

const PUZZLE_CRITICAL_GROUP := &"puzzle_critical"
const SHAKEN_BELOW := 0.66
const BREAKING_BELOW := 0.33
const SEEN_RATE := -0.08
const UNLIT_RATE := -0.01
const SAFE_ROOM_RATE := 0.02
const GLINT_INTERVAL := 40.0

## Tests and the cut list (GDD §13.2 item 1) can switch hallucinations off.
var hallucinations_enabled := true
var _band := Band.STEADY
var _glint_timer := GLINT_INTERVAL


func band() -> Band:
	if GameState.composure < BREAKING_BELOW:
		return Band.BREAKING
	if GameState.composure < SHAKEN_BELOW:
		return Band.SHAKEN
	return Band.STEADY


func _process(delta: float) -> void:
	var room := RoomManager.current
	if room == null or room.room_data == null or get_tree().paused:
		return
	var rate := 0.0
	if StalkerDirector.stalker_sees_player():
		rate += SEEN_RATE
	if room.room_data.unlit:
		rate += UNLIT_RATE
	if room.room_data.safe_room and not StalkerDirector.chase_active:
		rate += SAFE_ROOM_RATE
	if rate != 0.0:
		GameState.set_composure(GameState.composure + rate * delta)
	var b := band()
	if b != _band:
		_band = b
		band_changed.emit(b)
	RenderingServer.global_shader_parameter_set(&"wz_composure", 1.0 - GameState.composure)
	if hallucinations_enabled and b != Band.STEADY and not room.room_data.safe_room:
		_glint_timer -= delta
		if _glint_timer <= 0.0:
			_glint_timer = GLINT_INTERVAL * (0.5 if b == Band.BREAKING else 1.0)
			spawn_glint(room)


## A fake item glint at a random reachable spot. Clicking it shows "nothing there".
func spawn_glint(room: Room) -> GlintHotspot:
	var map := room.get_world_3d().navigation_map
	var p := room.global_position + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))
	var glint := GlintHotspot.new()
	var hotspots := room.get_node_or_null("Hotspots")
	if hotspots == null:
		return null
	hotspots.add_child(glint)
	glint.global_position = NavigationServer3D.map_get_closest_point(map, p) + Vector3(0, 0.1, 0)
	return glint
