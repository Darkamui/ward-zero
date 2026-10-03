class_name MapStatus
extends RefCounted
## Red/blue map status (GDD §3.5): a room is unresolved while it has an untaken pickup,
## an unsolved puzzle, or a locked exit. Computed from the live room and stored in its
## room state when the player leaves (and when the map opens).

const CLEARED := "cleared"
const UNRESOLVED := "unresolved"


static func compute(room: Room) -> String:
	return UNRESOLVED if not reasons(room).is_empty() else CLEARED


## Why a room is unresolved, for the map's side panel and tests.
static func reasons(room: Room) -> Array[String]:
	var result: Array[String] = []
	var room_id := String(room.room_id())
	for p in ContentDB.puzzles.values():
		if String(p.room_id) == room_id and not GameState.is_puzzle_solved(String(p.id)):
			result.append("puzzle:%s" % p.id)
	for n in room.hotspots():
		var h := n as Interactable
		if h == null or not h.is_active():
			continue
		if h.kind == Interactable.Kind.TAKE:
			result.append("pickup:%s" % h.name)
		elif h.kind == Interactable.Kind.EXIT and h.is_locked():
			result.append("locked:%s" % h.exit_id)
	return result


static func store(room: Room) -> void:
	GameState.room_state(String(room.room_id()))["status"] = compute(room)


static func stored(room_id: String) -> String:
	return GameState.room_states.get(room_id, {}).get("status", UNRESOLVED)


static func visited(room_id: String) -> bool:
	return GameState.get_flag("%s.visited" % room_id.to_lower(), false)
