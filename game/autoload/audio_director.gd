extends Node
## Shared playback and room ambience. Gameplay noise propagation remains on EventBus.

const CLICK := preload("res://game/audio/g01/ui_click.wav")
const SATCHEL := preload("res://game/audio/g01/satchel.wav")
const FOLDER := preload("res://game/audio/g01/folder.wav")
const PAPER := preload("res://game/audio/g01/paper.wav")
const DOOR := preload("res://game/audio/g01/door_close.wav")
const CASSETTE := preload("res://assets/audio/cassette_transport.wav")
const STEPS := [
	preload("res://game/audio/g01/step_1.wav"),
	preload("res://game/audio/g01/step_2.wav"),
	preload("res://game/audio/g01/step_3.wav"),
	preload("res://game/audio/g01/step_4.wav"),
]
const MAX_VOICES := 12
const AMBIENCE_DB := -9.0
const MUSIC_DB := -10.0

var ambience_stream: AudioStream
var music_stream: AudioStream
var _ambience: Array[AudioStreamPlayer] = []
var _voices: Array[AudioStreamPlayer] = []
var _pans: Array[AudioStreamPlayer2D] = []
var _fade: Tween
var _active := 0
var _voice_index := 0
var _step_index := 0
var _music: AudioStreamPlayer
var _music_fade: Tween
var _speakers: Dictionary[int, bool] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.bus = &"Music"
	_music.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_music)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = &"Ambience"
		player.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(player)
		_ambience.append(player)
	for i in MAX_VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_voices.append(player)
	for i in 4:
		var player := AudioStreamPlayer2D.new()
		player.bus = &"SFX"
		player.attenuation = 0.0
		player.max_distance = 4000.0
		add_child(player)
		_pans.append(player)
	EventBus.sfx_requested.connect(play_sfx)
	EventBus.ui_opened.connect(_on_ui_opened)
	EventBus.ui_closed.connect(_on_ui_closed)


func play_sfx(stream: AudioStream, gain_db := -6.0, bus := &"SFX") -> void:
	if stream == null:
		return
	var voice := _voices[_voice_index]
	_voice_index = (_voice_index + 1) % MAX_VOICES
	voice.stop()
	voice.stream = stream
	voice.bus = bus
	voice.volume_db = gain_db
	voice.pitch_scale = 1.0
	voice.play()


func play_ui_click() -> void:
	play_sfx(CLICK, -8.0, &"UI")


func play_footstep(running: bool) -> void:
	# Only the dayroom surface has been selected/mixed in this asset pass.
	if GameState.current_room != "G01":
		return
	play_sfx(STEPS[_step_index], -5.0 if running else -10.0)
	_step_index = (_step_index + 1) % STEPS.size()


static func looped(stream: AudioStream) -> AudioStream:
	var copy := stream.duplicate() as AudioStream
	if copy is AudioStreamOggVorbis:
		copy.loop = true
	elif copy is AudioStreamWAV:
		copy.loop_mode = AudioStreamWAV.LOOP_FORWARD
		copy.loop_begin = 0
		copy.loop_end = roundi(copy.get_length() * copy.mix_rate)
	return copy


func play_ambience(stream: AudioStream) -> void:
	if stream == ambience_stream:
		return
	ambience_stream = stream
	if _fade:
		_fade.kill()
	_fade = create_tween().set_parallel(true)
	var previous := _ambience[_active]
	_fade.tween_property(previous, "volume_db", -60.0, 0.4)
	if stream:
		_active = 1 - _active
		var next := _ambience[_active]
		next.stop()
		next.stream = looped(stream)
		next.volume_db = -60.0
		next.play()
		_fade.parallel().tween_property(next, "volume_db", AMBIENCE_DB, 0.5)
	else:
		# A rapid change can leave both crossfade voices alive; silence both.
		var other := _ambience[1 - _active]
		_fade.parallel().tween_property(other, "volume_db", -60.0, 0.4)
		_fade.chain().tween_callback(other.stop)
	_fade.chain().tween_callback(previous.stop)


func clear_room_audio() -> void:
	if _fade:
		_fade.kill()
	if _music_fade:
		_music_fade.kill()
	music_stream = null
	_music.stop()
	ambience_stream = null
	for voice in _ambience + _voices:
		voice.stop()
	for voice in _pans:
		voice.stop()
	_step_index = 0


func play_music(stream: AudioStream) -> void:
	if stream == music_stream:
		return
	music_stream = stream
	if _music_fade:
		_music_fade.kill()
	_music_fade = create_tween()
	if stream:
		_music.stop()
		_music.stream = looped(stream)
		_music.volume_db = -60.0
		_music.play()
		_music_fade.tween_property(_music, "volume_db", _music_gain(), 1.2)
	else:
		_music_fade.tween_property(_music, "volume_db", -60.0, 0.5)
		_music_fade.tween_callback(_music.stop)


func set_voice_active(source: Node, active: bool) -> void:
	if active:
		_speakers[source.get_instance_id()] = true
	else:
		_speakers.erase(source.get_instance_id())
	if music_stream:
		if _music_fade:
			_music_fade.kill()
		_music_fade = create_tween()
		_music_fade.tween_property(_music, "volume_db", _music_gain(), 0.2 if active else 0.8)


func _music_gain() -> float:
	return MUSIC_DB - (9.0 if not _speakers.is_empty() else 0.0)


## side: -1.0 = left, 0.0 = centre, 1.0 = right of the current shot.
func play_positional_cue(stream: AudioStream, side: float) -> void:
	if stream == null:
		return
	var voice := _pans[0]
	for candidate in _pans:
		if not candidate.playing:
			voice = candidate
			break
	voice.stop()
	voice.stream = stream
	voice.volume_db = -6.0
	var viewport_size := get_viewport().get_visible_rect().size
	voice.position = viewport_size * 0.5 + Vector2(clampf(side, -1, 1) * viewport_size.x * 0.5, 0)
	voice.play()


func _on_ui_opened(ui_name: StringName) -> void:
	match ui_name:
		&"inventory":
			play_sfx(SATCHEL, -8.0, &"UI")
		&"files":
			play_sfx(FOLDER, -8.0, &"UI")


func _on_ui_closed(ui_name: StringName) -> void:
	match ui_name:
		&"inventory":
			play_sfx(SATCHEL, -11.0, &"UI")
		&"files", &"document":
			play_sfx(PAPER, -13.0, &"UI")
