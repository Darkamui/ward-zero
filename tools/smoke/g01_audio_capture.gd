extends RefCounted
## Record the real game mix without changing saved settings or saves.

const OUT := "res://production/art-review/g01_audio"
var _tree: SceneTree
var _events: Array[Dictionary] = []
var _start := 0


func run(tree: SceneTree, _args: PackedStringArray) -> int:
	_tree = tree
	DirAccess.make_dir_recursive_absolute(OUT)
	GameState.reset()
	Seed.set_seed(12345)
	GameState.set_flag("intro.done")
	var gains: Array[float] = []
	for i in AudioServer.bus_count:
		gains.append(AudioServer.get_bus_volume_db(i))
		AudioServer.set_bus_volume_db(i, 0.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"UI"), linear_to_db(0.8))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Ambience"), linear_to_db(0.9))
	var recorder := AudioEffectRecord.new()
	var effect_index := AudioServer.get_bus_effect_count(0)
	AudioServer.add_bus_effect(0, recorder)
	recorder.set_recording_active(true)
	_start = Time.get_ticks_msec()
	var world := Node3D.new()
	tree.root.add_child(world)
	var player := load("res://game/core/player/player.tscn").instantiate() as Player
	world.add_child(player)
	RoomManager.setup(world, player)
	RoomManager.load_room_now(ContentDB.get_room(&"G01"), &"spawn_start")
	_mark("Dayroom room tone")
	await _wait(2.0)
	player.global_position = Vector3(-2.5, 0, -1)
	player.walk_to(Vector3(-0.5, 0, -1))
	_mark("Walk on dayroom floor")
	await _wait(1.8)
	player.stop()
	var inventory := InventoryUi.new()
	var reader := DocumentViewer.new()
	var files := FilesUi.new()
	var host := PuzzleHost.new()
	for ui in [inventory, reader, files, host]:
		tree.root.add_child(ui)
	_mark("Open and close satchel")
	inventory.open()
	await _wait(0.7)
	inventory.close()
	await _wait(0.5)
	_mark("Open Files and Quiet Hours")
	GameState.add_document("doc_quiet_hours")
	files.open()
	await _wait(0.5)
	reader.open(&"doc_quiet_hours")
	await _wait(0.8)
	reader.close()
	files.close()
	await _wait(0.6)
	_mark("Cassette transport starter effect")
	AudioDirector.play_sfx(AudioDirector.CASSETTE, -12.0)
	await _wait(0.7)
	_mark("Radio off station")
	host.open(&"P01")
	var radio := host.current
	radio._on_dial(P01Logic.DIAL_MAX)
	await _wait(1.5)
	_mark("Radio near station")
	radio._on_dial((radio.logic as P01Logic).frequency() + 25)
	await _wait(1.0)
	_mark("Radio tuned")
	radio._on_dial((radio.logic as P01Logic).frequency())
	await _wait(1.0)
	_mark("Solve: chain release, static stops")
	radio._on_release()
	await _wait(1.6)
	host.close()
	_mark("Leave world: silence")
	CameraDirector.unregister_room()
	RoomManager.current = null
	RoomManager.setup(null, null)
	await _wait(0.6)
	recorder.set_recording_active(false)
	var recording := recorder.get_recording()
	var error := recording.save_to_wav(OUT.path_join("gameplay-mix.wav"))
	AudioServer.remove_bus_effect(0, effect_index)
	for i in gains.size():
		AudioServer.set_bus_volume_db(i, gains[i])
	var log := FileAccess.open(OUT.path_join("capture-timeline.json"), FileAccess.WRITE)
	log.store_string(JSON.stringify(_events, "\t") + "\n")
	log.close()
	for ui in [inventory, reader, files, host]:
		ui.queue_free()
	world.queue_free()
	await tree.process_frame
	print("g01_audio_capture: ", recording.get_length(), " seconds; save status ", error)
	return 0 if error == OK and recording.get_length() > 10 else 1


func _wait(seconds: float) -> void:
	await _tree.create_timer(seconds).timeout


func _mark(label: String) -> void:
	_events.append({"seconds": (Time.get_ticks_msec() - _start) / 1000.0, "event": label})
