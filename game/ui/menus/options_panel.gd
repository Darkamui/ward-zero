class_name OptionsPanel
extends Control
## Options (GDD §11-12): language at any time, subtitles, volumes, door animation,
## fullscreen. Every change applies and saves immediately through Settings.

signal closed

var _box: VBoxContainer


func _ready() -> void:
	theme = UiStyle.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if not get_parent() is Control:
		size = get_viewport_rect().size
	add_child(UiStyle.dimmer())
	_box = UiStyle.centered_panel(self, Vector2(1100, 900))
	_build()


func _build() -> void:
	for c in _box.get_children():
		c.queue_free()
	_box.add_child(UiStyle.label("ui.options.title", 40, UiStyle.ACCENT))
	var lang := HBoxContainer.new()
	lang.add_child(UiStyle.label("ui.options.language", 28))
	for locale in Settings.LOCALES:
		var b := UiStyle.button("ui.options.lang_%s" % locale.to_lower(), _set_option.bind("locale", locale))
		b.disabled = Settings.get_value("locale") == locale
		lang.add_child(b)
	_box.add_child(lang)
	_box.add_child(_toggle("ui.options.subtitles", "subtitles"))
	var size_row := HBoxContainer.new()
	size_row.add_child(UiStyle.label("ui.options.subtitle_size", 28))
	for s in Settings.SUBTITLE_SIZES:
		var b := UiStyle.button("ui.options.size_%s" % s, _set_option.bind("subtitle_size", s))
		b.disabled = Settings.get_value("subtitle_size") == s
		size_row.add_child(b)
	_box.add_child(size_row)
	_box.add_child(_toggle("ui.options.subtitle_background", "subtitle_background"))
	for bus in ["Master", "Music", "Ambience", "SFX", "Voice"]:
		var row := HBoxContainer.new()
		var l := UiStyle.label("ui.options.volume_%s" % bus.to_lower(), 26)
		l.custom_minimum_size = Vector2(380, 0)
		row.add_child(l)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.custom_minimum_size = Vector2(500, 40)
		slider.value = Settings.get_value("volume_" + bus)
		slider.value_changed.connect(func(v: float) -> void: Settings.set_value("volume_" + bus, v))
		row.add_child(slider)
		_box.add_child(row)
	_box.add_child(_toggle("ui.options.skip_door", "skip_door_animation"))
	_box.add_child(_toggle("ui.options.fullscreen", "fullscreen"))
	_box.add_child(UiStyle.label("ui.options.storage_warning", 22, UiStyle.INK_DIM))
	_box.add_child(UiStyle.button("ui.common.back", _close))


func _toggle(label_key: String, key: String) -> CheckButton:
	var c := CheckButton.new()
	c.text = label_key
	c.button_pressed = bool(Settings.get_value(key))
	c.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	return c


func _set_option(key: String, value: Variant) -> void:
	Settings.set_value(key, value)
	_build.call_deferred()


func _close() -> void:
	closed.emit()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") or InventoryUi._is_right_click(event):
		get_viewport().set_input_as_handled()
		_close()
