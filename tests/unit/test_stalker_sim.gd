extends TestCase
## Room-graph stalker simulation (docs/03-milestone-2.md §3), on a synthetic graph:
##   S(safe, never) - A - B - C - A (ring), C - P(scripted puzzle room), B - D - E

var sim: StalkerSim
var tuning: StalkerTuning


func before_each() -> void:
	_room(&"S", RoomData.Access.NEVER, [&"A"])
	_room(&"A", RoomData.Access.OPEN, [&"B", &"C"])
	_room(&"B", RoomData.Access.OPEN, [&"C", &"D"])
	_room(&"C", RoomData.Access.OPEN, [&"P"])
	_room(&"P", RoomData.Access.SCRIPTED, [])
	_room(&"D", RoomData.Access.OPEN, [&"E"])
	_room(&"E", RoomData.Access.OPEN, [])
	tuning = StalkerTuning.new()
	tuning.walk_speed = 2.0
	tuning.search_time = 4.0
	tuning.hearing_bonus = 0
	sim = StalkerSim.new()
	sim.player_room = &"S"


func _room(id: StringName, access: RoomData.Access, links: Array) -> void:
	var r := RoomData.new()
	r.id = id
	r.access = access
	for l in links:
		var e := ExitDef.new()
		e.id = StringName("to_%s" % l)
		e.target_room = l
		r.exits.append(e)
	ContentDB.register_room(r)


func _run(seconds: float, step := 0.25) -> void:
	var t := 0.0
	while t < seconds:
		sim.tick(step)
		t += step


func test_patrols_the_route_in_order() -> void:
	var visited: Array[StringName] = []
	sim.arrived.connect(func(r: StringName) -> void: visited.append(r))
	sim.start([&"A", &"B", &"C"], tuning)
	_run(40.0)
	assert_true(visited.size() >= 6, "keeps moving: %s" % [visited])
	assert_eq(visited.slice(0, 4), [&"B", &"C", &"A", &"B"])


func test_never_enters_never_or_scripted_rooms() -> void:
	var visited: Array[StringName] = []
	sim.arrived.connect(func(r: StringName) -> void: visited.append(r))
	sim.start([&"A", &"B", &"C"], tuning)
	sim.hear(&"P", 3)
	_run(30.0)
	assert_false(visited.has(&"P"), "scripted room")
	assert_false(visited.has(&"S"), "safe room")


func test_hears_within_hops_and_investigates() -> void:
	sim.start([&"A", &"B", &"C"], tuning, &"A")
	assert_false(sim.hear(&"E", 2), "E is 3 hops from A")
	assert_true(sim.hear(&"E", 3))
	assert_eq(sim.state, StalkerSim.State.INVESTIGATE)
	var visited: Array[StringName] = []
	sim.arrived.connect(func(r: StringName) -> void: visited.append(r))
	_run(30.0)
	assert_has(visited, &"E")
	assert_true(sim.state == StalkerSim.State.SEARCH or sim.state == StalkerSim.State.PATROL)


func test_search_then_resume_patrol() -> void:
	sim.start([&"A", &"B", &"C"], tuning, &"D")
	sim.hear(&"D", 1)
	assert_eq(sim.state, StalkerSim.State.SEARCH, "noise in his own room: search at once")
	_run(3.5)
	assert_eq(sim.state, StalkerSim.State.SEARCH)
	_run(1.0)
	assert_eq(sim.state, StalkerSim.State.PATROL)


func test_hearing_bonus_and_composure_extra() -> void:
	sim.start([&"A", &"B", &"C"], tuning, &"A")
	assert_false(sim.hear(&"D", 1))
	tuning.hearing_bonus = 1
	assert_true(sim.hear(&"D", 1), "Committed +1 hop")
	sim.start([&"A", &"B", &"C"], tuning, &"A")
	tuning.hearing_bonus = 0
	sim.hearing_extra = 1
	assert_true(sim.hear(&"D", 1), "Breaking composure +1 hop")


func test_stops_at_the_players_door() -> void:
	sim.player_room = &"B"
	var from := [&""]
	sim.approaching_player.connect(func(r: StringName) -> void: from[0] = r)
	sim.start([&"A", &"B", &"C"], tuning, &"A")
	_run(2.0)
	assert_eq(from[0], &"A", "announces from the room he is in")
	assert_true(sim.holding)
	var before := sim.progress
	_run(10.0)
	assert_eq(sim.progress, before, "waits while the director telegraphs")
	sim.enter_player_room()
	assert_eq(sim.room, &"B")


func test_cannot_follow_into_a_memory() -> void:
	sim.player_room = &"B"
	sim.player_in_memory = true
	var approached := [false]
	sim.approaching_player.connect(func(_r: StringName) -> void: approached[0] = true)
	sim.start([&"A", &"B", &"C"], tuning, &"A")
	_run(20.0)
	assert_false(approached[0], "the stalker cannot follow into a memory (GDD §4.1)")
