class_name EndingScreen
extends CanvasLayer
## The ending that played (GDD §2.4), then credits and the way back to the title. The
## ending itself is greybox text until its cinematic exists.

const UI_NAME := &"ending"


func _ready() -> void:
	layer = 75
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.ui_requested.connect(_on_ui_requested)


func _on_ui_requested(ui_name: StringName) -> void:
	if ui_name == UI_NAME:
		show_screen()


func show_screen() -> void:
	get_tree().paused = true
	var ending := String(GameState.get_flag("ending", Ending.RELAPSE))
	var root := Control.new()
	root.theme = UiStyle.theme()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.92, 0.9, 0.84) if ending == Ending.DISCHARGE else Color(0.02, 0.02, 0.025)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var box := UiStyle.centered_panel(root, Vector2(1300, 760))
	box.add_child(UiStyle.label("ending.%s.title" % ending, 48, UiStyle.ACCENT))
	var body := UiStyle.label("ending.%s.body" % ending, 28)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(1200, 0)
	box.add_child(body)
	var s := EndOfSliceScreen.stats()
	s["score"] = int(GameState.get_flag("p21.score", 0))
	var stats := UiStyle.label("", 26, UiStyle.INK_DIM)
	stats.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	stats.text = tr("ending.stats").format(s)
	box.add_child(stats)
	box.add_child(UiStyle.label("ending.ng_plus_unlocked", 24, UiStyle.INK_DIM))
	box.add_child(UiStyle.button("ending.to_title", _to_title))
	EventBus.ui_opened.emit(UI_NAME)


func _to_title() -> void:
	get_tree().paused = false
	StalkerDirector.reset()
	Finale.cancel()
	get_tree().change_scene_to_file("res://game/main/title.tscn")
