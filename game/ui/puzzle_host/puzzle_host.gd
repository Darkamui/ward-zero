class_name PuzzleHost
extends CanvasLayer
## Opens puzzle close-ups over the room (EventBus.puzzle_requested). Right-click or Back
## closes. The world keeps running (GDD §5.1) except on Observer, where it pauses.

const UI_NAME := &"puzzle"

var current: PuzzleBase
var _root: Control


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.puzzle_requested.connect(open)


func open(puzzle_id: StringName) -> void:
	if current:
		return
	var data: PuzzleData = ContentDB.get_puzzle(puzzle_id)
	if data == null or data.scene == null:
		push_error("PuzzleHost: puzzle %s has no scene" % puzzle_id)
		return
	_root = Control.new()
	_root.theme = UiStyle.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.add_child(UiStyle.dimmer())
	current = data.scene.instantiate() as PuzzleBase
	_root.add_child(current)
	current.setup(data)
	current.close_requested.connect(close)
	var back := UiStyle.button("puzzle.common.back", close)
	back.position = Vector2(60, 980)
	_root.add_child(back)
	EventBus.ui_opened.emit(UI_NAME)
	if data.pauses_on_observer and Difficulty.tuning().close_ups_pause:
		get_tree().paused = true


func close() -> void:
	if current == null:
		return
	current.save_state()
	_root.queue_free()
	current = null
	get_tree().paused = false
	EventBus.ui_closed.emit(UI_NAME)


func is_open() -> bool:
	return current != null


func _unhandled_input(event: InputEvent) -> void:
	if (
		current
		and event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_RIGHT
	):
		get_viewport().set_input_as_handled()
		close()
	elif current and event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
