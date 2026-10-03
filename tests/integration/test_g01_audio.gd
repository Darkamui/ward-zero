extends RoomTestBase


func after_each() -> void:
	tree().paused = false
	super.after_each()


func test_ambience_tracks_room_camera_and_timeline() -> void:
	load_room(&"G01", &"spawn_start")
	var stream := ContentDB.get_room(&"G01").ambience_present
	assert_eq(AudioDirector.ambience_stream, stream)
	await wait(0.6)
	var voice: AudioStreamPlayer = AudioDirector._ambience[AudioDirector._active]
	assert_true(voice.playing)
	assert_eq(voice.bus, &"Ambience")
	assert_true(voice.stream.loop)
	var playback := voice.get_playback_position()
	CameraDirector.cut_to(&"cam_b")
	AudioDirector.play_ambience(stream)
	assert_true(voice.get_playback_position() >= playback, "same ambience and camera cuts do not restart")
	RoomManager.set_timeline(true)
	await wait(0.6)
	assert_true(AudioDirector.ambience_stream == null, "missing memory ambience is silent")
	for entry in AudioDirector._ambience:
		assert_false(entry.playing)
	RoomManager.set_timeline(false)
	await wait(0.6)
	assert_eq(AudioDirector.ambience_stream, stream)
	load_room(&"G02", &"spawn_from_g01")
	await wait(0.6)
	for entry in AudioDirector._ambience:
		assert_false(entry.playing, "no dayroom hum in another room")


func test_rapid_ambience_changes_and_cleanup_stop_every_voice() -> void:
	var stream := ContentDB.get_room(&"G01").ambience_present
	AudioDirector.play_ambience(stream)
	AudioDirector.play_ambience(preload("res://assets/audio/electrical_hum_loop.wav"))
	AudioDirector.play_ambience(null)
	await wait(0.6)
	for entry in AudioDirector._ambience:
		assert_false(entry.playing)
	AudioDirector.play_ambience(stream)
	AudioDirector.play_sfx(AudioDirector.PAPER)
	AudioDirector.clear_room_audio()
	for entry in AudioDirector._ambience + AudioDirector._voices:
		assert_false(entry.playing)
	assert_true(AudioDirector.ambience_stream == null)


func test_radio_static_follows_signal_and_solve_is_once() -> void:
	var host := PuzzleHost.new()
	tree().root.add_child(host)
	host.open(&"P01")
	await tree().process_frame
	var radio := host.current
	var logic := radio.logic as P01Logic
	assert_true(radio._static.playing)
	assert_eq(radio._static.bus, &"SFX")
	assert_eq(radio._static.stream.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	radio._on_dial(P01Logic.DIAL_MAX)
	var off_station: float = radio._static.volume_db
	radio._on_dial(logic.frequency())
	assert_true(radio._static.volume_db < off_station - 20.0)
	var sounds: Array[AudioStream] = []
	var collect := func(stream: AudioStream) -> void: sounds.append(stream)
	EventBus.sfx_requested.connect(collect)
	radio._on_release()
	radio._on_release()
	EventBus.sfx_requested.disconnect(collect)
	assert_eq(sounds.size(), 1, "chain release occurs once per solve")
	assert_false(radio._static.playing)
	assert_true(GameState.get_flag("g01.chain_released"))
	host.close()
	await wait(1.1)
	host.open(&"P01")
	await tree().process_frame
	assert_false(host.current._static.playing, "restored solved radio stays quiet")
	host.close()
	host.queue_free()


func test_closing_unsolved_radio_frees_its_loop() -> void:
	var host := PuzzleHost.new()
	tree().root.add_child(host)
	host.open(&"P01")
	var radio_voice: AudioStreamPlayer = host.current._static
	host.close()
	await tree().process_frame
	await tree().process_frame
	assert_false(is_instance_valid(radio_voice))
	host.queue_free()


func test_ui_works_while_paused_and_sound_pool_is_bounded() -> void:
	AudioDirector.play_ambience(ContentDB.get_room(&"G01").ambience_present)
	await wait(0.6)
	tree().paused = true
	var button := UiStyle.button("ui.common.back", func() -> void: pass)
	world.add_child(button)
	var index: int = AudioDirector._voice_index
	button.pressed.emit()
	var voice: AudioStreamPlayer = AudioDirector._voices[index]
	assert_eq(voice.bus, &"UI")
	assert_eq(voice.stream, AudioDirector.CLICK)
	assert_true(voice.playing)
	assert_true(AudioDirector._ambience[AudioDirector._active].stream_paused)
	for i in 40:
		EventBus.sfx_requested.emit(AudioDirector.PAPER)
	assert_eq(AudioDirector._voices.size(), AudioDirector.MAX_VOICES)
	assert_eq(AudioDirector._voices[(AudioDirector._voice_index + 11) % 12].bus, &"SFX")
	tree().paused = false


func test_walk_uses_foley_but_stop_and_teleport_do_not() -> void:
	var room := load_room(&"G01", &"spawn_start")
	await wait_nav_sync(room)
	player.global_position = Vector3(-2.5, 0, -1)
	player.walk_to(Vector3(-1, 0, -1))
	for i in 150:
		if AudioDirector._step_index > 0:
			break
		await tree().physics_frame
	assert_true(AudioDirector._step_index > 0, "real movement triggers a footstep")
	player.stop()
	var index: int = AudioDirector._step_index
	await wait(0.3)
	assert_eq(AudioDirector._step_index, index)
	player.teleport(room.get_spawn(&"spawn_start"))
	await wait(0.2)
	assert_eq(AudioDirector._step_index, index)
