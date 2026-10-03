class_name PuzzleBase
extends Control
## Close-up puzzle view (GDD §9.2). Hosts a PuzzleLogic, turns its results into game
## effects: noise on failure (never lost progress, rule R7), rewards on success.
## Subclasses build their UI in _build_ui() and call report_attempt() after inputs.

signal solved
signal failed_attempt
signal noise_emitted(hops: int)
signal close_requested

var data: PuzzleData
var logic: PuzzleLogic


func setup(puzzle_data: PuzzleData) -> void:
	data = puzzle_data
	logic = PuzzleValues.make_logic(data)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


## Override: create controls for the current logic state.
func _build_ui() -> void:
	pass


## Persist progress after every input.
func save_state() -> void:
	GameState.set_puzzle_data(String(data.id), logic.serialize())


## Call after a complete attempt (ring, pull, submit). Returns whether it solved.
func report_attempt(success: bool) -> bool:
	save_state()
	if success:
		_on_solved()
	else:
		failed_attempt.emit()
		if data.fail_noise_hops > 0:
			noise_emitted.emit(data.fail_noise_hops)
			EventBus.noise_emitted.emit(StringName(GameState.current_room), data.fail_noise_hops)
	return success


func _on_solved() -> void:
	if GameState.is_puzzle_solved(String(data.id)):
		return
	logic.solved = true
	GameState.mark_puzzle_solved(String(data.id))
	if data.solved_flag != &"":
		GameState.set_flag(data.solved_flag, true)
	Action.run_all(data.rewards)
	solved.emit()


func request_close() -> void:
	close_requested.emit()
