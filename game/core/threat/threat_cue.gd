class_name ThreatCue
extends Node
## Telegraphs the stalker (GDD §5.1, rule R9): footsteps panned to the side he comes
## from, a heartbeat, and desaturated screen edges (global shader param wz_threat, read by
## post_look.gdshader). Reused by the M2 AI for every entry.

## Optional streams; cues still show visually without them (rule R6).
@export var footstep_stream: AudioStream
@export var heartbeat_stream: AudioStream

var intensity := 0.0
var _target := 0.0
var _footsteps: AudioStreamPlayer
var _heartbeat: AudioStreamPlayer


func _ready() -> void:
	_footsteps = AudioStreamPlayer.new()
	_footsteps.bus = &"SFX"
	add_child(_footsteps)
	_heartbeat = AudioStreamPlayer.new()
	_heartbeat.bus = &"SFX"
	add_child(_heartbeat)
	RenderingServer.global_shader_parameter_set(&"wz_threat", 0.0)


## side: -1 left .. 1 right of the current shot.
func start(side: float) -> void:
	_target = 1.0
	if footstep_stream:
		_footsteps.stream = footstep_stream
		_footsteps.pitch_scale = 1.0
		# Stereo position through a panner would need a bus effect; volume offset per side
		# is enough for the greybox. AudioDirector takes this over with real assets.
		_footsteps.volume_db = -6.0 + side * 2.0
		_footsteps.play()
	if heartbeat_stream:
		_heartbeat.stream = heartbeat_stream
		_heartbeat.play()


func stop() -> void:
	_target = 0.0
	_footsteps.stop()
	_heartbeat.stop()


func _process(delta: float) -> void:
	if not is_equal_approx(intensity, _target):
		intensity = move_toward(intensity, _target, delta * 0.8)
		RenderingServer.global_shader_parameter_set(&"wz_threat", intensity)
