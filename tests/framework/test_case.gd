class_name TestCase
extends RefCounted
## Minimal test base class. Methods named test_* are run by tests/run_tests.gd.
## The runner resets GameState and Seed before every test.

var failures: Array[String] = []


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func fail(message: String) -> void:
	failures.append(message)


func assert_true(condition: bool, message := "") -> void:
	if not condition:
		fail("expected true. %s" % message)


func assert_false(condition: bool, message := "") -> void:
	if condition:
		fail("expected false. %s" % message)


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if not _equal(actual, expected):
		fail("expected <%s> but got <%s>. %s" % [expected, actual, message])


func assert_ne(actual: Variant, unexpected: Variant, message := "") -> void:
	if _equal(actual, unexpected):
		fail("did not expect <%s>. %s" % [unexpected, message])


func assert_has(container: Variant, value: Variant, message := "") -> void:
	if not container.has(value):
		fail("expected %s to contain <%s>. %s" % [container, value, message])


func assert_between(value: float, low: float, high: float, message := "") -> void:
	if value < low or value > high:
		fail("expected %s in [%s, %s]. %s" % [value, low, high, message])


static func _equal(a: Variant, b: Variant) -> bool:
	if typeof(a) == TYPE_FLOAT or typeof(b) == TYPE_FLOAT:
		if typeof(a) in [TYPE_FLOAT, TYPE_INT] and typeof(b) in [TYPE_FLOAT, TYPE_INT]:
			return is_equal_approx(float(a), float(b))
	if typeof(a) != typeof(b):
		# Allow String vs StringName comparisons.
		if typeof(a) in [TYPE_STRING, TYPE_STRING_NAME] and typeof(b) in [TYPE_STRING, TYPE_STRING_NAME]:
			return String(a) == String(b)
		return false
	return a == b


## Call when a test deliberately triggers engine errors (e.g. push_error paths).
func expect_errors(count: int) -> void:
	set_meta("expected_errors", get_meta("expected_errors", 0) + count)
