extends OrderingUi
## P16 close-up: the slide carousel. Easy numbers the slides as the lecture notes do.


func piece_text(p: int) -> String:
	var t := tr("slide.topic.%d" % p)
	if bool(data.params_for(GameState.puzzle_difficulty).get("numbered", false)):
		t = "%d. %s" % [(logic as P16Logic).correct_order().find(p) + 1, t]
	return t


func slot_text(s: int) -> String:
	return tr("puzzle.p16.slot").format({"n": s + 1})


func submit_key() -> String:
	return "puzzle.p16.run"
