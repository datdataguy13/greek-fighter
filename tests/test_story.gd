extends SceneTree

# Story mode and soundtrack data checks. Run from the project folder:
#   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tests/test_story.gd

var failures := 0


func _initialize() -> void:
	var stages: Array = []
	for s in StageArt.LIST:
		stages.append(s["id"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 3

	var complete := true
	var ladders_ok := true
	var tours := true
	var arms_ok := true
	for id: String in Looks.ORDER:
		var d: Dictionary = Story.DATA.get(id, {})
		for key in ["home", "taunts", "tip", "intro", "rival", "rival_line", "boss", "boss_line", "ending_title", "ending"]:
			if not d.has(key):
				complete = false
		if not complete:
			continue
		if d["rival"] == id or d["boss"] == id or d["rival"] == d["boss"] or d["ending"].size() < 3:
			complete = false
		for home in d["home"]:
			if home not in stages:
				complete = false

		for run in 20:
			var session := {"ids": [id, "zeus"], "level_idx": 1, "level": 0.5, "stage": "olympus"}
			Story.begin(session, rng)
			var ladder: Array = session["story"]["ladder"]
			var seen := {}
			var places := {}
			for f in ladder:
				seen[f["opp"]] = true
				places[f["stage"]] = true
				if f["opp"] == id or f["stage"] not in stages:
					ladders_ok = false
			if ladder.size() != Story.FIGHTS or seen.size() != Story.FIGHTS:
				ladders_ok = false
			if ladder[8]["opp"] != d["rival"] or ladder[9]["opp"] != d["boss"]:
				ladders_ok = false
			if places.size() < 5:
				tours = false
			# Walk the whole journey: the CPU must get harder, never out of range.
			var last := -9.0
			for i in Story.FIGHTS:
				Story.setup_fight(session)
				if session["level"] < last or session["level"] > 1.0 or Story.quote(session) == "":
					ladders_ok = false
				last = session["level"]
				if Story.advance(session) != (i == Story.FIGHTS - 1):
					ladders_ok = false

		# Elbows fold the forearm towards the front and knees fold the shin
		# towards the back, in every pose.
		for name: String in Poses.DEFS:
			var pose := Poses.pose(name)
			var j := Rig.solve(pose, Looks.L[id])
			for side in ["f", "b"]:
				var upper: Vector2 = j["el_" + side] - j["sh_" + side]
				var fore: Vector2 = j["hd_" + side] - j["el_" + side]
				var thigh: Vector2 = j["kn_" + side] - j["hp_" + side]
				var shin: Vector2 = j["ft_" + side] - j["kn_" + side]
				if upper.cross(fore) > 0.01 or thigh.cross(shin) < -0.01:
					arms_ok = false
	_expect(complete, "every fighter has a complete story (taunts, tip, intro, rival, final battle, ending)")
	_expect(ladders_ok, "every journey is 10 different opponents, rival 9th, final battle last, getting harder")
	_expect(tours, "every journey visits at least 5 different arenas")
	_expect(arms_ok, "no pose bends an elbow or a knee the wrong way")

	var session2 := {"ids": ["heracles", "zeus"], "level_idx": 1, "level": 0.5, "stage": "olympus"}
	Story.begin(session2, rng)
	Story.setup_fight(session2)
	var before: float = session2["level"]
	Story.use_continue(session2)
	Story.setup_fight(session2)
	_expect(session2["level"] < before and session2["story"]["continues"] == 1 and session2["story"]["idx"] == 0,
		"a continue replays the same fight a little easier")

	var problems: Array = []
	for id: String in Songs.ALL:
		problems.append_array(Songs.check(id))
	for p in problems:
		printerr("        ", p)
	_expect(problems.is_empty(), "every song's bars and patterns add up")
	var missing := false
	for id in stages + Songs.SCREENS.values():
		if not Songs.ALL.has(id):
			missing = true
	_expect(not missing, "every arena and menu screen has a song")
	var music := Music.new()
	var wav := music.render("victory")
	_expect(wav.data.size() > 20000 and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED, "the victory fanfare renders and plays once")
	_expect(music.render("title").loop_mode == AudioStreamWAV.LOOP_FORWARD, "the title theme renders as a loop")
	music.free()

	if failures == 0:
		print("All tests passed.")
	else:
		print("%d test(s) failed." % failures)
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("  ok    ", description)
	else:
		failures += 1
		printerr("  FAIL  ", description)
