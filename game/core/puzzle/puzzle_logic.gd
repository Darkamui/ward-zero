class_name PuzzleLogic
extends RefCounted
## Pure puzzle rules, separate from the close-up UI so they can be unit-tested (rule R7:
## no input sequence may make a puzzle unsolvable). One subclass per puzzle.

## Seeded values, keyed by SeedField name (see PuzzleValues).
var values: Dictionary = {}
## Parameter set for the current puzzle difficulty.
var params: Dictionary = {}
var solved := false


func setup(seed_values: Dictionary, difficulty_params: Dictionary) -> void:
	values = seed_values
	params = difficulty_params
	_setup()


## Override: build initial state from values and params.
func _setup() -> void:
	pass


## Override: state to persist (puzzle progress survives leaving the close-up and saving).
func serialize() -> Dictionary:
	return {}


## Override: restore state. Must tolerate missing keys (older saves).
func deserialize(_data: Dictionary) -> void:
	pass


## Override in puzzles whose documents show derived values (e.g. a formatted date).
## Called by PuzzleValues for fields that are not plain SeedFields.
static func computed_value(_values: Dictionary, _field: StringName) -> Variant:
	return null


## The input that solves the puzzle, as the logic understands it. Used by tests and the
## critical-path smoke test; never by the game.
func solution() -> Variant:
	return null
