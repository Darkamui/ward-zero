@tool
class_name HidingSpot
extends Interactable
## Locker, under a bed, curtained alcove, pantry (GDD §5.3). Click to hide, click again or
## right-click to come out. If the stalker sees the player go in, the spot is compromised:
## he finds them when he checks it.

## Where the player waits while hidden (child Marker3D "Inside"; defaults to here).
var compromised := false


func _ready() -> void:
	kind = Kind.USE
	super._ready()


func inside_position() -> Vector3:
	var m := get_node_or_null("Inside") as Node3D
	return m.global_position if m else global_position


func occupied() -> bool:
	var p := RoomManager.player
	return p != null and p.hiding_in == self


func interact() -> void:
	var p := RoomManager.player
	if p == null:
		return
	if occupied():
		p.leave_hiding()
		return
	compromised = StalkerDirector.stalker_sees_player()
	p.hide_in(self)
	Action.run_all(actions)


func cursor() -> Cursor:
	return Cursor.HAND if is_active() else Cursor.NONE
