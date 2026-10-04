class_name MenuStyle
extends RefCounted
## Front-end art direction, scoped to the title, options and chapter screens.

const BACKGROUND := preload("res://assets/art/menus/title_corridor.png")
const MUTED := Color("a8aaa0")
const LINE := Color(0.71, 0.69, 0.59, 0.24)


static func backdrop(parent: Control, texture: Texture2D = BACKGROUND, shade := 0.0) -> void:
	var art := UiStyle.artwork(texture, Vector2.ZERO, Vector2.ZERO)
	art.modulate = Color(1.0 - shade, 1.0 - shade, 1.0 - shade)
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	parent.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.015, 0.022, 0.02, 0.68))
	gradient.set_color(1, Color(0.015, 0.022, 0.02, 0.0))
	var fade := GradientTexture2D.new()
	fade.gradient = gradient
	fade.fill_from = Vector2(0, 0.5)
	fade.fill_to = Vector2(0.85, 0.5)
	var overlay := TextureRect.new()
	overlay.texture = fade
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bottom_gradient := Gradient.new()
	bottom_gradient.set_color(0, Color(0.01, 0.015, 0.015, 0.0))
	bottom_gradient.set_color(1, Color(0.01, 0.015, 0.015, 0.85))
	var bottom_texture := GradientTexture2D.new()
	bottom_texture.gradient = bottom_gradient
	bottom_texture.fill_from = Vector2(0, 0.72)
	bottom_texture.fill_to = Vector2(0, 1)
	var bottom := TextureRect.new()
	bottom.texture = bottom_texture
	bottom.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static func rule(parent: Control, at: Vector2, width: float) -> void:
	var line := ColorRect.new()
	line.color = LINE
	line.position = at
	line.size = Vector2(width, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)


static func label_at(
	parent: Control, key: String, at: Vector2, font_size := 24, color := UiStyle.INK
) -> Label:
	var label := UiStyle.label(key, font_size, color)
	label.position = at
	parent.add_child(label)
	return label


static func eyebrow(parent: Control, key: String, at: Vector2) -> Label:
	var label := label_at(parent, key, at, 20, UiStyle.ACCENT)
	label.add_theme_font_override("font", UiStyle.TYPEWRITER_FONT)
	return label


static func button(key: String, action: Callable, primary := false, font_size := 28) -> Button:
	var b := UiStyle.button(key, action, font_size)
	b.custom_minimum_size.y = 64
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var normal := UiStyle._box(Color(0.06, 0.08, 0.07, 0.3 if primary else 0), 0, UiStyle.ACCENT)
	normal.border_width_left = 3 if primary else 0
	normal.content_margin_left = 22
	b.add_theme_stylebox_override("normal", normal)
	var selected := UiStyle._box(Color(0.67, 0.59, 0.39, 0.12), 0, UiStyle.ACCENT)
	selected.border_width_left = 3
	selected.content_margin_left = 22
	b.add_theme_stylebox_override("hover", selected)
	b.add_theme_stylebox_override("pressed", selected)
	b.add_theme_stylebox_override("disabled", UiStyle._box(Color.TRANSPARENT, 0, Color.TRANSPARENT))
	b.add_theme_color_override("font_disabled_color", Color("777b73"))
	return b


static func paragraph(parent: Control, key: String, at: Vector2, width: float, font_size := 26) -> Label:
	var label := label_at(parent, key, at, font_size, MUTED)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size.x = width
	label.set_deferred("size", Vector2(width, 0))
	return label


static func footer(parent: Control, key: String) -> void:
	rule(parent, Vector2(140, 980), 1640)
	label_at(parent, key, Vector2(140, 1002), 19, MUTED)
	var brand := label_at(parent, "ui.front.institute", Vector2(1120, 1002), 19, MUTED)
	brand.size.x = 660
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


static func reveal(control: Control) -> void:
	control.modulate.a = 0.0
	control.create_tween().tween_property(control, "modulate:a", 1.0, 0.45)


static func ambience(parent: Node) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = AudioDirector.looped(preload("res://game/audio/g01/dayroom_loop.ogg"))
	player.bus = &"Ambience"
	player.volume_db = -24.0
	parent.add_child(player)
	player.play()
	return player
