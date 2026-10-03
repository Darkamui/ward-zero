extends TestCase


func before_each() -> void:
	var item := ItemData.new()
	item.id = &"item_photograph"
	item.storage = ItemData.Storage.KEY_POUCH
	ContentDB.register_item(item)


func test_flag_is() -> void:
	var c := FlagIs.new()
	c.flag = &"g02.gate_open"
	assert_false(c.is_met())
	GameState.set_flag("g02.gate_open")
	assert_true(c.is_met())
	c.value = false
	assert_false(c.is_met())


func test_has_item() -> void:
	var c := HasItem.new()
	c.item_id = &"item_photograph"
	assert_false(c.is_met())
	GameState.give_item("item_photograph")
	assert_true(c.is_met())


func test_puzzle_solved_and_timeline() -> void:
	var p := PuzzleSolved.new()
	p.puzzle_id = &"P03"
	assert_false(p.is_met())
	GameState.mark_puzzle_solved("P03")
	assert_true(p.is_met())
	var t := TimelineIs.new()
	t.memory = true
	assert_false(t.is_met())
	GameState.set_memory(true)
	assert_true(t.is_met())


func test_composites() -> void:
	var a := FlagIs.new()
	a.flag = &"a"
	var b := FlagIs.new()
	b.flag = &"b"
	var all := AllOf.new()
	all.conditions = [a, b]
	var any := AnyOf.new()
	any.conditions = [a, b]
	var n := NotCondition.new()
	n.condition = a
	assert_true(all.is_met() == false and any.is_met() == false and n.is_met())
	GameState.set_flag("a")
	assert_true(all.is_met() == false and any.is_met() and not n.is_met())
	GameState.set_flag("b")
	assert_true(all.is_met())


func test_empty_all_met() -> void:
	assert_true(Condition.all_met([]))


func test_actions_change_state() -> void:
	var set_flag := SetFlag.new()
	set_flag.flag = &"g01.chain_released"
	var give := GiveItem.new()
	give.item_id = &"item_photograph"
	var doc := OpenDocument.new()
	doc.document_id = &"doc_quiet_hours"
	Action.run_all([set_flag, give, doc])
	assert_true(GameState.get_flag("g01.chain_released"))
	assert_true(GameState.has_item("item_photograph"))
	assert_has(GameState.documents, "doc_quiet_hours")
	var remove := RemoveItem.new()
	remove.item_id = &"item_photograph"
	remove.execute()
	assert_false(GameState.has_item("item_photograph"))


func test_actions_emit_requests() -> void:
	var got := []
	var on_text := func(k: String) -> void: got.append(k)
	var on_noise := func(_r: StringName, h: int) -> void: got.append(h)
	EventBus.text_requested.connect(on_text)
	EventBus.noise_emitted.connect(on_noise)
	var show := ShowText.new()
	show.key = "ui.door.locked"
	var noise := EmitNoise.new()
	noise.hops = 2
	Action.run_all([show, noise])
	EventBus.text_requested.disconnect(on_text)
	EventBus.noise_emitted.disconnect(on_noise)
	assert_eq(got, ["ui.door.locked", 2])
