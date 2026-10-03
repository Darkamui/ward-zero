class_name DocumentData
extends Resource
## A readable document saved to Files (GDD §9.2).
## body_key is a template. Placeholders like {frequency} are bound in `placeholders`.

enum Style { TYPEWRITER, HANDWRITTEN, PRINT, NOTICE, NOTE }

const SCHEMA_VERSION := 1

@export var schema_version: int = SCHEMA_VERSION
@export var id: StringName
@export var title_key: String
@export var body_key: String
## Optional per-puzzle-difficulty body ("easy"/"hard"); falls back to body_key.
@export var body_key_by_difficulty: Dictionary[String, String] = {}
@export var fragment_id: StringName
## Placeholder name -> source. Sources: "seed:<puzzle>.<field>" or "flag:<flag name>".
@export var placeholders: Dictionary[StringName, String] = {}
@export var style: Style = Style.TYPEWRITER
@export var composure_delta: float = 0.0


func body_key_for(difficulty: String) -> String:
	return body_key_by_difficulty.get(difficulty, body_key)
