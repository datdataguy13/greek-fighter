#!/bin/sh
# Builds every target in export_presets.cfg into build/ and zips them for
# sharing. Needs Godot's export templates (in Godot: Editor > Manage Export
# Templates > Download, once).
#   tools/export.sh [path-to-godot]
set -e
cd "$(dirname "$0")/.."
G="${1:-/Applications/Godot.app/Contents/MacOS/Godot}"
rm -rf build
mkdir -p build/web build/mac build/linux build/pi build/dist
"$G" --headless --path . --import >/dev/null 2>&1 || true
"$G" --headless --path . --export-release "Web" build/web/index.html
"$G" --headless --path . --export-release "macOS" "build/mac/Greek Fighter.zip"
"$G" --headless --path . --export-release "Linux" build/linux/greek-fighter.x86_64
"$G" --headless --path . --export-release "Raspberry Pi 64-bit" build/pi/greek-fighter.arm64
"$G" --headless --path . --export-release "Raspberry Pi 32-bit" build/pi/greek-fighter.arm32
cp retropie/install.sh retropie/README.md build/pi/

cp "build/mac/Greek Fighter.zip" build/dist/greek-fighter-mac.zip
(cd build/web && zip -qr ../dist/greek-fighter-web.zip .)
(cd build/linux && zip -qr ../dist/greek-fighter-linux.zip .)
(cd build/pi && zip -qr ../dist/greek-fighter-retropie.zip .)
ls -lh build/dist
