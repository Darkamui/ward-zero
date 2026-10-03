extends RoomTestBase

var voice: TapePlayer
var _original_locale := ""


func before_each() -> void:
	super.before_each()
	_original_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	voice = TapePlayer.new()
	world.add_child(voice)


func after_each() -> void:
	tree().paused = false
	voice.stop()
	TranslationServer.set_locale(_original_locale)
	super.after_each()


func test_theme_unlocks_on_chase_return_and_restores_on_reentry() -> void:
	load_room(&"G01", &"spawn_start")
	assert_true(AudioDirector.music_stream == null, "opening remains room tone only")
	GameState.set_flag("act1.chase_done", true)
	await wait(1.3)
	var music := AudioDirector._music
	assert_true(music.playing)
	assert_eq(music.bus, &"Music")
	assert_true(music.stream.loop)
	var position := music.get_playback_position()
	CameraDirector.cut_to(&"cam_b")
	GameState.set_flag("unrelated", true)
	assert_true(music.get_playback_position() >= position)
	RoomManager.set_timeline(true)
	await wait(.6)
	assert_false(music.playing)
	RoomManager.set_timeline(false)
	assert_true(music.playing)
	load_room(&"G02", &"spawn_from_g01")
	await wait(.6)
	assert_false(music.playing)
	load_room(&"G01", &"spawn_from_g02")
	assert_true(music.playing, "saved flag restores theme")
	AudioDirector.clear_room_audio()
	assert_false(music.playing)


func test_voice_ducks_music_and_pause_resumes_both() -> void:
	GameState.set_flag("act1.chase_done", true)
	load_room(&"G01", &"spawn_start")
	await wait(1.3)
	voice.play(&"tape_01_claire")
	await wait(.3)
	assert_eq(voice._player.bus, &"Voice")
	assert_eq(AudioDirector._music.volume_db, AudioDirector.MUSIC_DB - 9.0)
	tree().paused = true
	var time := voice._time
	await wait(.2)
	assert_eq(voice._time, time, "subtitle clock pauses with audio")
	assert_true(voice._player.stream_paused)
	assert_true(AudioDirector._music.stream_paused)
	tree().paused = false
	voice.stop()
	await wait(.9)
	assert_eq(AudioDirector._music.volume_db, AudioDirector.MUSIC_DB)
	voice.play(&"tape_01_claire")
	world.remove_child(voice)
	assert_true(AudioDirector._speakers.is_empty(), "freeing overlay releases ducking")
	world.add_child(voice)


func test_locale_switch_restarts_same_line_and_recomputes_duration() -> void:
	voice.play(&"tape_01_claire")
	var english := voice._player.stream
	var lines := voice.tape.subtitles_for("en")
	voice._time = lines[1].start + .5
	TranslationServer.set_locale("fr_CA")
	await tree().process_frame
	assert_ne(voice._player.stream, english)
	assert_eq(voice._player.stream, voice.tape.audio_for("fr_CA"))
	assert_between(
		voice._time,
		voice.tape.subtitles_for("fr_CA")[1].start,
		voice.tape.subtitles_for("fr_CA")[1].start + .2
	)
	assert_eq(voice._duration, voice._player.stream.get_length())
	assert_eq(voice.tape.subtitles_for("fr_FR"), voice.tape.subtitles_for("fr_CA"))


func test_subtitle_only_tape_stops_previous_voice() -> void:
	voice.play(&"tape_01_claire")
	assert_true(voice._player.playing)
	var silent: TapeData
	for id in ContentDB.tapes:
		var candidate := ContentDB.get_tape(id)
		if candidate.audio.is_empty():
			silent = candidate
			break
	assert_true(silent != null)
	voice.play(silent.id)
	assert_false(voice._player.playing)
	assert_true(voice._player.stream == null)
	assert_true(AudioDirector._speakers.is_empty())
	assert_true(voice.is_playing(), "subtitle-only playback remains supported")


func test_localized_clips_end_and_radio_does_not_enter_files() -> void:
	for locale in ["en", "fr_CA"]:
		TranslationServer.set_locale(locale)
		voice.play(&"vo_p01_radio")
		assert_false(GameState.tapes.has("vo_p01_radio"))
		assert_eq(voice.tape.subtitles_for(locale)[0].key, "tape.vo_p01_radio.line2")
		assert_eq(voice.tape.subtitles_for(locale)[0].start, 0.0, "chain caption matches immediate reward")
		# Audio mix completion is reported on the audio thread, after the last buffer.
		await wait(voice._duration + .5)
		assert_false(voice.is_playing(), "localized recording finishes: %s" % locale)
		assert_false(voice._panel.visible, "subtitle panel clears: %s" % locale)
	assert_true(AudioDirector._speakers.is_empty())
