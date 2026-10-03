extends TestCase
## Puzzle DoD tests (docs/00-overview.md §6.2) for every built puzzle: solvable on every
## difficulty, still solvable after many random inputs (rule R7), deterministic per seed,
## progress survives serialize/deserialize.

const IDS := [
	&"P01",
	&"P02",
	&"P03",
	&"P04",
	&"P05",
	&"P06",
	&"P07",
	&"P08",
	&"P08L",
	&"P09",
	&"P10",
	&"P11",
	&"P12",
	&"P13",
]


func _logic(id: StringName, difficulty := "normal") -> PuzzleLogic:
	var data := ContentDB.get_puzzle(id)
	assert_true(data != null, "%s registered" % id)
	var logic: PuzzleLogic = (data.logic_script as GDScript).new()
	logic.setup(PuzzleValues.all_for(data), data.params_for(difficulty))
	return logic


func test_all_solvable_on_every_difficulty() -> void:
	for difficulty in ["easy", "normal", "hard"]:
		for s in 10:
			Seed.set_seed(s * 7919)
			for id in IDS:
				assert_true(
					_logic(id, difficulty).apply_solution(), "%s solvable (%s, seed %d)" % [id, difficulty, s]
				)


func test_never_unsolvable_after_wrong_inputs() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for s in 5:
		Seed.set_seed(s + 100)
		for id in IDS:
			var logic := _logic(id)
			for i in 60:
				logic.random_input(rng)
			assert_true(
				logic.solved or logic.apply_solution(),
				"%s still solvable after random inputs (seed %d)" % [id, s]
			)


func test_deterministic_per_seed() -> void:
	for id in IDS:
		Seed.set_seed(42)
		var a: Variant = _logic(id).solution()
		Seed.set_seed(42)
		var b: Variant = _logic(id).solution()
		assert_eq(str(a), str(b), "%s same seed same solution" % id)
		var differs := false
		for s in range(43, 53):
			Seed.set_seed(s)
			if str(_logic(id).solution()) != str(a):
				differs = true
				break
		assert_true(differs, "%s solution changes with the seed" % id)


func test_serialize_round_trip() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for id in IDS:
		Seed.set_seed(9)
		var logic := _logic(id)
		for i in 5:
			logic.random_input(rng)
		var copy := _logic(id)
		copy.deserialize(JSON.parse_string(JSON.stringify(logic.serialize())))
		assert_eq(JSON.stringify(copy.serialize()), JSON.stringify(logic.serialize()), "%s round trip" % id)


func test_wrong_answers_fail() -> void:
	Seed.set_seed(5)
	var p01 := _logic(&"P01") as P01Logic
	p01.set_dial(p01.frequency() + 100)
	assert_false(p01.release())
	assert_false((_logic(&"P02") as P02Logic).ring(), "ring with no cables")
	var p03 := _logic(&"P03") as P03Logic
	assert_false(p03.open_cabinet(p03.cabinet() % 12 + 1))
	assert_false((_logic(&"P05") as P05Logic).submit(), "empty board")
	assert_false((_logic(&"P06") as P06Logic).submit(), "empty drawers")
	var p08 := _logic(&"P08") as P08Logic
	assert_false(p08.pull((p08.target() + 1) % P08Logic.SHEETS))
	var p12 := _logic(&"P12") as P12Logic
	assert_false(p12.open((p12.sequence()[0] + 1) % P12Logic.DOORS))
	assert_eq(p12.progress, 0)


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


func test_p03_swapped_drawer_leads_to_card() -> void:
	for s in 20:
		Seed.set_seed(s)
		var p := _logic(&"P03") as P03Logic
		var month := p.birth_month()
		assert_ne(p.open_drawer(month), month, "labelled drawer holds another month")
		assert_eq(p.open_drawer(p.swapped_month()), month)
		assert_true(p.card_found)


func test_p04_code_rule() -> void:
	var p := _logic(&"P04") as P04Logic
	p.values = {&"founding_year": 1908, &"shift": 3}
	assert_eq(p.code(), [4, 2, 3, 1])
	p.params = {"reverse": true}
	assert_eq(p.code(), [1, 3, 2, 4])


func test_p06_clues_are_unambiguous() -> void:
	for s in 20:
		Seed.set_seed(s)
		var p := _logic(&"P06", "hard") as P06Logic
		var tray := p.tray()
		for i in p.patient_count():
			var matches := 0
			for pill in tray:
				if pill == p.pill_of(i):
					matches += 1
			assert_eq(matches, 1, "exactly one pill matches shape + colour")


func test_p07_configs_all_solvable_from_any_state() -> void:
	for difficulty in ["easy", "normal", "hard"]:
		var data := ContentDB.get_puzzle(&"P07")
		var configs: Array = data.params_for(difficulty).get("configs", P07Logic.DEFAULT_CONFIGS)
		for c in configs.size():
			var p := _logic(&"P07", difficulty) as P07Logic
			p.values = {&"config": c}
			p.reset()
			assert_false((p.solution() as Array).is_empty(), "%s config %d solvable" % [difficulty, c])


func test_p09_missing_drawing_gate() -> void:
	var p := _logic(&"P09") as P09Logic
	assert_false(p.available_pieces().has(5), "drawing 5 is in 1976 until moved")
	p.missing_available = true
	assert_true(p.available_pieces().has(5))


func test_p13_red_is_loud_but_recoverable() -> void:
	var p := _logic(&"P13") as P13Logic
	assert_false(
		(
			p.set_valve(0, P13Logic.MAX_SETTING)
			and p.set_valve(1, P13Logic.MAX_SETTING)
			and p.set_valve(2, P13Logic.MAX_SETTING)
		),
		"all valves open pushes a gauge into the red"
	)
	assert_true(p.apply_solution(), "and it can still be solved")
