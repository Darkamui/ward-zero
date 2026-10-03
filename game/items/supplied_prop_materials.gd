extends Node3D
## The starter kit exports its sRGB palette directly into glTF linear color factors.
## Correct that once on private material copies, preserving the supplied GLBs.


func _ready() -> void:
	for node in find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.get_active_material(surface) as StandardMaterial3D
			if source:
				var material := source.duplicate() as StandardMaterial3D
				material.albedo_color = source.albedo_color.srgb_to_linear()
				mesh.set_surface_override_material(surface, material)
