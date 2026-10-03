extends "res://game/items/supplied_prop_materials.gd"
## Print the same seeded date that the inside-face reveal adds to Files.


func _ready() -> void:
	super._ready()
	$InsidePrint.text = "LAVOIE, M.\n%s" % DocumentRenderer.resolve("puzzle:P03.birthdate")
