extends Node
## Owns the active fixed camera and its pre-rendered background (GDD §3.3, §9.2).
## The background is a global shader texture shared by the backdrop and every proxy,
## so the two always match.
##
## Cuts: every physics frame, if the player has left the active camera's trigger zones,
## cut to the first zone that contains them. Overlapping zones therefore give hysteresis
## (no ping-pong), and teleports or spawns resolve correctly without relying on area
## enter events.

signal camera_cut(camera_id: StringName)

const BACKDROP_SHADER := preload("res://game/shaders/backdrop.gdshader")
var room: Room
var active_id: StringName = &""
var _backdrop: MeshInstance3D
var _placeholder: Texture2D


func _ready() -> void:
	_backdrop = MeshInstance3D.new()
	_backdrop.name = "Backdrop"
	_backdrop.mesh = QuadMesh.new()
	var mat := ShaderMaterial.new()
	mat.shader = BACKDROP_SHADER
	_backdrop.material_override = mat
	_backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_backdrop.extra_cull_margin = 1000.0
	GameState.timeline_changed.connect(func(_m: bool) -> void: refresh())
	GameState.flag_changed.connect(_on_flag_changed)
	GameState.state_loaded.connect(refresh)


func register_room(new_room: Room) -> void:
	room = new_room
	active_id = &""


func unregister_room() -> void:
	if _backdrop.get_parent():
		_backdrop.get_parent().remove_child(_backdrop)
	room = null
	active_id = &""


func active_camera() -> Camera3D:
	if room == null:
		return null
	return room.cameras.get(active_id)


func cut_to(camera_id: StringName) -> void:
	if room == null or not room.cameras.has(camera_id):
		push_error("CameraDirector: no camera '%s'" % camera_id)
		return
	var cam: Camera3D = room.cameras[camera_id]
	cam.make_current()
	active_id = camera_id
	for id in room.cameras:
		var rig := room.cameras[id].get_node_or_null("LightRig")
		if rig:
			rig.visible = id == camera_id
	_attach_backdrop(cam)
	RenderingServer.global_shader_parameter_set(&"wz_background", background_for(camera_id))
	camera_cut.emit(camera_id)


## Re-applies the shared backdrop/proxy texture after timeline or state changes.
func refresh() -> void:
	if room and active_id != &"":
		RenderingServer.global_shader_parameter_set(&"wz_background", background_for(active_id))


func background_for(camera_id: StringName) -> Texture2D:
	var def: CameraDef = room.room_data.get_camera(camera_id) if room and room.room_data else null
	if def:
		if GameState.in_memory() and def.memory_background:
			return def.memory_background
		if def.state_background and def.state_flag != &"" and GameState.get_flag(def.state_flag):
			return def.state_background
		if def.background:
			return def.background
	return _placeholder_texture()


func _on_flag_changed(flag: String, _value: Variant) -> void:
	if room == null or room.room_data == null:
		return
	for def in room.room_data.cameras:
		if def.state_flag == flag:
			refresh()
			return


func _attach_backdrop(cam: Camera3D) -> void:
	if _backdrop.get_parent() != cam:
		if _backdrop.get_parent():
			_backdrop.get_parent().remove_child(_backdrop)
		cam.add_child(_backdrop)
	var distance := cam.far * 0.9
	var height := 2.0 * distance * tan(deg_to_rad(cam.fov) * 0.5)
	(_backdrop.mesh as QuadMesh).size = Vector2(height * 16.0 / 9.0, height) * 1.1
	_backdrop.transform = Transform3D(Basis(), Vector3(0, 0, -distance))


func _physics_process(_delta: float) -> void:
	if room == null or active_id == &"" or RoomManager.player == null:
		return
	var wanted := zone_camera_for(RoomManager.player.global_position)
	if wanted != &"" and wanted != active_id:
		cut_to(wanted)


## Camera to show for a player at point: the active one while the point is inside any of
## its zones, otherwise the first zone containing the point, otherwise none.
func zone_camera_for(point: Vector3) -> StringName:
	var first := &""
	for t in room.triggers:
		if Room.area_contains(t, point):
			if t.camera_id == active_id:
				return active_id
			if first == &"":
				first = t.camera_id
	return first


func _placeholder_texture() -> Texture2D:
	if _placeholder == null:
		var g := Gradient.new()
		g.set_color(0, Color(0.12, 0.12, 0.14))
		g.set_color(1, Color(0.30, 0.28, 0.26))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill_from = Vector2(0, 0)
		t.fill_to = Vector2(0, 1)
		_placeholder = t
	return _placeholder
