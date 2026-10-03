# ADR-002: GDScript only, statically typed

**Context.** C# projects can't reliably export to the web in Godot 4. A mixed codebase would also double the tooling.

**Decision.** All code is GDScript with static types everywhere (`var x: int`, typed arrays and dictionaries, typed function signatures). `untyped_declaration` is a warning. gdtoolkit (`gdformat`, `gdlint`) runs in CI.

**Consequences.** Faster scripts and earlier errors. Gdtoolkit can't parse a few newer syntax forms or variables named like keywords (`set`), so avoid those names.
