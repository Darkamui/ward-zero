class_name GameOverScreen
extends CanvasLayer
## Shown when the stalker catches the player on a lethal difficulty (GDD §8.1).
## Retry restarts from the scripted chase checkpoint when one is set
## (docs/02-milestone-1.md D1); Load opens the title load list.

const UI_NAME := &"game_over"

## Save string captured at the checkpoint (e.g. start of the Act 1 chase).
var checkpoint := ""
var _root: Control


func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_screen() -> void:
	if _root:
		return
	get_tree().paused = true
	_root = Control.new()
	_root.theme = UiStyle.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color(0.85, 0.85, 0.82)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)
	var box := UiStyle.centered_panel(_root, Vector2(700, 400))
	box.add_child(UiStyle.label("ui.game_over.title", 44, UiStyle.ACCENT))
	if checkpoint != "":
		box.add_child(UiStyle.button("ui.game_over.retry", _retry))
	if latest_slot() != -1:
		box.add_child(UiStyle.button("ui.game_over.load_last", _load_last))
	box.add_child(UiStyle.button("ui.game_over.quit", _quit))
	EventBus.ui_opened.emit(UI_NAME)


## Most recently written save slot, or -1.
static func latest_slot() -> int:
	var best := -1
	var best_time := ""
	for info in SaveSystem.list_slots():
		if String(info["saved_at"]) > best_time:
			best_time = String(info["saved_at"])
			best = int(info["slot"])
	return best


func _load_last() -> void:
	if SaveSystem.load_slot(latest_slot()) == SaveSystem.SaveError.OK:
		SaveScreen.restart_game(get_tree())


func _retry() -> void:
	SaveSystem.import_string(checkpoint)
	SaveScreen.restart_game(get_tree())


func _quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://game/main/title.tscn")
