class_name PuzzleUi
extends PuzzleBase
## Shared layout for placeholder close-ups: title, hint, a content area and a status line.
## Final close-up art (M1-29) replaces the content area per puzzle.

const SOLVED_CLOSE_DELAY := 1.0

var content: Control
var status: Label


func _build_ui() -> void:
	theme = UiStyle.theme()
	var title := UiStyle.label(data.name_key, 44, UiStyle.ACCENT)
	title.position = Vector2(120, 70)
	add_child(title)
	var hint := UiStyle.label("puzzle.%s.hint" % String(data.id).to_lower(), 26, UiStyle.INK_DIM)
	hint.position = Vector2(120, 134)
	add_child(hint)
	content = Control.new()
	content.position = Vector2(120, 200)
	content.size = Vector2(1680, 720)
	add_child(content)
	status = UiStyle.label("", 30)
	status.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	status.position = Vector2(420, 990)
	add_child(status)
	_build_content()
	_refresh()
	if logic.solved:
		status.text = tr("puzzle.common.solved")


## Override: add controls to `content`.
func _build_content() -> void:
	pass


## Override: update controls from logic state.
func _refresh() -> void:
	pass


func show_status(key: String, values := {}) -> void:
	status.text = tr(key).format(values)


## Wraps report_attempt with feedback and auto-close on success.
func attempt(success: bool, fail_key: String) -> void:
	if logic.solved and GameState.is_puzzle_solved(String(data.id)):
		return
	report_attempt(success)
	_refresh()
	if success:
		show_status("puzzle.common.solved")
		await get_tree().create_timer(SOLVED_CLOSE_DELAY).timeout
		if is_inside_tree():
			request_close()
	else:
		show_status(fail_key)
