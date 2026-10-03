class_name StalkerTuning
extends Resource
## Threat-difficulty rules and stalker tuning (GDD §8.1, docs/03-milestone-2.md §2).
## One resource per threat level in game/data/tuning/.

@export var threat: String = "patient"
@export var catch_lethal := true
@export var autosave_every_room := false
## Autosave when an act starts (GDD §8.1: Patient). Off on Committed, where every save
## costs a Blank Cassette.
@export var autosave_act_start := true
@export var saves_cost_cassette := false
@export var close_ups_pause := false
@export var walk_speed := 1.5
@export var run_speed := 2.8
@export var hearing_bonus := 0
@export var search_time := 10.0
@export var breath_required := 2.5
@export var breath_capacity := 4.5
@export var observer_composure_penalty := 0.3
