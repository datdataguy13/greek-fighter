extends SceneTree

# Checks every song in songs.gd (bar lengths, patterns), renders it and prints
# its length, loudness and render time. Set MUSIC_OUT=<folder> to also save
# each song as a .wav file you can listen to.

func _initialize() -> void:
	var music := Music.new()
	var out := OS.get_environment("MUSIC_OUT")
	var bad := 0
	for id: String in Songs.ALL:
		for problem in Songs.check(id):
			print("PROBLEM  ", problem)
			bad += 1
		var t0 := Time.get_ticks_msec()
		var wav := music.render(id)
		var ms := Time.get_ticks_msec() - t0
		var peak := 0
		var sum := 0.0
		var data := wav.data
		var n := data.size() / 2
		var clipped := 0
		for i in n:
			var v := data.decode_s16(i * 2)
			peak = maxi(peak, absi(v))
			if absi(v) >= 29990:
				clipped += 1
			sum += float(v) * v
		print("%-10s %-20s %5.1fs  peak %3d%%  rms %4.1f%%  %d clipped  rendered in %d ms" % [id, Songs.ALL[id]["name"],
			float(n) / Music.RATE, peak * 100 / 30000, sqrt(sum / n) / 300.0, clipped, ms])
		if out != "":
			wav.save_to_wav(out.path_join(id + ".wav"))
	music.free()
	print("%d songs, %d problems" % [Songs.ALL.size(), bad])
	quit(1 if bad > 0 else 0)
