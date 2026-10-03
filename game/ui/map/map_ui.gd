class_name MapUi
extends CanvasLayer
## The laminated evacuation plan (GDD §3.5, §11). Visited rooms only; red = something
## left to do ("!"), blue = cleared ("✓"); the current room is marked. On Easy puzzles,
## rooms with an unsolved puzzle get a ◆ (GDD §8.2).

const UI_NAME := &"map"
const SCALE := 1.7
const ORIGIN := Vector2(360, 190)
const RED := Color(0.75, 0.22, 0.2)
const BLUE := Color(0.25, 0.42, 0.75)

var _root: Control
var _canvas: Control
var _floor := RoomData.Floor.GROUND


func _ready() -> void:
	layer = 36
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_open() -> bool:
	return _root != null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"open_map"):
		if _root:
			close()
		elif not _ui_busy():
			open()
		get_viewport().set_input_as_handled()
	elif _root and (event.is_action_pressed(&"pause") or InventoryUi._is_right_click(event)):
		close()
		get_viewport().set_input_as_handled()


func _ui_busy() -> bool:
	var controller := get_tree().get_first_node_in_group(&"interaction_controller") as InteractionController
	return controller != null and controller.is_blocked()


func open() -> void:
	if _root:
		return
	if RoomManager.current:
		MapStatus.store(RoomManager.current)
		var data := RoomManager.current.room_data
		if data:
			_floor = data.map_floor
	_root = Control.new()
	_root.theme = UiStyle.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := UiStyle.dimmer()
	dim.color = Color(0.03, 0.03, 0.035, 0.94)
	_root.add_child(dim)
	var title := UiStyle.label("ui.map.title", 44, UiStyle.ACCENT)
	title.position = Vector2(120, 70)
	_root.add_child(title)
	var legend := UiStyle.label("ui.map.legend", 24, UiStyle.INK_DIM)
	legend.position = Vector2(120, 1000)
	_root.add_child(legend)
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_map)
	_root.add_child(_canvas)
	EventBus.ui_opened.emit(UI_NAME)


func close() -> void:
	if _root == null:
		return
	_root.queue_free()
	_root = null
	EventBus.ui_closed.emit(UI_NAME)


## Rooms drawn on the current floor plan (visited ones), for tests.
func shown_rooms() -> Array[StringName]:
	var result: Array[StringName] = []
	for id in ContentDB.rooms:
		var data: RoomData = ContentDB.rooms[id]
		if data.map_floor == _floor and data.map_rect.size != Vector2.ZERO and MapStatus.visited(String(id)):
			result.append(id)
	return result


func _draw_map() -> void:
	var font := UiStyle.UI_FONT
	var easy := GameState.puzzle_difficulty == "easy"
	for id in shown_rooms():
		var data: RoomData = ContentDB.rooms[id]
		var rect := Rect2(ORIGIN + data.map_rect.position * SCALE, data.map_rect.size * SCALE)
		var cleared := MapStatus.stored(String(id)) == MapStatus.CLEARED
		var color := BLUE if cleared else RED
		_canvas.draw_rect(rect, Color(color, 0.55))
		_canvas.draw_rect(rect, UiStyle.INK, false, 3.0)
		var label := "%s %s" % ["✓" if cleared else "!", tr(data.name_key)]
		if easy and _has_unsolved_puzzle(id):
			label += " ◆"
		_canvas.draw_string(
			font,
			rect.position + Vector2(10, 32),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 16,
			22,
			UiStyle.INK
		)
		if String(id) == GameState.current_room:
			_canvas.draw_circle(rect.get_center() + Vector2(0, 12), 10.0, UiStyle.ACCENT)


static func _has_unsolved_puzzle(room_id: StringName) -> bool:
	for p in ContentDB.puzzles.values():
		if p.room_id == room_id and not GameState.is_puzzle_solved(String(p.id)):
			return true
	return false
