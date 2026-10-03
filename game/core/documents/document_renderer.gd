class_name DocumentRenderer
extends RefCounted
## Renders a DocumentData's title and body in the current language, filling placeholders
## from seeded puzzle values and flags (GDD §9.2, rule R1). Re-render on
## NOTIFICATION_TRANSLATION_CHANGED to switch language live.
##
## Placeholder sources (DocumentData.placeholders values):
##   "puzzle:P01.frequency"        seeded or computed puzzle value (PuzzleValues)
##   "puzzle:P05.hymns[1]"         element of an array value
##   "trpuzzle:P03.birth_month_key" translate a computed translation key
##   "flag:g01.chain_released"     a GameState flag


static func title(doc: DocumentData) -> String:
	return TranslationServer.translate(doc.title_key)


static func body(doc: DocumentData) -> String:
	var key := doc.body_key_for(GameState.puzzle_difficulty)
	return TranslationServer.translate(key).format(placeholder_values(doc))


static func placeholder_values(doc: DocumentData) -> Dictionary:
	var result := {}
	for name in doc.placeholders:
		result[String(name)] = str(resolve(doc.placeholders[name]))
	return result


static func resolve(source: String) -> Variant:
	var kind := source.get_slice(":", 0)
	var ref := source.substr(kind.length() + 1)
	match kind:
		"flag":
			return GameState.get_flag(ref, false)
		"puzzle", "trpuzzle":
			var v: Variant = _puzzle_ref(ref)
			return TranslationServer.translate(str(v)) if kind == "trpuzzle" else v
	push_error("DocumentRenderer: bad placeholder source '%s'" % source)
	return "?"


static func _puzzle_ref(ref: String) -> Variant:
	var index := -1
	var bracket := ref.find("[")
	if bracket != -1:
		index = int(ref.substr(bracket + 1, ref.find("]") - bracket - 1))
		ref = ref.substr(0, bracket)
	var puzzle_id := StringName(ref.get_slice(".", 0))
	var field := StringName(ref.get_slice(".", 1))
	var v: Variant = PuzzleValues.value(puzzle_id, field)
	if index >= 0 and v is Array:
		return v[index] if index < v.size() else "?"
	return v if v != null else "?"
