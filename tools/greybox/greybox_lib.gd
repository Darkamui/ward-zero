extends RefCounted
## Helpers for greybox room builder scripts. Produces the node layout Room expects.

var root: Room
var geometry: Node3D
var navigation: NavigationRegion3D
var cameras: Node3D
var triggers: Node3D
var spawns: Node3D
var hotspots: Node3D
var render_lights: Node3D


func _init(room_name: String) -> void:
	root = Room.new()
	root.name = room_name
	geometry = _child(root, "Geometry", Node3D.new()) as Node3D
	navigation = _child(root, "Navigation", NavigationRegion3D.new()) as NavigationRegion3D
	cameras = _child(root, "Cameras", Node3D.new()) as Node3D
	triggers = _child(root, "Triggers", Node3D.new()) as Node3D
	spawns = _child(root, "Spawns", Node3D.new()) as Node3D
	hotspots = _child(root, "Hotspots", Node3D.new()) as Node3D
	render_lights = _child(root, "RenderLights", Node3D.new()) as Node3D


func box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	m.position = pos
	m.set_meta("clay_color", color)
	return _child(parent, node_name, m)


func camera(id: String, pos: Vector3, look_at_point: Vector3, fov: float) -> Camera3D:
	var cam := Camera3D.new()
	cam.transform = Transform3D(Basis(), pos).looking_at(look_at_point, Vector3.UP)
	cam.fov = fov
	cam.near = 0.05
	cam.far = 60.0
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	return _child(cameras, id, cam)


func trigger(camera_id: String, center: Vector3, size: Vector3) -> CameraTrigger:
	var t := CameraTrigger.new()
	t.camera_id = StringName(camera_id)
	t.position = center
	_child(triggers, "trigger_" + camera_id, t)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	_child(t, "Shape", cs)
	return t


func render_sun(rotation_deg: Vector3, energy: float) -> void:
	var l := DirectionalLight3D.new()
	l.rotation_degrees = rotation_deg
	l.light_energy = energy
	l.shadow_enabled = true
	l.directional_shadow_max_distance = 25.0
	_child(render_lights, "Sun", l)


func render_omni(pos: Vector3, energy: float, light_range: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_energy = energy
	l.omni_range = light_range
	l.shadow_enabled = true
	l.light_color = Color(1.0, 0.92, 0.8)
	_child(render_lights, "Lamp", l)


## One rig per camera: a key light matching the render's sun (casts the character's
## shadow onto proxies) plus a fill light near the camera that only lights characters.
func light_rigs(sun_rotation_deg: Vector3) -> void:
	for cam in cameras.get_children():
		var rig: Node3D = _child(cam, "LightRig", Node3D.new())
		rig.top_level = true
		var key := DirectionalLight3D.new()
		key.rotation_degrees = sun_rotation_deg
		key.light_energy = 1.1
		key.shadow_enabled = true
		key.directional_shadow_max_distance = 20.0
		_child(rig, "Key", key)
		var fill := OmniLight3D.new()
		fill.position = (cam as Camera3D).position
		fill.omni_range = 14.0
		fill.light_energy = 0.7
		fill.light_cull_mask = 1 << (ProxyProcessor.VISUAL_CHARACTERS - 1)
		_child(rig, "Fill", fill)


func spawn(spawn_name: String, pos: Vector3, yaw_deg: float) -> Marker3D:
	var m := Marker3D.new()
	m.position = pos
	m.rotation_degrees.y = yaw_deg
	return _child(spawns, spawn_name, m)


func hotspot_examine(
	node_name: String, center: Vector3, size: Vector3, approach: Vector3, text_key: String
) -> Interactable:
	var h := _hotspot(node_name, center, size, approach)
	h.kind = Interactable.Kind.EXAMINE
	var show := ShowText.new()
	show.key = text_key
	h.actions = [show]
	return h


func hotspot_exit(
	node_name: String, center: Vector3, size: Vector3, approach: Vector3, exit_id: StringName
) -> Interactable:
	var h := _hotspot(node_name, center, size, approach)
	h.kind = Interactable.Kind.EXIT
	h.exit_id = exit_id
	return h


func _hotspot(node_name: String, center: Vector3, size: Vector3, approach: Vector3) -> Interactable:
	var h := Interactable.new()
	h.position = center
	_child(hotspots, node_name, h)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	_child(h, "Shape", cs)
	var m := Marker3D.new()
	m.position = approach - center
	_child(h, "Approach", m)
	return h


func room_data(dir: String, camera_ids: Array, exits: Array) -> RoomData:
	var data := RoomData.new()
	data.id = StringName(root.name)
	for id in camera_ids:
		var c := CameraDef.new()
		c.id = StringName(id)
		var bg := "%s/bg/%s.webp" % [dir, id]
		if ResourceLoader.exists(bg):
			c.background = load(bg)
		var bg_mem := "%s/bg_mem/%s.webp" % [dir, id]
		if ResourceLoader.exists(bg_mem):
			c.memory_background = load(bg_mem)
		data.cameras.append(c)
	for e in exits:
		data.exits.append(e)
	return data


func save(dir: String, file_name: String, data: RoomData) -> Error:
	DirAccess.make_dir_recursive_absolute(dir)
	_own(root, root)
	var scene := PackedScene.new()
	var err := scene.pack(root)
	if err != OK:
		return err
	var scene_path := "%s/%s.tscn" % [dir, file_name]
	err = ResourceSaver.save(scene, scene_path)
	if err != OK:
		return err
	data.scene = load(scene_path)
	err = ResourceSaver.save(data, "%s/room_data.tres" % dir)
	root.free()
	return err


func _child(parent: Node, node_name: String, node: Node) -> Variant:
	node.name = node_name
	parent.add_child(node)
	return node


func _own(node: Node, owner_node: Node) -> void:
	for c in node.get_children():
		c.owner = owner_node
		_own(c, owner_node)
