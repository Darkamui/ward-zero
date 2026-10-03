extends Node
## Runs a tool script with autoloads available (they are not in --script mode).
##   godot --headless res://tools/run_tool.tscn -- res://tools/<tool>.gd [args...]
## The tool extends RefCounted and implements `func run(tree, args) -> int` (may await).


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("usage: -- res://tools/<tool>.gd [args]")
		get_tree().quit(2)
		return
	var script: GDScript = load(args[0])
	if script == null:
		get_tree().quit(2)
		return
	# Let the root finish setting up its children before tools add nodes to it.
	await get_tree().process_frame
	var tool: Object = script.new()
	var code: int = await tool.run(get_tree(), args.slice(1))
	get_tree().quit(code)
