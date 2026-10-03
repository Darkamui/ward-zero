class_name ProxyProcessor
extends RefCounted
## Applies the proxy naming conventions (docs/01-foundation.md §8.3) to a room's nodes.
## Used at runtime by Room, by the clay render tool, and by the glTF post-import script.
##
##   floor_   walkable floor: collision (layer floor), navmesh source, proxy material
##   occ_     foreground occluder: collision (layer walls), proxy material
##   col_     wall/obstacle collision only: hidden in game, clay in renders
##   shadow_  shadow catcher only: proxy material, no collision
##   art_     render-only detail: hidden in game, clay in renders
##   cam_     Camera3D, spawn_ Marker3D: left as they are

enum Mode { GAME, RENDER }

const LAYER_FLOOR := 1
const LAYER_WALLS := 2
## Visual layer for characters, lit by camera light rigs.
const VISUAL_CHARACTERS := 2

const PROXY_SHADER := preload("res://game/shaders/proxy.gdshader")

static var _proxy_material: ShaderMaterial
static var _clay_cache: Dictionary = {}


static func apply(root: Node, mode: Mode) -> void:
	for node in _all_children(root):
		var mesh := node as MeshInstance3D
		if mesh == null:
			continue
		var name := String(mesh.name).to_lower()
		if name.begins_with("floor_"):
			_setup(mesh, mode, LAYER_FLOOR, true)
		elif name.begins_with("occ_"):
			_setup(mesh, mode, LAYER_WALLS, true)
		elif name.begins_with("col_"):
			_setup(mesh, mode, LAYER_WALLS, false)
		elif name.begins_with("shadow_"):
			_setup(mesh, mode, 0, true)
		elif name.begins_with("art_"):
			mesh.visible = mode == Mode.RENDER
			if mode == Mode.RENDER:
				mesh.material_override = clay_material(mesh)


static func _setup(mesh: MeshInstance3D, mode: Mode, layer: int, visible_in_game: bool) -> void:
	if layer != 0 and not _has_static_body(mesh):
		mesh.create_trimesh_collision()
		var body := _static_body(mesh)
		if body:
			body.collision_layer = 1 << (layer - 1)
			body.collision_mask = 0
	if mode == Mode.RENDER:
		mesh.visible = true
		mesh.material_override = clay_material(mesh)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		mesh.visible = visible_in_game
		mesh.material_override = proxy_material()
		# Proxies never cast shadows onto each other: those are baked into the render.
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


static func proxy_material() -> ShaderMaterial:
	if _proxy_material == null:
		_proxy_material = ShaderMaterial.new()
		_proxy_material.shader = PROXY_SHADER
	return _proxy_material


## Flat lit material for greybox renders. Colour from the node's "clay_color" metadata.
static func clay_material(mesh: MeshInstance3D) -> StandardMaterial3D:
	var color: Color = mesh.get_meta("clay_color", Color(0.72, 0.70, 0.66))
	var key := color.to_html()
	if not _clay_cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.9
		_clay_cache[key] = m
	return _clay_cache[key]


static func _has_static_body(mesh: MeshInstance3D) -> bool:
	return _static_body(mesh) != null


static func _static_body(mesh: MeshInstance3D) -> StaticBody3D:
	for c in mesh.get_children():
		if c is StaticBody3D:
			return c
	return null


static func _all_children(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for c in root.get_children():
		result.append(c)
		result.append_array(_all_children(c))
	return result
