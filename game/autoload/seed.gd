extends Node
## Deterministic per-playthrough values (ADR-005).
##
## Every seeded game value is derived from (playthrough seed, puzzle id, field name)
## with a 32-bit FNV-1a hash plus a finalizer. This does not depend on Godot's RNG
## implementation, so values stay stable across engine versions and platforms.
## Never use the global RNG for game content.

const _FNV_OFFSET := 0x811C9DC5
const _FNV_PRIME := 0x01000193
const _MASK32 := 0xFFFFFFFF

var current: int = 0


func set_seed(value: int) -> void:
	current = value & _MASK32


## Fresh seed for a new game or NG+. Not deterministic by design.
func new_random_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi() & _MASK32


## Integer in [min_value, max_value], inclusive.
func derive_int(puzzle_id: StringName, field: StringName, min_value: int, max_value: int) -> int:
	assert(max_value >= min_value)
	var span := max_value - min_value + 1
	return min_value + (hash32(puzzle_id, field) % span)


## Integer in [min_value, max_value] that is a multiple of step away from min_value.
func derive_stepped(
	puzzle_id: StringName, field: StringName, min_value: int, max_value: int, step: int
) -> int:
	assert(step > 0)
	var count := (max_value - min_value) / step + 1
	return min_value + derive_int(puzzle_id, field, 0, count - 1) * step


func derive_choice(puzzle_id: StringName, field: StringName, choices: Array) -> Variant:
	assert(not choices.is_empty())
	return choices[derive_int(puzzle_id, field, 0, choices.size() - 1)]


## count distinct integers in [min_value, max_value], in derived order.
func derive_unique_ints(
	puzzle_id: StringName, field: StringName, count: int, min_value: int, max_value: int
) -> Array[int]:
	assert(count <= max_value - min_value + 1)
	var result: Array[int] = []
	var i := 0
	while result.size() < count:
		var value := derive_int(puzzle_id, StringName("%s#%d" % [field, i]), min_value, max_value)
		if not result.has(value):
			result.append(value)
		i += 1
	return result


func hash32(puzzle_id: StringName, field: StringName) -> int:
	var h := _FNV_OFFSET
	for byte in ("%d|%s|%s" % [current, puzzle_id, field]).to_utf8_buffer():
		h = ((h ^ byte) * _FNV_PRIME) & _MASK32
	# Murmur3 finalizer for better low-bit distribution before the modulo.
	h ^= h >> 16
	h = _mul32(h, 0x85EBCA6B)
	h ^= h >> 13
	h = _mul32(h, 0xC2B2AE35)
	h ^= h >> 16
	return h


## (a * b) mod 2^32 without overflowing GDScript's signed 64-bit int.
static func _mul32(a: int, b: int) -> int:
	var low := a * (b & 0xFFFF)
	var high := ((a * (b >> 16)) & 0xFFFF) << 16
	return (low + high) & _MASK32
