extends Node
## Room ambience, positional threat cues, music stingers. Filled in during M1.


func play_ambience(stream: AudioStream) -> void:
	push_error("AudioDirector.play_ambience(%s) not implemented" % stream)


## side: -1.0 = left, 0.0 = centre, 1.0 = right of the current shot.
func play_positional_cue(stream: AudioStream, side: float) -> void:
	push_error("AudioDirector.play_positional_cue(%s, %s) not implemented" % [stream, side])
