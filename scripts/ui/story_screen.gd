class_name StoryScreen
extends Node2D

# The two storybook pages of a journey: the opening ("intro") before the
# first fight and the ending after the last one.

var game: Game
var kind := "intro"
var time := 0.0
var t := 0
var me := ""
var title := ""
var lines: Array = []       # wrapped: one PackedStringArray per sentence
var total := 0
var stage_id := "olympus"
var done := false


func _ready() -> void:
	var st: Dictionary = game.session["story"]
	me = st["me"]
	var d: Dictionary = Story.DATA[me]
	var def: Dictionary = Roster.get_def(me)
	if kind == "ending":
		title = d["ending_title"]
		stage_id = st["ladder"][Story.FIGHTS - 1]["stage"]
		Music.play("ending")
	else:
		title = "The Journey of " + def["name"]
		stage_id = d["home"][0]
		Music.play("select")
	for sentence: String in d["ending" if kind == "ending" else "intro"]:
		var wrapped := UI.wrap(sentence, 30, 640.0)
		lines.append(wrapped)
		for w in wrapped:
			total += w.length()
		total += 24  # a pause between sentences


func _physics_process(delta: float) -> void:
	time += delta
	t += 1
	if t > 20 and Controls.confirm():
		if t * 1.5 < total:
			t = total  # first press shows the whole page
		elif kind == "intro":
			Sfx.play("ok")
			game.goto("versus")
			return
		elif not done:
			done = true
			t = total
			Sfx.play("gong", -6.0)
		else:
			Sfx.play("ok")
			game.goto("title")
			return
	queue_redraw()


func _draw() -> void:
	var st: Dictionary = game.session["story"]
	var def: Dictionary = Roster.get_def(me)
	var look: Dictionary = def["look"]
	StageArt.draw(self, stage_id, 310.0 + sin(time * 0.2) * 120.0, time)
	draw_rect(Rect2(0, 0, UI.W, UI.H), Color(0.04, 0.03, 0.1, 0.5))
	UI.panel(self, Rect2(470, 70, 760, 520), Color(0.07, 0.06, 0.14, 0.86), UI.GOLD, 5.0)

	var s: float = look.get("scale", 1.0) * 1.5
	var pose := Poses.idle(time)
	if kind == "ending":
		pose = Poses.pose("win").duplicate()
		pose["hf"] = pose["hf"] + Vector2(0, sin(time * 6.0) * 8.0)
	Rig.draw_shadow(self, Vector2(240, 640), 0.0, s)
	Rig.draw(self, Transform2D(0.0, Vector2(s, s), 0.0, Vector2(240, 640)), look, pose, {"time": time})

	if done:
		UI.text(self, Vector2(470, 250), "THE END", 130, UI.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 760)
		UI.text(self, Vector2(470, 330), "%s  -  %s" % [def["name"].to_upper(), title.to_upper()], 28, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 760)
		var c: int = st["continues"]
		var note := "A FLAWLESS JOURNEY: NO CONTINUES!" if c == 0 else "CONTINUES USED:  %d" % c
		UI.text(self, Vector2(470, 400), note, 30, Color("9ad0ff"), HORIZONTAL_ALIGNMENT_CENTER, 760)
		UI.text(self, Vector2(470, 470), "THANK YOU FOR PLAYING", 34, UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 760)
		UI.text(self, Vector2(470, 520), "Every fighter has a journey of their own.", 24, Color("c8d0e8"), HORIZONTAL_ALIGNMENT_CENTER, 760, 3)
		UI.centered(self, 690, "PUNCH = MAIN MENU", 22, Color("9aa4c0"))
		return

	UI.text(self, Vector2(510, 138), title.to_upper(), 50, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1)
	draw_line(Vector2(510, 156), Vector2(1190, 156), Color(UI.GOLD, 0.6), 3.0)
	var shown := int(t * 1.5)
	var y := 210.0
	for wrapped: PackedStringArray in lines:
		for w in wrapped:
			if shown <= 0:
				break
			UI.text(self, Vector2(510, y), w.substr(0, shown), 30, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, -1, 4)
			shown -= w.length()
			y += 37.0
		shown -= 24
		y += 20.0
	if t * 1.5 >= total and fposmod(time, 0.8) < 0.5:
		var prompt := "PUNCH = BEGIN THE JOURNEY" if kind == "intro" else "PUNCH = CONTINUE"
		UI.centered(self, 690, prompt, 24, UI.GOLD)
