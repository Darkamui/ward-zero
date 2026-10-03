# ADR-008: In-house test runner instead of GUT

**Context.** The Foundation plan named GUT. Its archives couldn't be downloaded from the build environment, and a third-party addon also has to track each Godot version.

**Decision.** `tests/run_tests.gd` (about 100 lines) finds `tests/**/test_*.gd`, runs every `test_*` method on a fresh `TestCase`, resets `GameState`, `Seed` and `ContentDB` before each test, and fails a test on any assertion failure **or any engine/script error logged during it** (through a `Logger` added with `OS.add_logger`). Tests that deliberately trigger errors call `expect_errors(n)`. Exit code 1 on failure.

**Consequences.** No addon to update. Fewer features than GUT (no doubles or parameterized tests); add them only when a test needs them. GUT can still be added later if that changes.
