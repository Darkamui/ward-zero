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


## Four walls (col_) with door gaps. gaps: [{wall: "n"/"s"/"e"/"w", at: offset along the
## wall's axis, width}]. Each gap gets a lintel above door_height.
func shell(w: float, d: float, h: float, wall_color: Color, gaps: Array, door_height := 2.2) -> void:
	box(geometry, "floor_main", Vector3(w, 0.1, d), Vector3(0, -0.05, 0), Color(0.42, 0.44, 0.40))
	box(geometry, "art_ceiling", Vector3(w, 0.1, d), Vector3(0, h + 0.05, 0), Color(0.75, 0.74, 0.70))
	for wall in ["n", "s", "e", "w"]:
		var along := w if wall in ["n", "s"] else d
		var cuts := []
		for g in gaps:
			if g["wall"] == wall:
				cuts.append([g["at"] - g["width"] / 2.0, g["at"] + g["width"] / 2.0])
		cuts.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var start := -along / 2.0
		var pieces := []
		for c in cuts:
			pieces.append([start, c[0]])
			start = c[1]
		pieces.append([start, along / 2.0])
		var i := 0
		for p in pieces:
			var length: float = p[1] - p[0]
			if length > 0.01:
				_wall_piece(
					wall, "col_wall_%s_%d" % [wall, i], (p[0] + p[1]) / 2.0, length, h, 0.0, w, d, wall_color
				)
			i += 1
		for c in cuts:
			var length: float = c[1] - c[0]
			_wall_piece(
				wall,
				"art_lintel_%s_%d" % [wall, i],
				(c[0] + c[1]) / 2.0,
				length,
				h - door_height,
				door_height,
				w,
				d,
				wall_color
			)
			i += 1


func _wall_piece(
	wall: String,
	node_name: String,
	mid: float,
	length: float,
	height: float,
	base: float,
	w: float,
	d: float,
	color: Color
) -> void:
	var t := 0.2
	match wall:
		"n":
			box(
				geometry,
				node_name,
				Vector3(length, height, t),
				Vector3(mid, base + height / 2, -d / 2 - t / 2),
				color
			)
		"s":
			box(
				geometry,
				node_name,
				Vector3(length, height, t),
				Vector3(mid, base + height / 2, d / 2 + t / 2),
				color
			)
		"e":
			box(
				geometry,
				node_name,
				Vector3(t, height, length),
				Vector3(w / 2 + t / 2, base + height / 2, mid),
				color
			)
		"w":
			box(
				geometry,
				node_name,
				Vector3(t, height, length),
				Vector3(-w / 2 - t / 2, base + height / 2, mid),
				color
			)


## Closed door slab in a gap (blocks walking; drawn in renders).
func door(
	node_name: String,
	wall: String,
	at: float,
	width: float,
	w: float,
	d: float,
	color := Color(0.36, 0.26, 0.18),
	height := 2.2
) -> MeshInstance3D:
	var t := 0.08
	match wall:
		"n":
			return box(
				geometry, node_name, Vector3(width, height, t), Vector3(at, height / 2, -d / 2 - 0.02), color
			)
		"s":
			return box(
				geometry, node_name, Vector3(width, height, t), Vector3(at, height / 2, d / 2 + 0.02), color
			)
		"e":
			return box(
				geometry, node_name, Vector3(t, height, width), Vector3(w / 2 + 0.02, height / 2, at), color
			)
	return box(geometry, node_name, Vector3(t, height, width), Vector3(-w / 2 - 0.02, height / 2, at), color)


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


func render_sun(rotation_deg: Vector3, energy: float, color := Color.WHITE) -> DirectionalLight3D:
	var l := DirectionalLight3D.new()
	l.light_color = color
	l.rotation_degrees = rotation_deg
	l.light_energy = energy
	l.shadow_enabled = true
	l.directional_shadow_max_distance = 25.0
	return _child(render_lights, "Sun", l)


func render_omni(
	pos: Vector3, energy: float, light_range: float, color := Color(1.0, 0.92, 0.8)
) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_energy = energy
	l.omni_range = light_range
	l.shadow_enabled = true
	l.light_color = color
	return _child(render_lights, "Lamp", l)


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


## Generic hotspot with actions and optional visibility conditions.
func hotspot(
	node_name: String,
	kind: Interactable.Kind,
	center: Vector3,
	size: Vector3,
	approach: Vector3,
	actions: Array = [],
	visible_if: Array = []
) -> Interactable:
	var h := _hotspot(node_name, center, size, approach)
	h.kind = kind
	h.actions.assign(actions)
	h.visible_if.assign(visible_if)
	return h


## Hiding spot (GDD §5.3) with an Inside marker where the hidden player waits.
func hiding_spot(
	node_name: String, center: Vector3, size: Vector3, approach: Vector3, inside: Vector3
) -> HidingSpot:
	var h := HidingSpot.new()
	h.position = center
	_child(hotspots, node_name, h)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	_child(h, "Shape", cs)
	var a := Marker3D.new()
	a.position = approach - center
	_child(h, "Approach", a)
	var i := Marker3D.new()
	i.position = inside - center
	_child(h, "Inside", i)
	return h


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


## Marks a node as visible only in one timeline (ADR-004). Persistent in the saved scene.
func timeline_only(node: Node, memory: bool) -> Node:
	node.add_to_group(&"memory_only" if memory else &"present_only", true)
	return node


func exit_def(
	id: String, target_room: String, target_spawn: String, lock_flag := "", locked_key := ""
) -> ExitDef:
	var e := ExitDef.new()
	e.id = StringName(id)
	e.target_room = StringName(target_room)
	e.target_spawn = StringName(target_spawn)
	e.lock_flag = StringName(lock_flag)
	if locked_key != "":
		e.locked_message_key = locked_key
	return e


# --- Action / condition shorthands ---------------------------------------------


static func text(key: String) -> ShowText:
	var a := ShowText.new()
	a.key = key
	return a


static func doc(id: String) -> OpenDocument:
	var a := OpenDocument.new()
	a.document_id = StringName(id)
	return a


static func puzzle(id: String) -> OpenPuzzle:
	var a := OpenPuzzle.new()
	a.puzzle_id = StringName(id)
	return a


static func ui(ui_name: String) -> OpenUi:
	var a := OpenUi.new()
	a.ui_name = StringName(ui_name)
	return a


static func tape(id: String) -> PlayTape:
	var a := PlayTape.new()
	a.tape_id = StringName(id)
	return a


static func give(id: String) -> GiveItem:
	var a := GiveItem.new()
	a.item_id = StringName(id)
	return a


static func script(script_name: String) -> StartScript:
	var a := StartScript.new()
	a.script_name = StringName(script_name)
	return a


static func set_flag(flag: String, value := true) -> SetFlag:
	var a := SetFlag.new()
	a.flag = StringName(flag)
	a.value = value
	return a


static func when(conditions: Array, then_actions: Array, else_actions: Array = []) -> ConditionalAction:
	var a := ConditionalAction.new()
	a.conditions.assign(conditions)
	a.then_actions.assign(then_actions)
	a.else_actions.assign(else_actions)
	return a


static func flag(name: String, value := true) -> FlagIs:
	var c := FlagIs.new()
	c.flag = StringName(name)
	c.value = value
	return c


static func has(item: String) -> HasItem:
	var c := HasItem.new()
	c.item_id = StringName(item)
	return c


static func solved(puzzle_id: String) -> PuzzleSolved:
	var c := PuzzleSolved.new()
	c.puzzle_id = StringName(puzzle_id)
	return c


static func in_memory(value := true) -> TimelineIs:
	var c := TimelineIs.new()
	c.memory = value
	return c


static func on_enter(conditions: Array, actions: Array, once_flag := "") -> EnterTrigger:
	var t := EnterTrigger.new()
	t.conditions.assign(conditions)
	t.actions.assign(actions)
	t.once_flag = StringName(once_flag)
	return t


## A puzzle hotspot: opens the close-up until solved, then shows solved_key.
static func puzzle_or_text(puzzle_id: String, solved_key: String) -> ConditionalAction:
	return when([solved(puzzle_id)], [text(solved_key)], [puzzle(puzzle_id)])


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
