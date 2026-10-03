class_name EndOfSliceScreen
extends CanvasLayer
## End of the M1 vertical slice (docs/02-milestone-1.md §2.1, M1-16): puzzles solved,
## fragments found, play time.

const UI_NAME := &"end_of_slice"
const ACT1_PUZZLES := ["P01", "P02", "P03", "P04", "P05"]


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.ui_requested.connect(_on_ui_requested)


func _on_ui_requested(ui_name: StringName) -> void:
	if ui_name == UI_NAME:
		show_screen()


static func stats() -> Dictionary:
	var solved := 0
	for p in ACT1_PUZZLES:
		if GameState.is_puzzle_solved(p):
			solved += 1
	return {
		"solved": solved,
		"total": ACT1_PUZZLES.size(),
		"fragments": GameState.fragments().size(),
		"time": "%d:%02d" % [int(GameState.play_time) / 3600, (int(GameState.play_time) / 60) % 60],
	}


func show_screen() -> void:
	get_tree().paused = true
	var root := Control.new()
	root.theme = UiStyle.theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.025)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var box := UiStyle.centered_panel(root, Vector2(1000, 560))
	box.add_child(UiStyle.label("ui.slice.title", 44, UiStyle.ACCENT))
	var s := stats()
	var l := UiStyle.label("", 30)
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.text = tr("ui.slice.stats").format(s)
	box.add_child(l)
	box.add_child(UiStyle.label("ui.slice.thanks", 26, UiStyle.INK_DIM))
	box.add_child(UiStyle.button("ui.game_over.quit", _quit))
	EventBus.ui_opened.emit(UI_NAME)


func _quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://game/main/title.tscn")
