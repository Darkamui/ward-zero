class_name RoomGraph
extends RefCounted
## The building as a graph: rooms are nodes, exits are undirected edges (ADR-006).


static func neighbors(room_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	var data: RoomData = ContentDB.get_room(room_id)
	if data:
		for e in data.exits:
			if not result.has(e.target_room) and ContentDB.get_room(e.target_room):
				result.append(e.target_room)
	for other_id in ContentDB.rooms:
		if other_id == room_id or result.has(other_id):
			continue
		for e in ContentDB.rooms[other_id].exits:
			if e.target_room == room_id:
				result.append(other_id)
				break
	return result


## Shortest path from a to b, inclusive. Empty if unreachable. `passable(room_id)` can
## exclude rooms (the endpoints are always allowed).
static func path(a: StringName, b: StringName, passable := Callable()) -> Array[StringName]:
	if a == b:
		return [a]
	var prev := {a: &""}
	var queue: Array[StringName] = [a]
	while not queue.is_empty():
		var cur: StringName = queue.pop_front()
		for n in neighbors(cur):
			if prev.has(n):
				continue
			if n != b and passable.is_valid() and not passable.call(n):
				continue
			prev[n] = cur
			if n == b:
				var result: Array[StringName] = [b]
				var step: StringName = cur
				while step != &"":
					result.push_front(step)
					step = prev[step]
				return result
			queue.append(n)
	return []


## Number of edges between a and b, or -1 if unreachable.
static func distance(a: StringName, b: StringName, passable := Callable()) -> int:
	var p := path(a, b, passable)
	return p.size() - 1 if not p.is_empty() else -1


## Closest room satisfying predicate(RoomData) -> bool, or &"" if none.
static func nearest(from: StringName, predicate: Callable) -> StringName:
	var seen := {from: true}
	var queue: Array[StringName] = [from]
	while not queue.is_empty():
		var cur: StringName = queue.pop_front()
		var data: RoomData = ContentDB.get_room(cur)
		if data and predicate.call(data):
			return cur
		for n in neighbors(cur):
			if not seen.has(n):
				seen[n] = true
				queue.append(n)
	return &""


## The spawn marker in `room_id` used when arriving from `from_room`.
static func spawn_from(room_id: StringName, from_room: StringName) -> StringName:
	var data: RoomData = ContentDB.get_room(from_room)
	if data:
		for e in data.exits:
			if e.target_room == room_id:
				return e.target_spawn
	return StringName("spawn_from_%s" % String(from_room).to_lower())
