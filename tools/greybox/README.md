# Greybox rooms

Greybox rooms are built from code so layouts are reproducible, then clay-rendered to stand-in backgrounds through the same path the final Blender renders will use (docs/02-milestone-1.md §7).

One room, from `ward-zero/`:

```
godot --headless res://tools/run_tool.tscn -- res://tools/greybox/build_g01.gd
xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --audio-driver Dummy \
    res://tools/run_tool.tscn -- res://tools/greybox/render_room.gd G01
godot --headless --import
godot --headless res://tools/run_tool.tscn -- res://tools/greybox/build_g01.gd   # links the new backgrounds
```

On a desktop, drop `xvfb-run …` and run the render line with a normal window. Add `--memory` to the render line to produce `bg_mem/` for rooms with a 1976 variant.

`tools/greybox/greybox.sh <room_id> <builder>` runs all four steps.

Naming conventions for nodes are those in `ProxyProcessor` (`floor_`, `occ_`, `col_`, `shadow_`, `art_`). The `clay_color` metadata sets each mesh's render colour.
