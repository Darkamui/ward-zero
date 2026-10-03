class_name PlayTape
extends Action
## Plays a tape or VO line. Listed tapes are added to Files here, so the state change
## doesn't depend on the TapePlayer UI being present (ADR-007).

@export var tape_id: StringName


func execute() -> void:
	var tape: TapeData = ContentDB.get_tape(tape_id)
	if tape and tape.listed_in_files:
		GameState.add_tape(String(tape_id))
	EventBus.tape_requested.emit(tape_id)
