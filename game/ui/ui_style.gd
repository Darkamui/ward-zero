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
const ICONS := {
	"eye": preload("res://assets/icons/eye-ivory.svg"),
	"hand": preload("res://assets/icons/hand-ivory.svg"),
	"combine": preload("res://assets/icons/combine-ivory.svg"),
	"folder": preload("res://assets/icons/folder-ivory.svg"),
	"key": preload("res://assets/icons/key-ivory.svg"),
	"cassette": preload("res://assets/icons/cassette-ivory.svg"),
	"back": preload("res://assets/icons/back-ivory.svg"),
	"exit": preload("res://assets/icons/exit-ivory.svg"),
	"play": preload("res://assets/icons/play-ivory.svg"),
}
const PAPER_ICONS := {
	"eye": preload("res://assets/icons/eye-ink.svg"),
	"folder": preload("res://assets/icons/folder-ink.svg"),
	"cassette": preload("res://assets/icons/cassette-ink.svg"),
	"play": preload("res://assets/icons/play-ink.svg"),
}
const BUTTON_ICONS := {
	"ui.common.back": "back",
	"puzzle.common.back": "back",
	"ui.inventory.examine": "eye",
	"ui.inventory.use": "hand",
	"ui.inventory.combine": "combine",
	"ui.inventory.drop": "exit",
	"ui.inventory.key_pouch": "key",
	"ui.bin.store": "folder",
	"ui.bin.take": "hand",
	"ui.files.documents": "folder",
	"ui.files.fragments": "folder",
	"ui.files.tapes": "cassette",
	"ui.files.read": "eye",
	"ui.files.play": "play",
}

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
	b.pressed.connect(AudioDirector.play_ui_click)
	if BUTTON_ICONS.has(text_key):
		b.icon = ICONS[BUTTON_ICONS[text_key]]
		b.add_theme_constant_override("h_separation", 10)
	return b


static func paper_button(text_key: String, on_pressed: Callable, size := 26) -> Button:
	var b := button(text_key, on_pressed, size)
	if BUTTON_ICONS.has(text_key):
		b.icon = PAPER_ICONS.get(BUTTON_ICONS[text_key])
	for state in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		b.add_theme_color_override(state, PAPER_INK)
	b.add_theme_stylebox_override("normal", _box(Color(0, 0, 0, 0), 1, Color(0.4, 0.3, 0.2, 0.4)))
	b.add_theme_stylebox_override("hover", _box(Color(1, 1, 1, 0.2), 2, PAPER_INK))
	b.add_theme_stylebox_override("pressed", _box(Color(0.3, 0.2, 0.1, 0.18), 2, PAPER_INK))
	b.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), 2, PAPER_INK))
	return b


static func artwork(texture: Texture2D, at: Vector2, dimensions: Vector2) -> TextureRect:
	var art := TextureRect.new()
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture = texture
	art.position = at
	art.size = dimensions
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


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
