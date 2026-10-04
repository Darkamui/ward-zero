extends Control
## A player-paced chapter card. Loading saves continues to bypass this scene.

const ART := preload("res://assets/art/menus/act1_dictaphone.png")
var _entering := false
var _ambience: AudioStreamPlayer


func _ready() -> void:
	theme = UiStyle.theme()
	MenuStyle.backdrop(self, ART, 0.05)
	MenuStyle.eyebrow(self, "ui.front.institute", Vector2(140, 115))
	MenuStyle.eyebrow(self, "ui.intro.act", Vector2(140, 340))
	MenuStyle.label_at(self, "ui.intro.title", Vector2(132, 385), 112)
	MenuStyle.rule(self, Vector2(140, 547), 90)
	MenuStyle.paragraph(self, "ui.intro.body", Vector2(140, 585), 675, 30)
	MenuStyle.paragraph(self, "ui.intro.listen", Vector2(140, 740), 620, 23)
	var begin := MenuStyle.button("ui.intro.enter", _enter_game, true, 30)
	begin.name = "EnterDayroom"
	begin.position = Vector2(140, 850)
	begin.custom_minimum_size.x = 370
	add_child(begin)
	MenuStyle.footer(self, "ui.intro.controls")
	_ambience = MenuStyle.ambience(self)
	MenuStyle.reveal(self)
	begin.grab_focus.call_deferred()


func _enter_game() -> void:
	if _entering:
		return
	_entering = true
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var transition := create_tween().set_parallel(true)
	transition.tween_property(fade, "modulate:a", 1.0, 0.6)
	transition.tween_property(_ambience, "volume_db", -60.0, 0.6)
	await transition.finished
	if GameState.current_room.is_empty():
		NewGame.start("patient", "normal")
	get_tree().change_scene_to_file("res://game/main/game.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not _entering:
		get_viewport().set_input_as_handled()
		_enter_game()
