class_name SeedField
extends Resource
## A value generated from the playthrough seed (ADR-005), e.g. a safe code digit.

enum Kind { INT, STEPPED, CHOICE, UNIQUE_INTS, INT_LIST }

@export var name: StringName
@export var kind: Kind = Kind.INT
@export var min_value: int = 0
@export var max_value: int = 9
@export var step: int = 1
@export var count: int = 1
@export var choices: Array = []
