extends TestCase
## Every document renders in both languages with all placeholders filled, and every clue
## shows exactly what its puzzle expects (rule R8; docs/02-milestone-1.md §10.1).


func after_each() -> void:
	TranslationServer.set_locale("en")


func _body(id: StringName) -> String:
	return DocumentRenderer.body(ContentDB.get_document(id))


func test_all_documents_render_in_both_locales() -> void:
	assert_true(ContentDB.documents.size() >= 12)
	for locale in ["en", "fr_CA"]:
		TranslationServer.set_locale(locale)
		for id in ContentDB.documents:
			var doc: DocumentData = ContentDB.documents[id]
			var title := DocumentRenderer.title(doc)
			var body := DocumentRenderer.body(doc)
			assert_ne(title, doc.title_key, "%s title translated (%s)" % [id, locale])
			assert_ne(body, doc.body_key, "%s body translated (%s)" % [id, locale])
			assert_false(body.contains("{"), "%s has unresolved placeholder (%s): %s" % [id, locale, body])
			assert_false(
				body.contains("?\n") or body.ends_with("?"), "%s has unknown value (%s)" % [id, locale]
			)


func test_clues_match_solutions_over_many_seeds() -> void:
	for s in 20:
		Seed.set_seed(s * 104729 + 3)
		# P01: notice shows the station.
		assert_true(_body(&"doc_quiet_hours").contains("%d kHz" % PuzzleValues.value(&"P01", &"frequency")))
		# P02: directory lists every route extension.
		var directory := _body(&"doc_staff_directory")
		for role in ["reception", "night_desk", "relay", "administrator"]:
			var ext: int = PuzzleValues.value(&"P02", StringName("ext_" + role))
			assert_true(directory.contains(str(ext)), "directory has %s" % role)
		# P03: wristband, admission file and card agree; the card names the cabinet.
		var birthdate: String = PuzzleValues.value(&"P03", &"birthdate")
		assert_true(_body(&"doc_wristband_note").contains(birthdate))
		assert_true(_body(&"doc_f01_admission_file").contains(birthdate))
		assert_true(
			_body(&"doc_catalog_card").contains("cabinet %d" % PuzzleValues.value(&"P03", &"cabinet"))
		)
		# P04: plaque year + memo shift give the safe code.
		var year: int = PuzzleValues.value(&"P04", &"founding_year")
		var shift: int = PuzzleValues.value(&"P04", &"shift")
		assert_true(_body(&"doc_founding_plaque").contains(str(year)))
		assert_true(_body(&"doc_cipher_memo").contains("advanced by %d" % shift))
		var logic := PuzzleValues.make_logic(ContentDB.get_puzzle(&"P04")) as P04Logic
		var expected := []
		for ch in str(year):
			expected.append((int(ch) + shift) % 10)
		assert_eq(logic.code(), expected)
		# P05: the 1976 board shows the three hymns.
		var board := _body(&"doc_hymn_board_1976")
		for h in PuzzleValues.value(&"P05", &"hymns"):
			assert_true(board.contains(str(h)))
		# P18 (Act 3) time is planted in F02.
		assert_true(_body(&"doc_f02_fire_clipping").contains(PuzzleValues.value(&"P18", &"fire_time")))


func test_language_switch_rerenders() -> void:
	var doc := ContentDB.get_document(&"doc_wristband_note")
	TranslationServer.set_locale("en")
	var en := DocumentRenderer.body(doc)
	TranslationServer.set_locale("fr_CA")
	var fr := DocumentRenderer.body(doc)
	assert_ne(en, fr)
	assert_true(fr.contains("Date de naissance"))


func test_fragments_have_documents() -> void:
	for id in ContentDB.items:
		var item: ItemData = ContentDB.items[id]
		if item.kind == ItemData.Kind.FRAGMENT:
			var found := false
			for doc in ContentDB.documents.values():
				if doc.fragment_id == item.fragment_id:
					found = true
			for tape in ContentDB.tapes.values():
				if tape.fragment_id == item.fragment_id:
					found = true
			assert_true(found, "fragment %s has a document or tape" % item.fragment_id)


func test_item_text_translated() -> void:
	for locale in ["en", "fr_CA"]:
		TranslationServer.set_locale(locale)
		for item in ContentDB.items.values():
			assert_ne(tr(item.name_key), item.name_key, "%s name (%s)" % [item.id, locale])
			assert_ne(tr(item.desc_key), item.desc_key, "%s desc (%s)" % [item.id, locale])


func test_hard_clues_match_solutions() -> void:
	GameState.set_difficulty("patient", "hard")
	for s in 20:
		Seed.set_seed(s * 7 + 1)
		# P01: the two addends sum to the station.
		var a: int = PuzzleValues.value(&"P01", &"riddle_a")
		var b: int = PuzzleValues.value(&"P01", &"riddle_b")
		assert_eq(a + b, PuzzleValues.value(&"P01", &"frequency"))
		var notice := _body(&"doc_quiet_hours")
		assert_true(notice.contains(str(a)) and notice.contains(str(b)))
		assert_false(notice.contains("%d kHz" % (a + b)), "Hard notice doesn't give the answer directly")
		# P04: memo says to reverse; the logic reverses.
		assert_true(_body(&"doc_cipher_memo").contains("right to left"))
		var p04 := PuzzleValues.make_logic(ContentDB.get_puzzle(&"P04")) as P04Logic
		assert_true(p04.params.get("reverse", false))
		# P05: board titles + hymnal index give the three numbers, in order.
		var board := _body(&"doc_hymn_board_1976")
		var index := _body(&"doc_hymnal_index").split("\n")
		var hymns: Array = PuzzleValues.value(&"P05", &"hymns")
		for k in 3:
			var title := tr(PuzzleValues.value(&"P05", StringName("title_key_%d" % k)))
			assert_true(board.contains(title), "board shows title %s" % title)
			var found := false
			for line in index:
				if line.begins_with(title + " ....."):
					found = line.ends_with(" " + str(hymns[k]))
			assert_true(found, "index maps %s to %d" % [title, hymns[k]])
		var all_numbers := {}
		for line in index.slice(2):
			all_numbers[line.get_slice(" ..... ", 1)] = true
		assert_eq(all_numbers.size(), P05Logic.TITLE_COUNT, "index numbers are unique")


func test_easy_clues() -> void:
	GameState.set_difficulty("patient", "easy")
	for s in 10:
		Seed.set_seed(s + 50)
		var board := _body(&"doc_hymn_board_1976")
		var hymns: Array = PuzzleValues.value(&"P05", &"hymns")
		assert_true(board.contains(str(hymns[0])) and board.contains(str(hymns[1])))
		assert_false(board.contains(str(hymns[2])), "Easy board shows only the 2 needed numbers")
		var p02 := PuzzleValues.make_logic(ContentDB.get_puzzle(&"P02")) as P02Logic
		assert_eq(p02.cable_count(), 2)
		assert_true(_body(&"doc_desk_memo").contains("Two cables"))


func test_act2_clues_match_solutions() -> void:
	for difficulty in ["easy", "normal", "hard"]:
		GameState.set_difficulty("patient", difficulty)
		for s in 15:
			Seed.set_seed(s * 31 + 7)
			# P06: chart shape + log colour identify each patient's pill.
			var p06 := PuzzleValues.make_logic(ContentDB.get_puzzle(&"P06")) as P06Logic
			var charts := _body(&"doc_med_charts")
			var shift_log := _body(&"doc_shift_log")
			for i in p06.patient_count():
				var name: String = PuzzleValues.value(&"P06", StringName("patient_%d" % i))
				var shape := tr(PuzzleValues.value(&"P06", StringName("shape_key_%d" % i)))
				var color := tr(PuzzleValues.value(&"P06", StringName("color_key_%d" % i)))
				assert_true(
					charts.contains("%s: one %s" % [name, color if difficulty == "easy" else shape]),
					"%s chart (%s)" % [name, difficulty]
				)
				assert_true(shift_log.contains("%s — the %s one" % [name, color]), "%s log" % name)
			# P08: the ledger row matching the note's bed and day has the target tag.
			var p08 := PuzzleValues.make_logic(ContentDB.get_puzzle(&"P08")) as P08Logic
			var key := (
				"Bed %d — %s —"
				% [PuzzleValues.value(&"P08", &"bed"), PuzzleValues.value(&"P08", &"day_name")]
			)
			var matches := []
			for line in _body(&"doc_laundry_ledger").split("\n"):
				if line.begins_with(key):
					matches.append(line)
			assert_eq(matches.size(), 1, "exactly one ledger row for the note's bed and day")
			if matches.size() == 1:
				assert_true(
					matches[0].ends_with(p08.tag(p08.target())), "that row has the stained sheet's tag"
				)
			# P08 label shows the lockbox code.
			var lock := PuzzleValues.make_logic(ContentDB.get_puzzle(&"P08L")) as CodeLockLogic
			assert_true(
				_body(&"doc_sheet_label").ends_with("%d%d%d" % lock.code()), "label gives the lockbox code"
			)
			# P10: the two boards together give the padlock code.
			var p10 := PuzzleValues.make_logic(ContentDB.get_puzzle(&"P10")) as CodeLockLogic
			var c := p10.code()
			assert_true(
				_body(&"doc_board_1998").contains(str(c[0])) and _body(&"doc_board_1976").ends_with(str(c[3]))
			)
			# P11: the lid sheet lists the melody, note by note.
			var p11 := PuzzleValues.make_logic(ContentDB.get_puzzle(&"P11")) as P11Logic
			var names := []
			for n in p11.melody():
				names.append(tr("note.%s" % P11Logic.NOTES[n]))
			assert_true(
				_body(&"doc_lid_sheet").ends_with(" ".join(names)), "lid sheet = melody (%s)" % difficulty
			)
	GameState.set_difficulty("patient", "normal")
