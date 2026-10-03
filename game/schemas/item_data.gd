class_name ItemData
extends Resource
## Static description of an item (GDD §9.2).

enum Storage { SLOT, KEY_POUCH }
enum Kind { NORMAL, KEY, ANCHOR, FRAGMENT, CONSUMABLE, TOOL }

const SCHEMA_VERSION := 1

@export var schema_version: int = SCHEMA_VERSION
@export var id: StringName
@export var name_key: String
@export var desc_key: String
@export var icon: Texture2D
@export var examine_model: PackedScene
@export var examine_reveals: Array[ExamineReveal] = []
## Other item id -> resulting item id.
@export var combines_with: Dictionary[StringName, StringName] = {}
@export var storage: Storage = Storage.SLOT
@export var kind: Kind = Kind.NORMAL
@export var droppable: bool = true
## Consumables: run on "Use" from the inventory, then the item is used up.
@export var use_actions: Array[Action] = []
## For fragments: the GDD fragment id (F01..F12).
@export var fragment_id: StringName
