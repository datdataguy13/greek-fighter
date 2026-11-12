#!/bin/sh
# Usage: tools/shot.sh <res://script.gd> <out.png> [frames]   (extra env vars pass through)
cd "$(dirname "$0")/.."
G=/Applications/Godot.app/Contents/MacOS/Godot
SHOT_SCRIPT="$1" SHOT_OUT="$2" SHOT_FRAMES="${3:-20}" "$G" --path . --quit-after 600 -s res://tools/shoot.gd 2>&1 | grep -vE "^Godot Engine|^OpenGL|^$" | head -40
