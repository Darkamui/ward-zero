class_name NewGame
extends RefCounted
## Starts a fresh playthrough: new seed, chosen difficulty, starting items, act-start
## autosave (GDD §8.1: Patient autosaves at the start of each act). New Game+ (GDD §8.3)
## also keeps the Files from the profile and adds the Claire ending hint.

const START_ROOM := "G01"
const START_SPAWN := "spawn_start"
const STARTING_ITEMS := ["item_dictaphone", "item_wristband"]
const NG_PLUS_HINT := "doc_claire_hint"


static func start(threat: String, puzzle: String, seed_value := -1, ng_plus := false) -> void:
	GameState.reset()
	Seed.set_seed(seed_value if seed_value >= 0 else Seed.new_random_seed())
	GameState.set_difficulty(threat, puzzle)
	for item in STARTING_ITEMS:
		GameState.give_item(item)
	GameState.set_location(START_ROOM, START_SPAWN)
	GameState.set_flag("act", 1)
	if ng_plus:
		GameState.ng_plus = 1
		for doc in Profile.kept_documents():
			GameState.add_document(doc)
		for tape in Profile.kept_tapes():
			GameState.add_tape(tape)
		GameState.add_document(NG_PLUS_HINT)
	SaveSystem.save(SaveSystem.AUTOSAVE_SLOT)
