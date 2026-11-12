#!/bin/sh
# Parse-checks every script in the project; prints only problems.
cd "$(dirname "$0")/.."
G=/Applications/Godot.app/Contents/MacOS/Godot
for f in $(find scripts tools tests -name "*.gd"); do
  "$G" --headless --path . --check-only --script "res://$f" 2>&1 | grep -E "ERROR|Parse Error|Compile Error|at: " | grep -v "main.gd" | sed "s|^|$f: |" | head -6
done
