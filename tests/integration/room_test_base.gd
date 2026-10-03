class_name RoomTestBase
extends TestCase
## Shared setup for tests that load rooms: a throwaway world with a player.

var world: Node3D
var player: Player


func before_each() -> void:
	world = Node3D.new()
	tree().root.add_child(world)
	player = load("res://game/core/player/player.tscn").instantiate()
	world.add_child(player)
	RoomManager.setup(world, player)
	StalkerDirector.reset()


func after_each() -> void:
	StalkerDirector.reset()
	CameraDirector.unregister_room()
	RoomManager.current = null
	RoomManager.setup(null, null)
	world.queue_free()


func tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func load_room(room_id: StringName, spawn: StringName) -> Room:
	return RoomManager.load_room_now(ContentDB.get_room(room_id), spawn)


## Loads a room and runs its enter triggers, like RoomManager.go_to without fades.
func enter(room_id: StringName, spawn: StringName) -> Room:
	var room := load_room(room_id, spawn)
	RoomManager.room_entered.emit(room_id)
	RoomManager.run_enter_triggers(room.room_data)
	return room


func wait_nav_sync(room: Room) -> void:
	var map := room.get_world_3d().navigation_map
	var start := NavigationServer3D.map_get_iteration_id(map)
	for i in 30:
		if NavigationServer3D.map_get_iteration_id(map) >= start + 2:
			return
		await tree().physics_frame


func wait(seconds: float) -> void:
	await tree().create_timer(seconds).timeout


func hotspot(room: Room, hotspot_name: String) -> Interactable:
	return room.get_node("Hotspots/" + hotspot_name) as Interactable
