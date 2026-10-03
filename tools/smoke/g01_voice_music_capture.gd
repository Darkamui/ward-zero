extends RefCounted
## Real engine mix, temporary bus levels, no saved settings or save writes.

const OUT := "res://production/art-review/g01_voice_music"
var _tree: SceneTree
var _events: Array[Dictionary] = []
var _start := 0


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	_tree = tree
	GameState.reset()
	Seed.set_seed(12345)
	var locale := TranslationServer.get_locale()
	TranslationServer.set_locale("en")
	var gains: Array[float] = []
	for i in AudioServer.bus_count:
		gains.append(AudioServer.get_bus_volume_db(i))
		AudioServer.set_bus_volume_db(i, 0.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Ambience"), linear_to_db(.9))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), linear_to_db(.8))
	var recorder := AudioEffectRecord.new()
	var effect_index := AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0, recorder)
	var world := Node3D.new()
	tree.root.add_child(world)
	var player := load("res://game/core/player/player.tscn").instantiate() as Player
	world.add_child(player)
	var voice := TapePlayer.new()
	world.add_child(voice)
	var host := PuzzleHost.new()
	world.add_child(host)
	RoomManager.setup(world, player)
	RoomManager.load_room_now(ContentDB.get_room(&"G01"), &"spawn_start")
	recorder.set_recording_active(true)
	_start = Time.get_ticks_msec()
	_mark("English opening with room tone")
	voice.play(&"tape_01_claire")
	await _wait(voice._duration + .5)
	_mark("English radio solve, immediate chain then calm voice")
	host.open(&"P01")
	var radio := host.current
	radio._on_dial((radio.logic as P01Logic).frequency())
	radio._on_release()
	await _wait(voice._duration + .5)
	host.close()
	_mark("Post-chase return unlocks theme")
	GameState.set_flag("act1.chase_done", true)
	await _wait(7)
	TranslationServer.set_locale("fr_CA")
	_mark("French Claire; music lowers under voice")
	voice.play(&"tape_01_claire")
	await _wait(voice._duration + 1.5)
	_mark("French radio; music lowers under voice")
	voice.play(&"vo_p01_radio")
	AudioDirector.play_sfx(preload("res://game/audio/g01/chain_release.wav"))
	await _wait(voice._duration + 2)
	_mark("World cleanup: silence")
	voice.stop()
	CameraDirector.unregister_room()
	RoomManager.current = null
	RoomManager.setup(null, null)
	await _wait(.8)
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	var error := recording.save_to_wav(OUT.path_join("gameplay-mix.wav"))
	AudioServer.remove_bus_effect(0, effect_index)
	for i in gains.size():
		AudioServer.set_bus_volume_db(i, gains[i])
	TranslationServer.set_locale(locale)
	var log := FileAccess.open(OUT.path_join("capture-timeline.json"), FileAccess.WRITE)
	log.store_string(JSON.stringify(_events, "\t") + "\n")
	log.close()
	world.queue_free()
	await tree.process_frame
	print("g01_voice_music_capture: ", recording.get_length(), " seconds; save status ", error)
	return 0 if error == OK and recording.get_length() > 25 else 1


func _wait(seconds: float) -> void:
	await _tree.create_timer(seconds).timeout


func _mark(label: String) -> void:
	_events.append({"seconds": (Time.get_ticks_msec() - _start) / 1000.0, "event": label})
