class_name OptionsPanel
extends Control
## All controls apply immediately through Settings, from both title and pause.

signal closed

const TABS := ["audio", "display", "accessibility"]
var _tab := "audio"
var _content: Control
var _rows: VBoxContainer
var _closing := false


func _ready() -> void:
	theme = UiStyle.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(UiStyle.dimmer())
	MenuStyle.backdrop(self, MenuStyle.BACKGROUND, 0.62)
	_build()
	MenuStyle.reveal(self)


func _build(focus_name := "Tab_audio") -> void:
	if _content:
		_content.hide()
		_content.queue_free()
	_content = Control.new()
	add_child(_content)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	MenuStyle.eyebrow(_content, "ui.front.preferences", Vector2(140, 105))
	MenuStyle.label_at(_content, "ui.options.title", Vector2(135, 145), 76)
	MenuStyle.label_at(_content, "ui.options.autosaved", Vector2(140, 260), 23, MenuStyle.MUTED)
	MenuStyle.rule(_content, Vector2(140, 325), 1640)
	var tabs := VBoxContainer.new()
	tabs.position = Vector2(140, 375)
	tabs.custom_minimum_size.x = 360
	tabs.add_theme_constant_override("separation", 15)
	_content.add_child(tabs)
	for tab in TABS:
		var b := MenuStyle.button("ui.options.tab_%s" % tab, _select_tab.bind(tab))
		b.name = "Tab_" + tab
		b.toggle_mode = true
		b.button_pressed = _tab == tab
		tabs.add_child(b)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(640, 370)
	scroll.size = Vector2(1140, 475)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 20)
	scroll.add_child(_rows)
	match _tab:
		"audio":
			for bus in ["Master", "Music", "Ambience", "SFX", "Voice", "UI"]:
				_slider("ui.options.volume_%s" % bus.to_lower(), "volume_" + bus)
		"display":
			_toggle("ui.options.fullscreen", "fullscreen")
			_toggle("ui.options.skip_door", "skip_door_animation")
			_toggle("ui.options.photosensitivity", "photosensitivity")
			var hint := UiStyle.label("ui.options.display_hint", 24, MenuStyle.MUTED)
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_rows.add_child(hint)
		"accessibility":
			_choices("ui.options.language", "locale", Settings.LOCALES, "ui.options.lang_")
			_toggle("ui.options.subtitles", "subtitles")
			_choices(
				"ui.options.subtitle_size",
				"subtitle_size",
				Settings.SUBTITLE_SIZES.keys(),
				"ui.options.size_"
			)
			_toggle("ui.options.subtitle_background", "subtitle_background")
			_subtitle_preview()
	var back := MenuStyle.button("ui.common.back", _close)
	back.name = "Back"
	back.position = Vector2(140, 870)
	back.size.x = 360
	_content.add_child(back)
	MenuStyle.paragraph(_content, "ui.options.storage_warning", Vector2(640, 875), 1100, 21)
	MenuStyle.footer(_content, "ui.front.navigation")
	var focus := _content.find_child(focus_name, true, false) as Control
	if focus:
		focus.grab_focus.call_deferred()


func _select_tab(tab: String) -> void:
	_tab = tab
	_build("Tab_" + tab)


func _row(key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 58
	row.add_theme_constant_override("separation", 20)
	var label := UiStyle.label(key, 27)
	label.custom_minimum_size.x = 370
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	_rows.add_child(row)
	return row


func _slider(label_key: String, key: String) -> void:
	var row := _row(label_key)
	var slider := HSlider.new()
	slider.name = key
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.custom_minimum_size = Vector2(380, 44)
	slider.value = Settings.get_value(key)
	for state in ["slider", "grabber_area", "grabber_area_highlight"]:
		var color := Color(0.42, 0.46, 0.42, 0.3) if state == "slider" else UiStyle.ACCENT
		var track := UiStyle._box(color, 0, Color.TRANSPARENT)
		track.set_content_margin_all(0)
		track.content_margin_top = 2
		track.content_margin_bottom = 2
		slider.add_theme_stylebox_override(state, track)
	row.add_child(slider)
	var value := UiStyle.label("", 24, UiStyle.ACCENT)
	value.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	value.custom_minimum_size.x = 90
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_override("font", UiStyle.TYPEWRITER_FONT)
	value.text = str(roundi(slider.value * 100)) + "%"
	row.add_child(value)
	slider.value_changed.connect(
		func(v: float) -> void:
			Settings.set_value(key, v)
			value.text = str(roundi(v * 100)) + "%"
	)


func _toggle(label_key: String, key: String) -> void:
	var row := _row(label_key)
	var button := MenuStyle.button(
		"ui.options.on" if Settings.get_value(key) else "ui.options.off", func() -> void: pass
	)
	button.name = key
	button.custom_minimum_size.x = 210
	button.toggle_mode = true
	button.button_pressed = bool(Settings.get_value(key))
	button.toggled.connect(
		func(on: bool) -> void:
			Settings.set_value(key, on)
			button.text = "ui.options.on" if on else "ui.options.off"
			if _tab == "accessibility":
				_build.call_deferred(key)
	)
	row.add_child(button)


func _choices(label_key: String, key: String, values: Array, prefix: String) -> void:
	var row := _row(label_key)
	for value in values:
		var button := MenuStyle.button(
			prefix + str(value).to_lower(), _set_option.bind(key, value), false, 24
		)
		button.name = key + "_" + str(value)
		button.toggle_mode = true
		button.button_pressed = Settings.get_value(key) == value
		row.add_child(button)


func _subtitle_preview() -> void:
	var panel := PanelContainer.new()
	var color := (
		Color(0.01, 0.015, 0.015, 0.85) if Settings.get_value("subtitle_background") else Color.TRANSPARENT
	)
	panel.add_theme_stylebox_override("panel", UiStyle._box(color, 0, Color.TRANSPARENT))
	var text := UiStyle.label("ui.options.preview", Settings.subtitle_font_size())
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(text)
	panel.visible = bool(Settings.get_value("subtitles"))
	_rows.add_child(panel)


func _set_option(key: String, value: Variant) -> void:
	Settings.set_value(key, value)
	_build.call_deferred(key + "_" + str(value))


func _close() -> void:
	if _closing:
		return
	_closing = true
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	# Handle Escape ahead of PauseMenu so one press closes only this overlay.
	if event.is_action_pressed(&"pause") or InventoryUi._is_right_click(event):
		get_viewport().set_input_as_handled()
		_close()
