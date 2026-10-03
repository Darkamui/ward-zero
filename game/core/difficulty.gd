class_name Difficulty
extends RefCounted
## Access to the current threat tuning (game/data/tuning/<threat>.tres).

const DIR := "res://game/data/tuning"

static var _cache: Dictionary = {}


static func tuning(threat := "") -> StalkerTuning:
	if threat == "":
		threat = GameState.threat_difficulty
	if not _cache.has(threat):
		var path := "%s/%s.tres" % [DIR, threat]
		_cache[threat] = load(path) if ResourceLoader.exists(path) else StalkerTuning.new()
	return _cache[threat]
