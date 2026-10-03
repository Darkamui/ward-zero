#!/bin/sh
# Build, clay-render, import and link one greybox room. Run from the repo root.
# Usage: tools/greybox/greybox.sh G01 build_g01 [--memory]
set -e
ROOM="$1"; BUILDER="res://tools/greybox/$2.gd"; shift 2
GODOT="${GODOT:-godot}"
"$GODOT" --headless res://tools/run_tool.tscn -- "$BUILDER"
RENDER="$GODOT --rendering-driver opengl3 --audio-driver Dummy res://tools/run_tool.tscn -- res://tools/greybox/render_room.gd $ROOM"
if [ -z "$DISPLAY" ]; then
  xvfb-run -a -s "-screen 0 1920x1080x24" $RENDER
  for flag in "$@"; do xvfb-run -a -s "-screen 0 1920x1080x24" $RENDER "$flag"; done
else
  $RENDER
  for flag in "$@"; do $RENDER "$flag"; done
fi
"$GODOT" --headless --import
"$GODOT" --headless res://tools/run_tool.tscn -- "$BUILDER"
