class_name UiStyle
extends RefCounted
## Shared look for menus and overlays (GDD §11: diegetic, late-90s). Builds the project
## theme in code so there is one place to change it. Sizes assume the 1920x1080 canvas.

const INK := Color(0.92, 0.90, 0.85)
const INK_DIM := Color(0.62, 0.60, 0.56)
const ACCENT := Color(0.85, 0.72, 0.45)
const PANEL := Color(0.05, 0.05, 0.06, 0.92)
const DIM := Color(0, 0, 0, 0.72)
const PAPER := Color(0.88, 0.84, 0.74)
const PAPER_INK := Color(0.12, 0.11, 0.10)

const UI_FONT := preload("res://game/ui/fonts/IBMPlexSans.ttf")
const TYPEWRITER_FONT := preload("res://game/ui/fonts/CourierPrime-Regular.ttf")
const TYPEWRITER_BOLD := preload("res://game/ui/fonts/CourierPrime-Bold.ttf")
const HANDWRITTEN_FONT := preload("res://game/ui/fonts/Caveat.ttf")

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = UI_FONT
	t.default_font_size = 28
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", ACCENT)
	t.set_color("font_focus_color", "Button", ACCENT)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", Color(0.4, 0.4, 0.4))
	t.set_stylebox("normal", "Button", _box(Color(0.12, 0.12, 0.13, 0.9), 2, Color(0.3, 0.3, 0.3)))
	t.set_stylebox("hover", "Button", _box(Color(0.18, 0.17, 0.15, 0.95), 2, ACCENT))
	t.set_stylebox("pressed", "Button", _box(Color(0.25, 0.22, 0.16, 0.95), 2, ACCENT))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), 2, ACCENT))
	t.set_stylebox("disabled", "Button", _box(Color(0.08, 0.08, 0.08, 0.8), 2, Color(0.2, 0.2, 0.2)))
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, 2, Color(0.25, 0.24, 0.22)))
	t.set_stylebox("panel", "Panel", _box(PANEL, 2, Color(0.25, 0.24, 0.22)))
	t.set_color("font_color", "ItemList", INK)
	t.set_stylebox("panel", "ItemList", _box(Color(0.08, 0.08, 0.09, 0.9), 1, Color(0.25, 0.25, 0.25)))
	t.set_stylebox("selected", "ItemList", _box(Color(0.3, 0.25, 0.15, 0.9), 0, ACCENT))
	t.set_stylebox("selected_focus", "ItemList", _box(Color(0.3, 0.25, 0.15, 0.9), 0, ACCENT))
	t.set_font_size("font_size", "ItemList", 26)
	t.set_stylebox("background", "ProgressBar", _box(Color(0.1, 0.1, 0.1, 0.9), 2, Color(0.35, 0.35, 0.35)))
	t.set_stylebox("fill", "ProgressBar", _box(ACCENT, 0, ACCENT))
	_theme = t
	return t


static func _box(bg: Color, border: int, border_color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(border)
	s.border_color = border_color
	s.set_content_margin_all(14)
	s.set_corner_radius_all(2)
	return s


## Full-screen dimmer that swallows mouse input underneath.
static func dimmer() -> ColorRect:
	var r := ColorRect.new()
	r.color = DIM
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r


static func label(text_key: String, size := 28, color := INK) -> Label:
	var l := Label.new()
	l.text = text_key
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text_key: String, on_pressed: Callable, size := 28) -> Button:
	var b := Button.new()
	b.text = text_key
	b.add_theme_font_size_override("font_size", size)
	b.pressed.connect(on_pressed)
	return b


## Panel of at least the given size, centered in parent (which should fill the screen).
## Returns the inner VBox.
static func centered_panel(parent: Control, size: Vector2) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = size
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	return box


static func font_for(style: DocumentData.Style) -> Font:
	match style:
		DocumentData.Style.HANDWRITTEN, DocumentData.Style.NOTE:
			return HANDWRITTEN_FONT
		DocumentData.Style.NOTICE:
			return TYPEWRITER_BOLD
	return TYPEWRITER_FONT
