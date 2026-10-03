extends Node
## In-game root: world, player, input, overlays. Starts a new game in G01 unless a save
## was loaded before this scene opened.

const START_ROOM := &"G01"
const START_SPAWN := &"spawn_start"

@onready var world: Node3D = $World
@onready var player: Player = $Player


func _ready() -> void:
	if not OS.has_feature("release"):
		add_child(DebugOverlay.new())
	RoomManager.setup(world, player)
	if GameState.current_room == "":
		Seed.set_seed(Seed.new_random_seed())
		RoomManager.go_to(START_ROOM, START_SPAWN)
	else:
		RoomManager.go_to(StringName(GameState.current_room), StringName(GameState.current_spawn))
