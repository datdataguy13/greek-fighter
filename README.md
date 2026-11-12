# Greek Fighter

A two-player fighting game in the spirit of Street Fighter, starring the gods,
heroes and heroines of Greek myth. Built with Godot 4 (GDScript). All art,
sound and music is generated in code, so the project has no image or audio files.

## Play it

- **In a browser (nothing to install):** https://datdataguy13.github.io/greek-fighter/
  Works in Chrome, Edge, Firefox and Safari on a computer, and gamepads work too.
- **Download for Mac, Linux or Raspberry Pi:** get the zip for your machine from
  the [Releases page](https://github.com/datdataguy13/greek-fighter/releases).
  - **Mac:** unzip and open *Greek Fighter.app*. It isn't from the App Store,
    so the first time macOS will refuse to open it. Go to *System Settings >
    Privacy & Security* and click **Open Anyway** next to Greek Fighter (you
    only need to do this once).
  - **Linux:** unzip and run `./greek-fighter.x86_64`.
  - **Raspberry Pi / RetroPie:** see [retropie/README.md](retropie/README.md).
- **From the source code:** install [Godot 4.7](https://godotengine.org/download)
  (on a Mac: `brew install --cask godot`), download this repo, open
  `project.godot` in Godot and press F5. Or from a terminal:

      /Applications/Godot.app/Contents/MacOS/Godot --path .

## Controls

|            | Player 1 | Player 2 | Gamepad |
|------------|----------|----------|---------|
| Move       | W A S D  | Arrows   | D-pad / left stick |
| Punch      | F        | K        | X |
| Kick       | G        | L        | A |
| Heavy      | H        | ;        | B |
| Special    | T        | O        | Y or RB |

Esc or P pauses and shows both fighters' move lists. Gamepad 1 is player 1,
gamepad 2 is player 2. In menus, Punch selects and Kick goes back.

- Hold **back** to block. Crouch-block low attacks; stand to block jump attacks.
- **Punch > Kick > Heavy** chains into a combo, and normals cancel into specials.
- **Forward or back + Heavy** up close throws (throws beat blocking).
- Double-tap forward or back to dash.
- Specials: **Special**, **forward/back + Special**, **down + Special**
  (or the classic motions: quarter-circle forward + Punch, forward-down-down/forward
  + Punch, quarter-circle back + Kick). Some fighters have an air Special.
- Super: **down, down + Special** when the meter is full.

## Modes

- **Story mode:** pick a fighter and win ten fights across the arenas. Fights
  1-8 are drawn at random, fight 9 is your fighter's rival and fight 10 is their
  final battle. Before each fight a versus screen shows the arena, what the
  opponent has to say and a tip for beating them. Lose and you can continue
  (the CPU eases off a little each time); win all ten for your fighter's ending.
  The CPU LEVEL setting on the title screen sets how hard the journey is.
- **2 player versus**, **1 player vs CPU** and **watch CPU vs CPU**.

The title screen also has a MUSIC on/off switch (remembered between runs).

## Fighters

Zeus, Poseidon, Hades, Athena, Ares, Artemis, Hermes, Achilles, Odysseus,
Jason, Atalanta, Heracles, Hippolyta, Medusa.

## Arenas

Mount Olympus, Walls of Troy, River Styx, the Labyrinth, Deck of the Argo,
the Acropolis, Oracle of Delphi, Cyclops' Cave.

## How the code is laid out

    scripts/sim/     the rules: fighters, moves, hits, rounds, CPU (no drawing, no engine input)
    scripts/data/    roster.gd (stats and moves), looks.gd (what each fighter looks like),
                     story.gd (story mode: rivals, taunts, tips, intros and endings)
    scripts/art/     rig.gd + poses.gd (cartoon fighters), stage_art.gd, fx.gd
    scripts/ui/      title, fighter select, arena select, versus and story pages, fight screen and HUD
    scripts/audio/   sfx.gd (sound effects), songs.gd (the soundtrack as note data),
                     music.gd (the chiptune synth that plays it)
    tests/           rules tests
    tools/           balance run, screenshot and art-check helpers

- **Add a fighter:** add a look to `scripts/data/looks.gd` (and its id to `ORDER`)
  and an entry to `scripts/data/roster.gd`.
  Give them a story in `scripts/data/story.gd` too.
- **Add an arena:** add an entry to `LIST` in `scripts/art/stage_art.gd` and a
  matching draw function, and a song with the same id in `scripts/audio/songs.gd`.
- **Change the music:** every tune is a few lines of text in
  `scripts/audio/songs.gd` (the format is explained at the top of the file).
  `tools/music_check.gd` checks the songs and, with `MUSIC_OUT=<folder>`, saves
  each one as a `.wav` to listen to.

## Tests and balance

    G=/Applications/Godot.app/Contents/MacOS/Godot
    $G --headless --path . -s res://tests/test_sim.gd      # fight rules
    $G --headless --path . -s res://tests/test_combat.gd   # input helpers
    $G --headless --path . -s res://tests/test_story.gd    # story mode, songs, elbows and knees
    $G --headless --path . -s res://tools/music_check.gd   # render and measure every song
    $G --headless --path . -s res://tools/balance.gd       # CPU vs CPU, every matchup

The balance tool prints each fighter's win rate when the CPU plays both sides.
Set `BALANCE_N` (games per matchup) and `BALANCE_DETAIL=1` (damage by move).
After adding a script with a new `class_name`, run `tools/import.sh` once.

## Building and releasing

Every push to `main` runs the tests on GitHub, builds every version and
updates the browser version on GitHub Pages
(see [.github/workflows/build.yml](.github/workflows/build.yml)).
To publish downloads, tag a version:

    git tag v1.0 && git push origin v1.0

and the Mac, Linux, web and RetroPie zips appear on the Releases page.

To build on your own machine instead, install Godot's export templates once
(in Godot: Editor > Manage Export Templates > Download) and run
`tools/export.sh`; the zips land in `build/dist/`.

The project uses the Compatibility (OpenGL) renderer and scales to any
screen, which is what the web and the Raspberry Pi need.

## License

The code is MIT licensed (see [LICENSE](LICENSE)). The Bangers font is by
Vernon Adams under the SIL Open Font License.
