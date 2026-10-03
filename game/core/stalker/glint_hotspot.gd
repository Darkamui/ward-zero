class_name GlintHotspot
extends Interactable
## Composure hallucination (GDD §5.4): looks like an item glint, isn't one.
## Never placed on or near puzzle-critical content (rule R2).

const LIFETIME := 20.0


func _ready() -> void:
	name = "glint_%d" % get_instance_id()
	kind = Kind.TAKE
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	cs.shape = shape
	add_child(cs)
	var m := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	m.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.95, 0.8)
	mat.emission_energy_multiplier = 3.0
	m.material_override = mat
	m.layers = 1 << (ProxyProcessor.VISUAL_CHARACTERS - 1)
	add_child(m)
	super._ready()
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)


func approach_position() -> Vector3:
	return global_position - Vector3(0, 0.1, 0)


func interact() -> void:
	EventBus.text_requested.emit("ui.glint.nothing")
	queue_free()
