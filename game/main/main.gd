extends Node
## Boot scene. M1 replaces this with the title menu.


func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred("res://game/main/title.tscn")
