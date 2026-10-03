extends Node
## In-game root: world, player, input and every overlay. Resumes from GameState (set by
## New Game, Load or Import); running the scene directly starts a new game.

var puzzle_host: PuzzleHost
var document_viewer: DocumentViewer
var tape_player: TapePlayer
var inventory: InventoryUi
var files: FilesUi
var map: MapUi
var save_screen: SaveScreen
var pause_menu: PauseMenu
var game_over: GameOverScreen
var end_of_slice: EndOfSliceScreen
var ending_screen: EndingScreen

@onready var world: Node3D = $World
@onready var player: Player = $Player


func _ready() -> void:
	puzzle_host = _add(PuzzleHost.new())
	document_viewer = _add(DocumentViewer.new())
	tape_player = _add(TapePlayer.new())
	inventory = _add(InventoryUi.new())
	files = _add(FilesUi.new())
	map = _add(MapUi.new())
	save_screen = _add(SaveScreen.new())
	pause_menu = _add(PauseMenu.new())
	game_over = _add(GameOverScreen.new())
	end_of_slice = _add(EndOfSliceScreen.new())
	ending_screen = _add(EndingScreen.new())
	_add(HidingHud.new())
	if not OS.has_feature("release"):
		add_child(DebugOverlay.new())
	Finale.cancel()
	StalkerDirector.restore(GameState.stalker)
	StalkerDirector.player_caught.connect(_on_player_caught)
	RoomManager.setup(world, player)
	if GameState.current_room == "":
		NewGame.start("patient", "normal")
	RoomManager.go_to(StringName(GameState.current_room), StringName(GameState.current_spawn))


func _exit_tree() -> void:
	if StalkerDirector.player_caught.is_connected(_on_player_caught):
		StalkerDirector.player_caught.disconnect(_on_player_caught)


func _on_player_caught() -> void:
	game_over.checkpoint = StalkerDirector.checkpoint
	await get_tree().create_timer(1.0).timeout
	game_over.show_screen()


func _add(node: Node) -> Variant:
	add_child(node)
	return node
