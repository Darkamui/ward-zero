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
			assert_true(found, "fragment %s has a document" % item.fragment_id)


func test_item_text_translated() -> void:
	for locale in ["en", "fr_CA"]:
		TranslationServer.set_locale(locale)
		for item in ContentDB.items.values():
			assert_ne(tr(item.name_key), item.name_key, "%s name (%s)" % [item.id, locale])
			assert_ne(tr(item.desc_key), item.desc_key, "%s desc (%s)" % [item.id, locale])
