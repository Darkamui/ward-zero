extends TestCase
## Puzzle DoD tests (docs/00-overview.md §6.2) for P01-P05: solvable with the correct
## input, wrong input fails, still solvable after many wrong inputs (rule R7),
## deterministic per seed, progress survives serialize/deserialize.

const IDS := [&"P01", &"P02", &"P03", &"P04", &"P05"]


func _logic(id: StringName, difficulty := "normal") -> PuzzleLogic:
	var data := ContentDB.get_puzzle(id)
	var logic: PuzzleLogic = (data.logic_script as GDScript).new()
	logic.setup(PuzzleValues.all_for(data), data.params_for(difficulty))
	return logic


## Applies the known solution. Returns whether the final attempt solved it.
func _solve(id: StringName, logic: PuzzleLogic) -> bool:
	var s: Variant = logic.solution()
	match id:
		&"P01":
			logic.set_dial(s)
			return logic.release()
		&"P02":
			for p in logic.patches.duplicate():
				logic.unplug(p[0])
			for link in s:
				logic.connect_jacks(link[0], link[1])
			return logic.ring()
		&"P03":
			logic.open_drawer(s["drawer"])
			return logic.open_cabinet(s["cabinet"])
		&"P04":
			for i in 4:
				logic.set_wheel(i, s[i])
			return logic.pull()
		&"P05":
			for r in s.size():
				var n: int = s[r]
				logic.place(r, 0, n / 100)
				logic.place(r, 1, (n / 10) % 10)
				logic.place(r, 2, n % 10)
			return logic.submit()
	return false


## One random input of any kind; returns true if it was a (failed or not) attempt.
func _random_input(id: StringName, logic: PuzzleLogic, rng: RandomNumberGenerator) -> void:
	match id:
		&"P01":
			logic.set_dial(rng.randf_range(400, 1800))
			if not logic.is_tuned():
				logic.release()
		&"P02":
			var jacks: Array = logic.jacks()
			match rng.randi() % 3:
				0:
					logic.connect_jacks(jacks[rng.randi() % jacks.size()], jacks[rng.randi() % jacks.size()])
				1:
					logic.unplug_link(jacks[rng.randi() % jacks.size()], jacks[rng.randi() % jacks.size()])
				2:
					if not logic.patches.is_empty():
						var saved: Array = logic.patches.duplicate(true)
						if not logic.ring():
							logic.patches = saved
		&"P03":
			logic.open_drawer(rng.randi_range(1, 12))
			var c := rng.randi_range(1, 12)
			if c != logic.cabinet():
				logic.open_cabinet(c)
		&"P04":
			logic.turn_wheel(rng.randi() % 4, rng.randi_range(-3, 3))
			if logic.wheels != logic.code():
				logic.pull()
		&"P05":
			var r: int = rng.randi() % logic.rows()
			if rng.randf() < 0.3:
				logic.clear(r, rng.randi() % 3)
			else:
				logic.place(r, rng.randi() % 3, rng.randi() % 10)
			if logic.is_full() and not logic.submit():
				pass


func test_all_solvable_on_every_difficulty() -> void:
	for difficulty in ["easy", "normal", "hard"]:
		for s in 10:
			Seed.set_seed(s * 7919)
			for id in IDS:
				assert_true(
					_solve(id, _logic(id, difficulty)), "%s solvable (%s, seed %d)" % [id, difficulty, s]
				)


func test_never_unsolvable_after_wrong_inputs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for s in 5:
		Seed.set_seed(s + 100)
		for id in IDS:
			var logic := _logic(id)
			for i in 60:
				_random_input(id, logic, rng)
			assert_true(_solve(id, logic), "%s still solvable after random inputs (seed %d)" % [id, s])


func test_deterministic_per_seed() -> void:
	for id in IDS:
		Seed.set_seed(42)
		var a: Variant = _logic(id).solution()
		Seed.set_seed(42)
		var b: Variant = _logic(id).solution()
		Seed.set_seed(43)
		var c: Variant = _logic(id).solution()
		assert_eq(a, b, "%s same seed same solution" % id)
		assert_ne(str(a), str(c), "%s different seed changes the solution" % id)


func test_wrong_answers_fail() -> void:
	Seed.set_seed(5)
	var p01 := _logic(&"P01") as P01Logic
	p01.set_dial(p01.frequency() + 100)
	assert_false(p01.release())
	var p02 := _logic(&"P02") as P02Logic
	assert_false(p02.ring(), "ring with no cables")
	var p03 := _logic(&"P03") as P03Logic
	assert_false(p03.open_cabinet(p03.cabinet() % 12 + 1))
	var p04 := _logic(&"P04") as P04Logic
	p04.wheels = [9, 9, 9, 9] if p04.code() != [9, 9, 9, 9] else [0, 0, 0, 0]
	assert_false(p04.pull())
	var p05 := _logic(&"P05") as P05Logic
	assert_false(p05.submit(), "empty board")


func test_serialize_round_trip() -> void:
	Seed.set_seed(9)
	var p02 := _logic(&"P02") as P02Logic
	var links: Array = p02.solution()
	p02.connect_jacks(links[0][0], links[0][1])
	var copy := _logic(&"P02") as P02Logic
	copy.deserialize(JSON.parse_string(JSON.stringify(p02.serialize())))
	assert_eq(copy.patches, p02.patches)
	var p05 := _logic(&"P05") as P05Logic
	p05.place(1, 2, 7)
	var copy5 := _logic(&"P05") as P05Logic
	copy5.deserialize(JSON.parse_string(JSON.stringify(p05.serialize())))
	assert_eq(copy5.board[1][2], 7)


func test_p02_cable_rules() -> void:
	var p := _logic(&"P02") as P02Logic
	var j: Array = p.jacks()
	assert_true(p.connect_jacks(j[0], j[1]))
	assert_false(p.connect_jacks(j[1], j[0]), "same link twice")
	assert_false(p.connect_jacks(j[3], j[3]), "same jack")
	assert_true(p.connect_jacks(j[1], j[2]), "a jack takes a second cable (chain)")
	assert_false(p.connect_jacks(j[1], j[4]), "but not a third")
	assert_true(p.connect_jacks(j[4], j[5]))
	assert_false(p.connect_jacks(j[6], j[7]), "no cables left")
	assert_eq(p.patches.size(), p.cable_count())
	p.unplug_link(j[1], j[2])
	assert_eq(p.patches.size(), p.cable_count() - 1)


func test_p03_swapped_drawer_leads_to_card() -> void:
	for s in 20:
		Seed.set_seed(s)
		var p := _logic(&"P03") as P03Logic
		var month := p.birth_month()
		assert_ne(p.open_drawer(month), month, "labelled drawer holds another month")
		assert_false(p.card_found)
		assert_eq(p.open_drawer(p.swapped_month()), month)
		assert_true(p.card_found)
	var easy := _logic(&"P03", "easy") as P03Logic
	assert_eq(easy.open_drawer(easy.birth_month()), easy.birth_month(), "Easy: labels not swapped")


func test_p04_code_rule() -> void:
	var p := _logic(&"P04") as P04Logic
	p.values = {&"founding_year": 1908, &"shift": 3}
	assert_eq(p.code(), [4, 2, 3, 1])
	p.params = {"reverse": true}
	assert_eq(p.code(), [1, 3, 2, 4])


func test_p01_signal_strength_is_visual_alternative() -> void:
	var p := _logic(&"P01") as P01Logic
	p.set_dial(p.frequency())
	assert_eq(p.signal_strength(), 1.0)
	p.set_dial(p.frequency() + P01Logic.FADE_RANGE * 2)
	assert_eq(p.signal_strength(), 0.0)
