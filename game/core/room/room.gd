class_name Room
extends Node3D
## Root of a room scene. Expected children (created by the greybox builder or by hand):
##   Geometry     proxy meshes named by convention (see ProxyProcessor), or proxy.glb
##   Navigation   NavigationRegion3D, baked at load if its mesh is empty
##   Cameras      Camera3D nodes named after CameraDef ids; each may hold a LightRig child
##   Triggers     CameraTrigger areas
##   Spawns       Marker3D nodes named spawn_*
##   Hotspots     Interactable areas
##   RenderLights lights used only by the clay render tool

## Set by tools/render_room.gd before instancing, so proxies keep their clay look.
static var render_mode := false

@export var room_data: RoomData

var cameras: Dictionary[StringName, Camera3D] = {}
var triggers: Array[CameraTrigger] = []


func _ready() -> void:
	var mode := ProxyProcessor.Mode.RENDER if render_mode else ProxyProcessor.Mode.GAME
	ProxyProcessor.apply(self, mode)
	var render_lights := get_node_or_null("RenderLights")
	if render_lights:
		render_lights.visible = render_mode
		for light in render_lights.get_children():
			if light is Light3D:
				light.visible = render_mode
	for cam in _children_of("Cameras"):
		if cam is Camera3D:
			cameras[StringName(cam.name)] = cam
			cam.keep_aspect = Camera3D.KEEP_HEIGHT
	for t in _children_of("Triggers"):
		if t is CameraTrigger:
			triggers.append(t)
	if not render_mode:
		_bake_navigation()
	_apply_timeline_groups(GameState.in_memory())


func room_id() -> StringName:
	return room_data.id if room_data else StringName(name)


func get_spawn(spawn_name: StringName) -> Marker3D:
	var spawns := get_node_or_null("Spawns")
	if spawns == null:
		return null
	return spawns.get_node_or_null(NodePath(String(spawn_name))) as Marker3D


func spawn_names() -> Array[StringName]:
	var result: Array[StringName] = []
	for s in _children_of("Spawns"):
		result.append(StringName(s.name))
	return result


func navigation_region() -> NavigationRegion3D:
	return get_node_or_null("Navigation") as NavigationRegion3D


## Camera whose trigger contains the point, or the first camera.
func camera_for_point(point: Vector3) -> StringName:
	for t in triggers:
		if area_contains(t, point):
			return t.camera_id
	if room_data and not room_data.cameras.is_empty():
		return room_data.cameras[0].id
	return cameras.keys()[0] if not cameras.is_empty() else &""


func hotspots() -> Array[Node]:
	return _children_of("Hotspots")


## Toggles present_only / memory_only nodes (ADR-004).
func _apply_timeline_groups(memory: bool) -> void:
	for n in _descendants(self):
		if n is Node3D:
			if n.is_in_group(&"present_only"):
				n.visible = not memory
			elif n.is_in_group(&"memory_only"):
				n.visible = memory


func set_timeline(memory: bool) -> void:
	_apply_timeline_groups(memory)


func _bake_navigation() -> void:
	var region := navigation_region()
	if region == null:
		return
	if region.navigation_mesh != null and region.navigation_mesh.get_polygon_count() > 0:
		return
	# Bake into a fresh mesh and assign it afterwards: re-assigning the same object is a
	# no-op, which would leave the region registered with the empty mesh.
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = (
		(1 << (ProxyProcessor.LAYER_FLOOR - 1)) | (1 << (ProxyProcessor.LAYER_WALLS - 1))
	)
	nm.cell_size = 0.1
	nm.cell_height = 0.1
	nm.agent_radius = 0.3
	nm.agent_height = 1.8
	nm.agent_max_climb = 0.2
	# Only voxelize near floor level so furniture tops don't become walkable islands.
	# Obstacles still carve the floor through their lower part.
	nm.filter_baking_aabb = AABB(Vector3(-100, -0.5, -100), Vector3(200, 1.0, 200))
	var source := NavigationMeshSourceGeometryData3D.new()
	# Parse from the room root so Geometry's collision bodies are found.
	NavigationServer3D.parse_source_geometry_data(nm, source, self)
	NavigationServer3D.bake_from_source_geometry_data(nm, source)
	region.navigation_mesh = nm


func _children_of(path: String) -> Array[Node]:
	var n := get_node_or_null(path)
	return n.get_children() if n else ([] as Array[Node])


static func _descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for c in root.get_children():
		result.append(c)
		result.append_array(_descendants(c))
	return result


static func area_contains(area: Area3D, point: Vector3) -> bool:
	for c in area.get_children():
		var cs := c as CollisionShape3D
		if cs == null or cs.shape == null:
			continue
		var local := cs.global_transform.affine_inverse() * point
		if cs.shape is BoxShape3D:
			var half: Vector3 = (cs.shape as BoxShape3D).size * 0.5
			if absf(local.x) <= half.x and absf(local.y) <= half.y and absf(local.z) <= half.z:
				return true
	return false
