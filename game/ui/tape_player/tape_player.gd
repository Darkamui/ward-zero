class_name TapePlayer
extends CanvasLayer
## Plays tapes and VO lines (EventBus.tape_requested) with timed subtitles (GDD §10, §12).
## Audio is chosen for the current language; without audio the subtitle timings still run,
## so tapes work before their recordings exist. Listed tapes are added to Files.
## Switching language mid-tape restarts the current line in the new language.

signal finished(tape_id: StringName)

var tape: TapeData
var _player: AudioStreamPlayer
var _time := 0.0
var _duration := 0.0
var _panel: PanelContainer
var _label: Label
var _locale := ""


func _ready() -> void:
	layer = 15
	_player = AudioStreamPlayer.new()
	_player.bus = &"Voice"
	add_child(_player)
	_panel = PanelContainer.new()
	_panel.theme = UiStyle.theme()
	_panel.anchor_left = 0.1
	_panel.anchor_right = 0.9
	_panel.anchor_top = 0.86
	_panel.anchor_bottom = 0.86
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = Label.new()
	_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.add_child(_label)
	_panel.visible = false
	EventBus.tape_requested.connect(play)
	Settings.changed.connect(func(_k: String) -> void: _apply_style())
	_apply_style()


func play(tape_id: StringName) -> void:
	var t: TapeData = ContentDB.get_tape(tape_id)
	if t == null:
		push_error("TapePlayer: unknown tape %s" % tape_id)
		return
	tape = t
	if t.listed_in_files:
		AudioDirector.play_sfx(AudioDirector.CASSETTE, -12.0)
		GameState.add_tape(String(t.id))
	_time = 0.0
	_locale = TranslationServer.get_locale()
	_start_audio(0.0)


func stop() -> void:
	if tape == null:
		return
	var id := tape.id
	tape = null
	_player.stop()
	AudioDirector.set_voice_active(self, false)
	_panel.visible = false
	finished.emit(id)


func is_playing() -> bool:
	return tape != null


func current_line_text() -> String:
	return _label.text if _panel.visible else ""


func _start_audio(from: float) -> void:
	_player.stop()
	_duration = 0.0
	for line in tape.subtitles_for(_locale):
		_duration = maxf(_duration, line.end)
	var stream := tape.audio_for(_locale)
	_player.stream = stream
	if stream:
		_player.play(from)
		_duration = maxf(_duration, stream.get_length())
	AudioDirector.set_voice_active(self, stream != null)


func _process(delta: float) -> void:
	if tape == null:
		return
	_time += delta
	var text := ""
	if Settings.get_value("subtitles"):
		for line in tape.subtitles_for(TranslationServer.get_locale()):
			if _time >= line.start and _time < line.end:
				text = tr(line.key)
	_label.text = text
	_panel.visible = text != ""
	if _time >= _duration and not _player.playing:
		stop()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and tape:
		var line_key := ""
		for line in tape.subtitles_for(_locale):
			if _time >= line.start:
				line_key = line.key
		_locale = TranslationServer.get_locale()
		var line_start := 0.0
		for line in tape.subtitles_for(_locale):
			if line.key == line_key:
				line_start = line.start
		_time = line_start
		_start_audio(line_start)


func _exit_tree() -> void:
	AudioDirector.set_voice_active(self, false)


func _apply_style() -> void:
	_label.add_theme_font_size_override("font_size", Settings.subtitle_font_size())
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.75 if Settings.get_value("subtitle_background") else 0.0)
	bg.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", bg)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 0 if Settings.get_value("subtitle_background") else 8)
