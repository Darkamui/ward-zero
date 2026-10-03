class_name PuzzleData
extends Resource
## Static description of a puzzle (GDD §9.2). The close-up scene extends PuzzleBase.

const SCHEMA_VERSION := 1

@export var schema_version: int = SCHEMA_VERSION
@export var id: StringName
@export var room_id: StringName
@export var scene: PackedScene
## Parameter sets keyed "easy", "normal", "hard". Missing sets fall back to "normal".
@export var params: Dictionary = {"normal": {}}
@export var seed_fields: Array[SeedField] = []
@export var fail_noise_hops: int = 1
@export var rewards: Array[Action] = []
@export var prerequisite_flags: Array[StringName] = []
@export var pauses_on_observer: bool = true
@export var solved_flag: StringName


func params_for(difficulty: String) -> Dictionary:
	if params.has(difficulty):
		return params[difficulty]
	return params.get("normal", {})


func get_seed_field(field_name: StringName) -> SeedField:
	for f in seed_fields:
		if f.name == field_name:
			return f
	return null
