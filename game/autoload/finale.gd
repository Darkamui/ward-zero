extends Node
## P22 Ward Zero (docs/05-milestone-4.md): he walks out of the dark behind the player,
## slower than a walk. Taking the exit door plays Relapse or Discharge by P21's score;
## standing still and letting him arrive plays Claire at 12/12 (Relapse otherwise).

signal started
signal ended(ending: String)

const ROOM := &"B07"
const STALKER_SCENE := preload("res://game/characters/man_in_white/man_in_white.tscn")
## Fraction of the player's walk speed: anyone who moves gets away.
const SPEED_FACTOR := 0.8

var active := false
var stalker: ManInWhite


func _ready() -> void:
	EventBus.script_requested.connect(_on_script_requested)


func _on_script_requested(script_name: StringName) -> void:
	match script_name:
		&"finale_start":
			start()
		&"finale_exit":
			resolve(false)


func score() -> int:
	return int(GameState.get_flag("p21.score", 0))


func start() -> void:
	var room := RoomManager.current
	if active or room == null or room.room_id() != ROOM:
		return
	active = true
	StalkerDirector.deactivate()
	var spawn := room.get_spawn(&"spawn_stalker")
	StalkerDirector.cue.start(0.0)
	started.emit()
	await get_tree().create_timer(StalkerDirector.MIN_TELEGRAPH_SECONDS + 0.5, false).timeout
	if not active or RoomManager.current != room or spawn == null:
		return
	stalker = STALKER_SCENE.instantiate()
	room.add_child(stalker)
	stalker.global_position = spawn.global_position
	stalker.caught_player.connect(resolve.bind(true))
	stalker.pursue(RoomManager.player, Player.WALK_SPEED * SPEED_FACTOR)


func _physics_process(_delta: float) -> void:
	# Leaving Ward Zero mid-sequence cancels it; it starts over on the way back in.
	if active and (RoomManager.current == null or RoomManager.current.room_id() != ROOM):
		cancel()


func resolve(stayed: bool) -> void:
	if not active and stayed:
		return
	var ending := Ending.compute(score(), stayed)
	cancel()
	if RoomManager.player:
		RoomManager.player.stop()
	GameState.set_flag("ending", ending)
	Profile.record_ending(ending)
	RoomManager.flash(Color(1, 1, 1), 1.2)
	ended.emit(ending)
	EventBus.ui_requested.emit(&"ending")


func cancel() -> void:
	active = false
	StalkerDirector.cue.stop()
	if stalker and is_instance_valid(stalker):
		stalker.queue_free()
	stalker = null
