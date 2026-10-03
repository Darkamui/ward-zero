extends TestCase

var _key: ItemData
var _crank: ItemData


func before_each() -> void:
	_key = ItemData.new()
	_key.id = &"item_test_key"
	_key.storage = ItemData.Storage.KEY_POUCH
	_key.kind = ItemData.Kind.KEY
	ContentDB.register_item(_key)
	_crank = ItemData.new()
	_crank.id = &"item_test_crank"
	ContentDB.register_item(_crank)


func test_flags_default_false() -> void:
	assert_eq(GameState.get_flag("nope"), false)


func test_set_flag_emits_once() -> void:
	var calls := []
	GameState.flag_changed.connect(func(f: String, v: Variant) -> void: calls.append([f, v]))
	GameState.set_flag("g01.chain_released")
	GameState.set_flag("g01.chain_released")
	assert_eq(calls.size(), 1)
	assert_eq(calls[0][0], "g01.chain_released")
	assert_true(GameState.get_flag("g01.chain_released"))


func test_set_flag_mixed_types_no_error() -> void:
	GameState.set_flag("x", 1)
	GameState.set_flag("x", "one")
	assert_eq(GameState.get_flag("x"), "one")


func test_inventory_starts_with_six_empty_slots() -> void:
	assert_eq(GameState.slot_count(), 6)
	assert_eq(GameState.free_slots(), 6)


func test_key_goes_to_pouch() -> void:
	assert_true(GameState.give_item("item_test_key"))
	assert_has(GameState.key_pouch, "item_test_key")
	assert_eq(GameState.free_slots(), 6)
	assert_true(GameState.has_item("item_test_key"))


func test_slot_item_and_full_inventory() -> void:
	for i in 6:
		assert_true(GameState.give_item("item_test_crank"))
	assert_false(GameState.give_item("item_test_crank"), "seventh item should not fit")
	assert_eq(GameState.free_slots(), 0)


func test_satchel_grows_slots() -> void:
	GameState.set_slot_count(8)
	assert_eq(GameState.slot_count(), 8)
	GameState.set_slot_count(6)
	assert_eq(GameState.slot_count(), 8, "never shrinks")


func test_remove_item() -> void:
	GameState.give_item("item_test_crank")
	assert_true(GameState.remove_item("item_test_crank"))
	assert_false(GameState.has_item("item_test_crank"))
	assert_false(GameState.remove_item("item_test_crank"))


func test_bin_round_trip() -> void:
	GameState.give_item("item_test_crank")
	assert_true(GameState.move_to_bin(0))
	assert_eq(GameState.bin, ["item_test_crank"])
	assert_true(GameState.take_from_bin(0))
	assert_true(GameState.has_item("item_test_crank"))
	assert_eq(GameState.bin.size(), 0)


func test_fragments_listed() -> void:
	var frag := ItemData.new()
	frag.id = &"item_f01"
	frag.storage = ItemData.Storage.KEY_POUCH
	frag.kind = ItemData.Kind.FRAGMENT
	frag.fragment_id = &"F01"
	ContentDB.register_item(frag)
	GameState.give_item("item_f01")
	GameState.give_item("item_test_key")
	assert_eq(GameState.fragments(), ["F01"])


func test_room_state() -> void:
	GameState.mark_taken("G01", "pickup_notice")
	assert_true(GameState.is_taken("G01", "pickup_notice"))
	assert_false(GameState.is_taken("G02", "pickup_notice"))
	GameState.mark_exit_opened("G01", "to_g02")
	assert_true(GameState.is_exit_opened("G01", "to_g02"))


func test_puzzle_state() -> void:
	GameState.set_puzzle_data("P01", {"dial": 700})
	assert_eq(GameState.get_puzzle_data("P01")["dial"], 700)
	assert_false(GameState.is_puzzle_solved("P01"))
	GameState.mark_puzzle_solved("P01")
	assert_true(GameState.is_puzzle_solved("P01"))
	assert_eq(GameState.get_puzzle_data("P01")["dial"], 700, "solving keeps data")


func test_round_trip_dict() -> void:
	Seed.set_seed(99)
	GameState.set_difficulty("committed", "hard")
	GameState.set_flag("a.b", true)
	GameState.give_item("item_test_key")
	GameState.give_item("item_test_crank")
	GameState.add_document("doc_quiet_hours")
	GameState.mark_document_read("doc_quiet_hours")
	GameState.add_tape("tape_01_claire")
	GameState.set_location("G02", "spawn_from_g01")
	GameState.set_memory(true)
	GameState.set_puzzle_data("P02", {"patches": [[1, 2]]})
	GameState.mark_taken("G01", "x")
	var d := GameState.to_dict()
	var json := JSON.stringify(d)
	GameState.reset()
	Seed.set_seed(0)
	GameState.from_dict(JSON.parse_string(json))
	assert_eq(Seed.current, 99)
	assert_eq(GameState.threat_difficulty, "committed")
	assert_eq(GameState.puzzle_difficulty, "hard")
	assert_true(GameState.get_flag("a.b"))
	assert_true(GameState.has_item("item_test_key"))
	assert_true(GameState.has_item("item_test_crank"))
	assert_eq(GameState.slot_count(), 6)
	assert_eq(GameState.documents_read, ["doc_quiet_hours"])
	assert_eq(GameState.tapes, ["tape_01_claire"])
	assert_eq(GameState.current_room, "G02")
	assert_true(GameState.in_memory())
	assert_true(GameState.is_taken("G01", "x"))
	assert_eq(GameState.get_puzzle_data("P02")["patches"][0][1], 2)


func test_difficulty_names() -> void:
	GameState.set_difficulty("observer", "easy")
	assert_eq(GameState.threat_difficulty, "observer")
