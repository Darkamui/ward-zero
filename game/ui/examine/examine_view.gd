class_name ExamineView
extends Control
## 3D item examine (GDD §3.4): drag to turn, scroll to zoom. When the camera looks at the
## model from within an ExamineReveal's cone, the reveal fires once (adds a document,
## sets a flag, shows text).

signal revealed(reveal: ExamineReveal)

var item: ItemData
var _pivot: Node3D
var _camera: Camera3D
var _dragging := false
var _fired: Array[ExamineReveal] = []


func setup(item_data: ItemData) -> void:
	item = item_data
	var container := SubViewportContainer.new()
	container.stretch = true
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	container.add_child(vp)
	_pivot = Node3D.new()
	vp.add_child(_pivot)
	var model: Node3D
	if item.examine_model:
		model = item.examine_model.instantiate()
	else:
		model = _placeholder()
	_pivot.add_child(model)
	_camera = Camera3D.new()
	_camera.position = Vector3(0, 0, 2.2)
	vp.add_child(_camera)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 30, 0)
	vp.add_child(key)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.5, 0.55)
	vp.add_child(env)
	for r in item.examine_reveals:
		if r.sets_flag != &"" and GameState.get_flag(r.sets_flag, false):
			_fired.append(r)
		elif r.adds_document != &"" and GameState.documents.has(String(r.adds_document)):
			_fired.append(r)


## Placeholder until examine models exist: a box with a marked face for each reveal.
func _placeholder() -> Node3D:
	var root := Node3D.new()
	var m := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 0.6, 0.25)
	m.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.55, 0.5)
	m.material_override = mat
	root.add_child(m)
	for r in item.examine_reveals:
		var mark := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.6, 0.3)
		mark.mesh = q
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.9, 0.85, 0.7)
		mark.material_override = mm
		var dir := r.view_direction.normalized()
		mark.position = dir * 0.14
		if absf(dir.dot(Vector3.UP)) < 0.99:
			mark.look_at_from_position(dir * 0.14, dir * 2.0, Vector3.UP)
			mark.rotate_object_local(Vector3.UP, PI)
		root.add_child(mark)
	return root


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera.position.z = maxf(1.2, _camera.position.z - 0.15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera.position.z = minf(4.0, _camera.position.z + 0.15)
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		rotate_by(event.relative * 0.01)
		accept_event()


func rotate_by(delta: Vector2) -> void:
	_pivot.rotate_y(delta.x)
	_pivot.rotate_object_local(Vector3.RIGHT, delta.y)
	_check_reveals()


## Direction from the model to the camera, in model space.
func view_direction() -> Vector3:
	return (_pivot.global_transform.basis.inverse() * Vector3.BACK).normalized()


func _check_reveals() -> void:
	var view := view_direction()
	for r in item.examine_reveals:
		if _fired.has(r):
			continue
		if rad_to_deg(view.angle_to(r.view_direction.normalized())) <= r.tolerance_degrees:
			_fired.append(r)
			if r.sets_flag != &"":
				GameState.set_flag(r.sets_flag, true)
			if r.adds_document != &"":
				EventBus.document_requested.emit(r.adds_document)
			if r.message_key != "":
				EventBus.text_requested.emit(r.message_key)
			revealed.emit(r)
