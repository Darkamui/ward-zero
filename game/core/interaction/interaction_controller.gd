class_name InteractionController
extends Node
## Turns mouse input into player movement and hotspot interaction (GDD §3.2).
## Disabled while any UI is open (EventBus.ui_opened / ui_closed).

signal hovered_changed(hotspot: Interactable)

const RAY_LENGTH := 200.0
const MASK_FLOOR := 1 << 0
const MASK_HOTSPOTS := 1 << 2

@export var player: Player

## Item selected in the inventory for use-item mode; empty when not in that mode.
var held_item: StringName = &""
var hovered: Interactable
var _ui_open := 0
var _last_cursor := Interactable.Cursor.NONE


func _ready() -> void:
	add_to_group(&"interaction_controller")
	EventBus.ui_opened.connect(func(_n: StringName) -> void: _ui_open += 1)
	EventBus.ui_closed.connect(func(_n: StringName) -> void: _ui_open = maxi(0, _ui_open - 1))


func is_blocked() -> bool:
	return _ui_open > 0 or player == null or CameraDirector.active_camera() == null


func _unhandled_input(event: InputEvent) -> void:
	if player and player.is_hidden():
		# Hidden: only coming out is possible (right-click, or clicking the spot again).
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT or pick_hotspot(event.position) == player.hiding_in:
				player.leave_hiding()
			get_viewport().set_input_as_handled()
		return
	if is_blocked():
		return
	if event is InputEventMouseMotion:
		_update_hover(event.position)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_left_click(event.position, event.double_click)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if held_item != &"":
				held_item = &""
			else:
				player.stop()
			get_viewport().set_input_as_handled()


func _on_left_click(screen_pos: Vector2, double: bool) -> void:
	var hotspot := pick_hotspot(screen_pos)
	if hotspot:
		var item := held_item
		held_item = &""
		player.walk_to(hotspot.approach_position(), double, _arrive_at.bind(hotspot, item))
		return
	var hit: Variant = pick_floor(screen_pos)
	if hit != null:
		player.walk_to(hit, double)


func _arrive_at(hotspot: Interactable, item: StringName) -> void:
	if not is_instance_valid(hotspot) or not hotspot.is_active():
		return
	_face(hotspot.global_position)
	if item != &"":
		hotspot.use_item(item)
	else:
		hotspot.interact()


func _face(point: Vector3) -> void:
	var d := point - player.global_position
	if Vector2(d.x, d.z).length() > 0.01:
		player.rotation.y = atan2(-d.x, -d.z)


func _update_hover(screen_pos: Vector2) -> void:
	var h := pick_hotspot(screen_pos)
	if h != hovered:
		hovered = h
		hovered_changed.emit(h)
	var cur := h.cursor() if h else Interactable.Cursor.NONE
	if held_item != &"" and h:
		cur = Interactable.Cursor.HAND
	if cur != _last_cursor:
		_last_cursor = cur
		CursorSet.apply(cur)


func pick_hotspot(screen_pos: Vector2) -> Interactable:
	var result := _ray(screen_pos, MASK_HOTSPOTS, true, false)
	if result.is_empty():
		return null
	var h := result["collider"] as Interactable
	return h if h and (h.is_active() or (player and h == player.hiding_in)) else null


func pick_floor(screen_pos: Vector2) -> Variant:
	var result := _ray(screen_pos, MASK_FLOOR, false, true)
	return null if result.is_empty() else result["position"]


func _ray(screen_pos: Vector2, mask: int, areas: bool, bodies: bool) -> Dictionary:
	var cam := CameraDirector.active_camera()
	if cam == null:
		return {}
	var from := cam.project_ray_origin(screen_pos)
	var query := PhysicsRayQueryParameters3D.create(
		from, from + cam.project_ray_normal(screen_pos) * RAY_LENGTH, mask
	)
	query.collide_with_areas = areas
	query.collide_with_bodies = bodies
	return cam.get_world_3d().direct_space_state.intersect_ray(query)
