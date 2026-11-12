#!/bin/bash
# Installs Greek Fighter as a RetroPie port. Run it on the Pi from the folder
# you unzipped greek-fighter-retropie.zip into:
#   bash install.sh
# Then restart EmulationStation; the game is under Ports.
set -e
cd "$(dirname "$0")"

case "$(uname -m)" in
  aarch64) BIN=greek-fighter.arm64 ;;
  armv7l|armv6l) BIN=greek-fighter.arm32 ;;
  *) echo "This doesn't look like a Raspberry Pi (uname -m = $(uname -m))."; exit 1 ;;
esac

GAME_DIR="$HOME/RetroPie/roms/ports/greek-fighter"
mkdir -p "$GAME_DIR"
cp "$BIN" "$GAME_DIR/greek-fighter"
chmod +x "$GAME_DIR/greek-fighter"

# Godot needs an X server; RetroPie boots straight to the console, so the
# launcher starts a bare one just for the game.
if ! command -v xinit >/dev/null 2>&1; then
  echo "Installing a minimal X server (needed once)..."
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends xserver-xorg xinit x11-xserver-utils
fi

cat > "$HOME/RetroPie/roms/ports/Greek Fighter.sh" <<LAUNCH
#!/bin/bash
# OpenGL ES 3 is the Pi's native GPU API; --fullscreen fills the TV.
xinit "$GAME_DIR/greek-fighter" --fullscreen --rendering-driver opengl3_es -- :0 -nocursor vt\$(fgconsole 2>/dev/null || echo 1)
LAUNCH
chmod +x "$HOME/RetroPie/roms/ports/Greek Fighter.sh"
echo "Installed. Restart EmulationStation and look under Ports for 'Greek Fighter'."
