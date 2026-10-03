extends Node
## In-game root: world, player, input and every overlay. Resumes from GameState (set by
## New Game, Load or Import); running the scene directly starts a new game.

var puzzle_host: PuzzleHost
var document_viewer: DocumentViewer
var tape_player: TapePlayer
var inventory: InventoryUi
var files: FilesUi
var save_screen: SaveScreen
var pause_menu: PauseMenu
var game_over: GameOverScreen
var end_of_slice: EndOfSliceScreen

@onready var world: Node3D = $World
@onready var player: Player = $Player


func _ready() -> void:
	puzzle_host = _add(PuzzleHost.new())
	document_viewer = _add(DocumentViewer.new())
	tape_player = _add(TapePlayer.new())
	inventory = _add(InventoryUi.new())
	files = _add(FilesUi.new())
	save_screen = _add(SaveScreen.new())
	pause_menu = _add(PauseMenu.new())
	game_over = _add(GameOverScreen.new())
	end_of_slice = _add(EndOfSliceScreen.new())
	if not OS.has_feature("release"):
		add_child(DebugOverlay.new())
	RoomManager.setup(world, player)
	if GameState.current_room == "":
		NewGame.start("patient", "normal")
	RoomManager.go_to(StringName(GameState.current_room), StringName(GameState.current_spawn))


func _add(node: Node) -> Variant:
	add_child(node)
	return node
