extends Node
## Global signals for events with no single owner (ADR-007).
## Owned state changes go through the owning autoload's own signals instead.

@warning_ignore("unused_signal")
signal noise_emitted(room_id: StringName, hops: int)
@warning_ignore("unused_signal")
signal ui_opened(ui_name: StringName)
@warning_ignore("unused_signal")
signal ui_closed(ui_name: StringName)

# Requests from data-driven actions to whichever UI or system handles them.
@warning_ignore("unused_signal")
signal text_requested(key: String)
@warning_ignore("unused_signal")
signal puzzle_requested(puzzle_id: StringName)
@warning_ignore("unused_signal")
signal document_requested(document_id: StringName)
@warning_ignore("unused_signal")
signal tape_requested(tape_id: StringName)
@warning_ignore("unused_signal")
signal sfx_requested(stream: AudioStream)
@warning_ignore("unused_signal")
signal script_requested(script_name: StringName)
