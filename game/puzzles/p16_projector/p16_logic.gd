class_name P16Logic
extends OrderingLogic
## P16 Observation Theatre projector: put the six slides in lecture order (the lecture
## notes list the topics in order; Hard gives only "X comes before Y" pairs). Once they
## are in order, slides 2 and 5 overlap and show the Director's safe code.
## values: order (6 unique 0-5: the slide id for each position), safe_code (1000-9999).

const SLIDES := 6


func count() -> int:
	return SLIDES


func correct_order() -> Array:
	return (values.get(&"order", [0, 1, 2, 3, 4, 5]) as Array).duplicate()


## topic_key_<k>: topic of the slide in lecture position k. pair_<k>: Hard clue pairs
## (shuffled order of consecutive pairs). code_<i>: safe code digits.
static func computed_value(v: Dictionary, field: StringName) -> Variant:
	var f := String(field)
	var order: Array = v.get(&"order", [0, 1, 2, 3, 4, 5])
	if f.begins_with("topic_key_"):
		return "slide.topic.%d" % int(order[int(f.trim_prefix("topic_key_"))])
	if f.begins_with("pair_"):
		var k := int(f.trim_prefix("pair_"))
		var shuffle := [3, 0, 4, 1, 2]
		var p: int = shuffle[k]
		return (
			TranslationServer
			. translate("slide.pair")
			. format(
				{
					"a": TranslationServer.translate("slide.topic.%d" % int(order[p])),
					"b": TranslationServer.translate("slide.topic.%d" % int(order[p + 1])),
				}
			)
		)
	if f.begins_with("code_"):
		return CodeLockLogic.digit_of(v, "safe_code", 4, int(f.trim_prefix("code_")))
	return null
