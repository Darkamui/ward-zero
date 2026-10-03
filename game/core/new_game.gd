class_name NewGame
extends RefCounted
## Starts a fresh playthrough: new seed, chosen difficulty, starting items, act-start
## autosave (GDD §8.1: Patient autosaves at the start of each act).

const START_ROOM := "G01"
const START_SPAWN := "spawn_start"
const STARTING_ITEMS := ["item_dictaphone", "item_wristband"]


static func start(threat: String, puzzle: String, seed_value := -1) -> void:
	GameState.reset()
	Seed.set_seed(seed_value if seed_value >= 0 else Seed.new_random_seed())
	GameState.set_difficulty(threat, puzzle)
	for item in STARTING_ITEMS:
		GameState.give_item(item)
	GameState.set_location(START_ROOM, START_SPAWN)
	GameState.set_flag("act", 1)
	SaveSystem.save(SaveSystem.AUTOSAVE_SLOT)
