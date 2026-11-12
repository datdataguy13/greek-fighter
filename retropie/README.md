# Greek Fighter on RetroPie

Needs a **Raspberry Pi 4 or 5** (the Pi 3's GPU doesn't support OpenGL ES 3).

1. Download `greek-fighter-retropie.zip` from the project's Releases page.
2. Copy it to the Pi (USB stick, or `scp greek-fighter-retropie.zip pi@retropie.local:`).
3. On the Pi (press F4 in EmulationStation for a terminal, or SSH in):

       unzip greek-fighter-retropie.zip -d greek-fighter
       bash greek-fighter/install.sh

4. Restart EmulationStation. Greek Fighter is under **Ports**.

Controllers: the first gamepad is player 1, the second is player 2.
D-pad / left stick moves; X = punch, A = kick, B = heavy, Y or RB = special,
Start = pause. To get back to EmulationStation, choose QUIT on the title
screen (from a fight: Start, then QUIT TO MENU).

The installer picks the 64-bit or 32-bit build to match your Pi's OS, and the
first time it runs it installs a minimal X server (Godot games need one).
