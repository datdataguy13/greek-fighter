extends SceneTree

# Renders every song in songs.gd to assets/music/<id>.wav, so exported builds
# load the soundtrack instead of synthesising it while the game runs (which
# costs several seconds of CPU and makes the single-threaded web build stutter).
# tools/export.sh runs this before exporting; the .wav files are build output
# and stay out of git. Without them the game falls back to the synth in music.gd.
#   godot --headless --path . -s res://tools/bake_music.gd

const IMPORT := """[remap]

importer="wav"
type="AudioStreamWAV"

[params]

compress/mode=2
"""


func _initialize() -> void:
	var dir := ProjectSettings.globalize_path(Music.BAKED)
	DirAccess.make_dir_recursive_absolute(dir)
	var music := Music.new()
	for id: String in Songs.ALL:
		var wav := music.render(id)
		var path := dir.path_join(id + ".wav")
		if wav.save_to_wav(path) != OK:
			push_error("could not write " + path)
			quit(1)
			return
		# Ask the importer for QOA compression (about 5x smaller than raw PCM),
		# unless an import file is already there.
		if not FileAccess.file_exists(path + ".import"):
			var f := FileAccess.open(path + ".import", FileAccess.WRITE)
			f.store_string(IMPORT)
		print("baked ", id)
	music.free()
	quit()
