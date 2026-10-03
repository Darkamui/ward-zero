extends TestCase
## Exercise actual GUI input routing, persistence and the seeded solve/reward path.

var _host: PuzzleHost
var _tree: SceneTree


func before_each() -> void:
	_tree = Engine.get_main_loop() as SceneTree
	_host = PuzzleHost.new()
	_tree.root.add_child(_host)
	Seed.set_seed(12345)
	_host.open(&"P01")


func after_each() -> void:
	_host.close()
	_host.queue_free()


func test_radio_keyboard_persists_and_reopens() -> void:
	await _tree.process_frame
	_key(KEY_RIGHT, true)
	_key(KEY_RIGHT, false)
	_key(KEY_PAGEUP, true)
	_key(KEY_PAGEUP, false)
	assert_eq(_host.current.logic.dial, 661.0)
	assert_false(GameState.is_puzzle_solved("P01"))
	_host.close()
	await _tree.process_frame
	_host.open(&"P01")
	await _tree.process_frame
	assert_eq(_host.current.logic.dial, 661.0, "close and reopen retains tuning")
	_key(KEY_END, true)
	_key(KEY_END, false)
	_key(KEY_RIGHT, true)
	_key(KEY_RIGHT, false)
	assert_eq(_host.current.logic.dial, P01Logic.DIAL_MAX, "keyboard clamps to scale")
	_key(KEY_HOME, true)
	_key(KEY_HOME, false)
	assert_eq(_host.current.logic.dial, P01Logic.DIAL_MIN)


func test_radio_knobs_drag_and_sync_without_jumping() -> void:
	await _tree.process_frame
	var coarse: Control = _host.current._controls[1]
	var at := coarse.global_position + coarse.size * 0.5
	_mouse(at, true)
	assert_eq(_host.current.logic.dial, 650.0, "knob click keeps current frequency")
	_motion(at + Vector2(20, 0))
	_mouse(at + Vector2(20, 0), false)
	assert_eq(_host.current.logic.dial, 730.0, "coarse drag")
	var fine: Control = _host.current._controls[2]
	at = fine.global_position + fine.size * 0.5
	_mouse(at, true)
	_motion(at + Vector2(3, 0))
	_mouse(at + Vector2(3, 0), false)
	assert_eq(_host.current.logic.dial, 733.0, "fine drag")
	for control in _host.current._controls:
		assert_eq(control.value, 733.0, "all indicators share the same dial")


func test_radio_solves_only_on_release_and_rewards_once() -> void:
	await _tree.process_frame
	var l := _host.current.logic as P01Logic
	var scale: Control = _host.current._controls[0]
	var target_x := 14.0 + (l.frequency() - 530.0) / 1170.0 * (scale.size.x - 28.0)
	var at := scale.global_position + Vector2(target_x, 60)
	_mouse(at, true)
	assert_true(l.is_tuned())
	assert_false(GameState.is_puzzle_solved("P01"), "holding needle does not submit")
	var solved_events := [0]
	_host.current.solved.connect(func() -> void: solved_events[0] += 1)
	_mouse(at, false)
	assert_true(GameState.is_puzzle_solved("P01"))
	assert_true(GameState.get_flag("g01.chain_released"))
	_key(KEY_ENTER, true)
	_key(KEY_ENTER, false)
	assert_eq(solved_events[0], 1, "repeated input cannot repeat rewards")
	await _tree.create_timer(1.1).timeout
	assert_false(_host.is_open(), "solved radio closes automatically")


func test_radio_easy_marker_uses_seed_and_normal_hides_it() -> void:
	assert_eq(_host.current._controls[0].easy_frequency, -1)
	_host.close()
	await _tree.process_frame
	GameState.set_difficulty("patient", "easy")
	_host.open(&"P01")
	assert_eq(_host.current._controls[0].easy_frequency, _host.current.logic.frequency())


func test_radio_keyboard_focus_and_station_release() -> void:
	await _tree.process_frame
	_key(KEY_TAB, true)
	_key(KEY_TAB, false)
	assert_true(_host.current._controls[1].has_focus(), "Tab reaches coarse knob")
	_key(KEY_TAB, true)
	_key(KEY_TAB, false)
	assert_true(_host.current._controls[2].has_focus(), "Tab reaches fine knob")
	var l := _host.current.logic as P01Logic
	# Hold Right until the seeded frequency, then release once to submit.
	_key(KEY_HOME, true)
	_key(KEY_HOME, false)
	for i in range(l.frequency() - int(P01Logic.DIAL_MIN)):
		_key(KEY_RIGHT, true)
	assert_true(l.is_tuned())
	assert_false(GameState.is_puzzle_solved("P01"))
	_key(KEY_RIGHT, false)
	assert_true(GameState.is_puzzle_solved("P01"), "keyboard release solves")
	await _tree.create_timer(1.1).timeout
	assert_false(_host.is_open())


func test_radio_pointer_capture_clamps_outside_scale() -> void:
	await _tree.process_frame
	var scale: Control = _host.current._controls[0]
	var at := scale.global_position + Vector2(30, 60)
	_mouse(at, true)
	_motion(at + Vector2(1500, 200))
	assert_eq(_host.current.logic.dial, P01Logic.DIAL_MAX)
	_mouse(at + Vector2(1500, 200), false)
	_motion(at)
	assert_eq(_host.current.logic.dial, P01Logic.DIAL_MAX, "release outside ends the drag")


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	_tree.root.push_input(event, true)


func _mouse(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	_tree.root.push_input(event, true)


func _motion(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	_tree.root.push_input(event, true)
