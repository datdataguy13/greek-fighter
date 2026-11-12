class_name Game
extends Node

# Root of the game: owns the session (who is fighting where) and swaps
# between the title, fighter select, stage select and fight screens.

const LEVELS := [["EASY", 0.15], ["NORMAL", 0.5], ["HARD", 1.0]]

# mode: "story" (a ten-fight journey, see story.gd), "2p" (two humans),
# "cpu" (player 1 vs CPU) or "watch" (CPU vs CPU)
var session := {"mode": "2p", "ids": ["achilles", "zeus"], "stage": "olympus", "level": 0.5, "level_idx": 1}
var screen: Node


func _ready() -> void:
	Controls.setup()
	add_child(Sfx.new())
	add_child(Music.new())
	# Developer hooks for screenshots/tests: jump straight to a screen.
	for key in ["mode", "stage"]:
		if OS.has_environment("GF_" + key.to_upper()):
			session[key] = OS.get_environment("GF_" + key.to_upper())
	if OS.has_environment("GF_P1"):
		session["ids"] = [OS.get_environment("GF_P1"), OS.get_environment("GF_P2")]
	if session["mode"] == "story":
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		Story.begin(session, rng)
		session["story"]["idx"] = int(OS.get_environment("GF_FIGHT")) if OS.has_environment("GF_FIGHT") else 0
		Story.setup_fight(session)
	goto(OS.get_environment("GF_SCREEN") if OS.has_environment("GF_SCREEN") else "title")


func goto(name: String) -> void:
	if screen != null:
		screen.queue_free()
	match name:
		"select":
			screen = SelectScreen.new()
		"stage":
			screen = StageSelectScreen.new()
		"fight":
			screen = FightScreen.new()
		"versus":
			screen = VersusScreen.new()
		"story_intro", "ending":
			screen = StoryScreen.new()
			screen.set("kind", "ending" if name == "ending" else "intro")
		_:
			screen = TitleScreen.new()
	screen.set("game", self)
	add_child(screen)
