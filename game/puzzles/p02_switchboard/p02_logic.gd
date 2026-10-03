class_name P02Logic
extends PuzzleLogic
## P02 Reception switchboard: patch cables along the route given by the desk memo (by
## role); the staff directory maps roles to extensions. Press ring to test.
## Lamps (with a ✓) show each correctly patched link, never colour alone (rule R5).
##
## params.route: role ids in route order (n roles = n-1 cables).
## params.decoys: other roles with a jack on the board.
## values.extensions: one unique extension per entry of ALL_ROLES, so the directory
## (which lists every role) is the same at every difficulty.

const ALL_ROLES := [
	"reception",
	"night_desk",
	"relay",
	"administrator",
	"records",
	"chaplain",
	"kitchen",
	"pharmacy",
	"boiler_room",
	"director",
]

var patches: Array = []  # Array of [ext_a, ext_b], a < b


func route() -> Array:
	return params.get("route", ["reception", "night_desk", "relay", "administrator"])


func decoys() -> Array:
	return params.get("decoys", [])


func roles() -> Array:
	return route() + decoys()


func extension_of(role: String) -> int:
	return P02Logic.extension_for(values, role)


static func extension_for(v: Dictionary, role: String) -> int:
	var i := ALL_ROLES.find(role)
	var exts: Array = v.get(&"extensions", [])
	return int(exts[i]) if i >= 0 and i < exts.size() else -1


## Jack labels in board order (sorted, so the board never hints at the route).
func jacks() -> Array:
	var result := []
	for r in roles():
		result.append(extension_of(r))
	result.sort()
	return result


func cable_count() -> int:
	return route().size() - 1


func required_links() -> Array:
	var result := []
	var r := route()
	for i in r.size() - 1:
		result.append(_link(extension_of(r[i]), extension_of(r[i + 1])))
	return result


func jack_in_use(ext: int) -> bool:
	for p in patches:
		if p.has(ext):
			return true
	return false


## Connects two free jacks with a spare cable. Returns false if not possible.
func connect_jacks(a: int, b: int) -> bool:
	if a == b or not jacks().has(a) or not jacks().has(b):
		return false
	if jack_in_use(a) or jack_in_use(b) or patches.size() >= cable_count():
		return false
	patches.append(_link(a, b))
	return true


## Pulls the cable plugged into ext, if any.
func unplug(ext: int) -> void:
	for p in patches.duplicate():
		if p.has(ext):
			patches.erase(p)


func link_correct(link: Array) -> bool:
	return required_links().has(_link(link[0], link[1]))


## Ring the Administrator: true when exactly the required links are patched.
func ring() -> bool:
	if patches.size() != cable_count():
		return false
	for p in patches:
		if not link_correct(p):
			return false
	solved = true
	return true


func serialize() -> Dictionary:
	return {"patches": patches.duplicate(true)}


func deserialize(d: Dictionary) -> void:
	patches = []
	for p in d.get("patches", []):
		if p is Array and p.size() == 2:
			patches.append(_link(int(p[0]), int(p[1])))


func solution() -> Variant:
	return required_links()


## Directory placeholders: "ext_<role>".
static func computed_value(v: Dictionary, field: StringName) -> Variant:
	var f := String(field)
	if f.begins_with("ext_"):
		return extension_for(v, f.trim_prefix("ext_"))
	return null


static func _link(a: int, b: int) -> Array:
	return [mini(a, b), maxi(a, b)]
