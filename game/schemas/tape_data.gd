class_name TapeData
extends Resource
## A dictaphone tape or VO line (GDD §9.2). Audio and subtitles exist per locale.

const SCHEMA_VERSION := 1

@export var schema_version: int = SCHEMA_VERSION
@export var id: StringName
@export var title_key: String
## Locale ("en", "fr_CA") -> stream.
@export var audio: Dictionary[String, AudioStream] = {}
## Subtitle lines. Keys are translated, so one timing track serves both locales unless
## per_locale_subtitles has an entry for the locale.
@export var subtitles: Array[SubLine] = []
@export var per_locale_subtitles: Dictionary[String, Array] = {}
@export var fragment_id: StringName
## False for VO lines (e.g. the P01 radio message) that are not listed under Tapes.
@export var listed_in_files: bool = true


func audio_for(locale: String) -> AudioStream:
	if audio.has(locale):
		return audio[locale]
	var lang := locale.get_slice("_", 0)
	for k in audio.keys():
		if k.get_slice("_", 0) == lang:
			return audio[k]
	return audio.get("en")


func subtitles_for(locale: String) -> Array:
	if per_locale_subtitles.has(locale):
		return per_locale_subtitles[locale]
	return subtitles
