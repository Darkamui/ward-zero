class_name PauseMenu
extends CanvasLayer
## Esc menu (GDD §3.2): resume, options, load, quit to title. Pauses the game.

const UI_NAME := &"pause"

var _root: Control


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_open() -> bool:
	return _root != null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		if _root:
			close()
		else:
			open()


func open() -> void:
	if _root:
		return
	get_tree().paused = true
	_root = Control.new()
	_root.theme = UiStyle.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.add_child(UiStyle.dimmer())
	var box := UiStyle.centered_panel(_root, Vector2(520, 460))
	box.add_child(UiStyle.label("ui.pause.title", 40, UiStyle.ACCENT))
	box.add_child(UiStyle.button("ui.pause.resume", close))
	box.add_child(UiStyle.button("ui.options.title", _on_options))
	box.add_child(UiStyle.button("ui.pause.quit", _on_quit))
	EventBus.ui_opened.emit(UI_NAME)


func close() -> void:
	if _root == null:
		return
	_root.queue_free()
	_root = null
	get_tree().paused = false
	EventBus.ui_closed.emit(UI_NAME)


func _on_options() -> void:
	var o := OptionsPanel.new()
	_root.add_child(o)


func _on_quit() -> void:
	close()
	get_tree().change_scene_to_file("res://game/main/title.tscn")
