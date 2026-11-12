#!/bin/sh
# Re-scans the project so new class_names and assets are registered.
cd "$(dirname "$0")/.."
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import 2>&1 | grep -E "Parse Error|SCRIPT ERROR" | head -20
