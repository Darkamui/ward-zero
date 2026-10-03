class_name HidingHud
extends CanvasLayer
## While hidden: a hint to come out, and during a breath check a breath meter with the
## phase in words (the visual alternative to his footsteps and breathing, rule R6).

var _panel: PanelContainer
var _label: Label
var _meter: ProgressBar
var _check: BreathCheck


func _ready() -> void:
	layer = 16
	_panel = PanelContainer.new()
	_panel.theme = UiStyle.theme()
	_panel.position = Vector2(660, 60)
	_panel.custom_minimum_size = Vector2(600, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	_label = UiStyle.label("", 28)
	_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_label)
	_meter = ProgressBar.new()
	_meter.max_value = 1.0
	_meter.step = 0.01
	_meter.show_percentage = false
	_meter.custom_minimum_size = Vector2(560, 28)
	box.add_child(_meter)
	_panel.visible = false
	StalkerDirector.breath_check_started.connect(func(c: BreathCheck) -> void: _check = c)
	StalkerDirector.breath_check_ended.connect(func(_ok: bool) -> void: _check = null)


func _process(_delta: float) -> void:
	var player := RoomManager.player
	var hidden := player != null and player.is_hidden()
	_panel.visible = hidden
	if not hidden:
		return
	if _check:
		_meter.visible = true
		_meter.value = _check.breath_left()
		_label.text = (
			tr("ui.breath.hold") if _check.phase == BreathCheck.Phase.CHECK else tr("ui.breath.coming")
		)
	else:
		_meter.visible = false
		_label.text = tr("ui.hiding.hint")
