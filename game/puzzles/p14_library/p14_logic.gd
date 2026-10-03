class_name P14Logic
extends OrderingLogic
## P14 Library: shelve the books from the Director's reading list in call-number order
## (the reading list gives each title's number). Correct shelving opens the secret door.
## values: catalog (7 unique 100-999). params.books (3/5/7).

const TITLES := 7


func count() -> int:
	return int(params.get("books", 5))


func catalog_of(book: int) -> int:
	return int(values[&"catalog"][book])


func correct_order() -> Array:
	var order := range(count())
	order.sort_custom(func(a: int, b: int) -> bool: return catalog_of(a) < catalog_of(b))
	return order


## title_key_<i>, catalog_<i> for the reading list.
static func computed_value(v: Dictionary, field: StringName) -> Variant:
	var f := String(field)
	if f.begins_with("title_key_"):
		return "book.title.%d" % int(f.trim_prefix("title_key_"))
	if f.begins_with("catalog_"):
		return int(v[&"catalog"][int(f.trim_prefix("catalog_"))])
	return null
