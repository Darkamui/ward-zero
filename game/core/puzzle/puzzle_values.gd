class_name PuzzleValues
extends RefCounted
## Resolves seeded and derived puzzle values for puzzles and document templates.
## "P04.founding_year" → SeedField on PuzzleData P04; anything else asks the puzzle's
## logic script for a computed value.


static func all_for(data: PuzzleData) -> Dictionary:
	var result := {}
	# A puzzle can share another puzzle's seeded values (e.g. the E05 lockbox uses P08's).
	if data.values_from != &"":
		var source: PuzzleData = ContentDB.get_puzzle(data.values_from)
		if source:
			result = all_for(source)
	for f in data.seed_fields:
		result[f.name] = derive(data.id, f)
	return result


static func derive(puzzle_id: StringName, f: SeedField) -> Variant:
	match f.kind:
		SeedField.Kind.INT:
			return Seed.derive_int(puzzle_id, f.name, f.min_value, f.max_value)
		SeedField.Kind.STEPPED:
			return Seed.derive_stepped(puzzle_id, f.name, f.min_value, f.max_value, f.step)
		SeedField.Kind.CHOICE:
			return Seed.derive_choice(puzzle_id, f.name, f.choices)
		SeedField.Kind.UNIQUE_INTS:
			return Seed.derive_unique_ints(puzzle_id, f.name, f.count, f.min_value, f.max_value)
		SeedField.Kind.INT_LIST:
			var list: Array[int] = []
			for i in f.count:
				list.append(
					Seed.derive_int(puzzle_id, StringName("%s#%d" % [f.name, i]), f.min_value, f.max_value)
				)
			return list
	return null


## Value for a document placeholder or test. Returns null if unknown.
static func value(puzzle_id: StringName, field: StringName) -> Variant:
	var data: PuzzleData = ContentDB.get_puzzle(puzzle_id)
	if data == null:
		push_error("PuzzleValues: unknown puzzle %s" % puzzle_id)
		return null
	var f := data.get_seed_field(field)
	if f:
		return derive(puzzle_id, f)
	if data.values_from != &"":
		var shared: Variant = value(data.values_from, field)
		if shared != null:
			return shared
	if data.logic_script:
		return data.logic_script.call(&"computed_value", all_for(data), field)
	return null


## Builds a ready-to-use logic object for a puzzle at the current difficulty.
static func make_logic(data: PuzzleData) -> PuzzleLogic:
	var logic: PuzzleLogic = (data.logic_script as GDScript).new()
	logic.setup(all_for(data), data.params_for(GameState.puzzle_difficulty))
	logic.deserialize(GameState.get_puzzle_data(String(data.id)))
	logic.solved = GameState.is_puzzle_solved(String(data.id))
	return logic
