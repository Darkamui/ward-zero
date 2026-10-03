# ADR-007: State changes only through GameState

**Context.** Saving, loading, debugging and the content validator all need one place that holds the truth.

**Decision.** Everything that must survive a save lives in the `GameState` autoload and changes only through its methods, which emit signals. Ids are stored as `String` so `to_dict()` serializes to JSON without conversion. Requests that aren't state (show text, open a puzzle, play a tape) go through `EventBus` signals.

**Consequences.** Save/load is one `to_dict`/`from_dict` pair. UI updates by listening to signals instead of polling.
