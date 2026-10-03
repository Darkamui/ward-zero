extends TestCase


func test_same_seed_same_values() -> void:
	Seed.set_seed(12345)
	var a := Seed.derive_int(&"p04", &"founding_year", 1890, 1925)
	var b := Seed.derive_int(&"p04", &"founding_year", 1890, 1925)
	assert_eq(a, b)


func test_known_value_is_stable() -> void:
	# Guards against accidental changes to the hash. If this fails after a deliberate
	# change, every existing save's codes change too: bump the save version.
	Seed.set_seed(1)
	assert_eq(Seed.hash32(&"p01", &"frequency"), 2946917920)


func test_different_seeds_differ() -> void:
	var values := {}
	for s in 50:
		Seed.set_seed(s)
		values[Seed.derive_int(&"p04", &"code", 0, 9999)] = true
	assert_true(values.size() > 40, "seeds should give varied codes, got %d distinct" % values.size())


func test_fields_independent() -> void:
	Seed.set_seed(7)
	var same := 0
	for i in 100:
		var a := Seed.derive_int(&"p05", StringName("a%d" % i), 0, 9)
		var b := Seed.derive_int(&"p05", StringName("b%d" % i), 0, 9)
		if a == b:
			same += 1
	assert_between(same, 0, 25, "fields should be uncorrelated")


func test_range_inclusive_and_distributed() -> void:
	var seen := {}
	for s in 400:
		Seed.set_seed(s)
		var v := Seed.derive_int(&"x", &"y", 3, 6)
		assert_between(v, 3, 6)
		seen[v] = true
	assert_eq(seen.size(), 4)


func test_stepped() -> void:
	for s in 100:
		Seed.set_seed(s)
		var v := Seed.derive_stepped(&"p01", &"frequency", 550, 1600, 10)
		assert_between(v, 550, 1600)
		assert_eq((v - 550) % 10, 0)


func test_unique_ints() -> void:
	for s in 50:
		Seed.set_seed(s)
		var v := Seed.derive_unique_ints(&"p05", &"hymns", 3, 100, 699)
		assert_eq(v.size(), 3)
		assert_true(v[0] != v[1] and v[1] != v[2] and v[0] != v[2])


func test_unique_ints_full_range() -> void:
	var v := Seed.derive_unique_ints(&"x", &"y", 5, 1, 5)
	v.sort()
	assert_eq(v, [1, 2, 3, 4, 5])


func test_choice() -> void:
	var v: String = Seed.derive_choice(&"p02", &"role", ["a", "b", "c"])
	assert_has(["a", "b", "c"], v)
