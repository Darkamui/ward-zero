# ADR-005: Seeded values through Seed.derive_*

**Context.** GDD §7: codes are generated from the playthrough seed so walkthroughs can't hand out answers and NG+ stays fresh.

**Decision.** Every seeded value comes from `Seed.derive_int/stepped/choice/unique_ints(puzzle_id, field, …)`. The derivation is a 32-bit FNV-1a hash of `"<seed>|<puzzle>|<field>"` with a Murmur3 finalizer, implemented in GDScript and independent of Godot's RNG. A unit test pins one known output.

**Consequences.** The same seed gives the same values on every platform and engine version. Changing the hash changes every code in existing saves, so it requires a save version bump. Puzzle-critical values are never baked into images (rule R1).
