# ADR-003: Content as custom Resources

**Context.** 33 rooms, 22 puzzles, dozens of items and documents. Logic hard-coded per room would be unmaintainable for a solo developer.

**Decision.** Rooms, puzzles, items, documents and tapes are described by `RoomData`, `PuzzleData`, `ItemData`, `DocumentData` and `TapeData` resources (`game/schemas/`). Behaviour on hotspots and rewards is composed from small `Condition` and `Action` resources edited in the inspector. `ContentDB` indexes all of them by id at startup. Room scenes hold only room-specific scripts when data can't express something.

**Consequences.** Content can be validated headlessly (missing ids, unreachable hotspots). The Action/Condition set grows only as content needs it; it must never become a general scripting language.
