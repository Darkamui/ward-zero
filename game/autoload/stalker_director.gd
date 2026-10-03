extends Node
## The Man in White: room-graph simulation, noise propagation, state machine and 3D
## spawning (GDD §5.1, ADR-006). M1 adds the scripted chase, M2 the full AI.

signal state_changed(state: State)
signal noise_heard(room_id: StringName, hops: int)

enum State { DORMANT, PATROL, INVESTIGATE, SEARCH, CHASE, LOSE }

## Minimum warning before any entry into the player's room (rule R9).
const MIN_TELEGRAPH_SECONDS := 3.0

var state: State = State.DORMANT
## Recent noise events for the debug overlay: [{ room, hops, time }].
var noise_log: Array[Dictionary] = []


func _ready() -> void:
	EventBus.noise_emitted.connect(_on_noise_emitted)


func _on_noise_emitted(room_id: StringName, hops: int) -> void:
	noise_log.append({"room": room_id, "hops": hops, "time": Time.get_ticks_msec() / 1000.0})
	if noise_log.size() > 20:
		noise_log.pop_front()
	noise_heard.emit(room_id, hops)
