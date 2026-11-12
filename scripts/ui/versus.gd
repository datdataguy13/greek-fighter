class_name VersusScreen
extends Node2D

# Story mode's "loading screen": who you are about to fight and where, what
# they have to say about it, a tip for beating them, and how far along the
# journey you are.

const PIP := 50.0
const PIP_GAP := 8.0

var game: Game
var time := 0.0
var t := 0
var fight := {}
var quote_lines := PackedStringArray()
var quote_len := 0
var tip_lines := PackedStringArray()
var stage_name := ""
var pips: Array[Portrait] = []


func _ready() -> void:
	Story.setup_fight(game.session)
	fight = Story.fight(game.session)
	quote_lines = UI.wrap(Story.quote(game.session), 28, 400.0)
	for line in quote_lines:
		quote_len += line.length()
	tip_lines = UI.wrap("TIP:  " + Story.DATA[fight["opp"]]["tip"], 22, 470.0)
	for s in StageArt.LIST:
		if s["id"] == fight["stage"]:
			stage_name = "%s  -  %s" % [s["name"], s["sub"]]
	var st: Dictionary = game.session["story"]
	var x0 := (UI.W - (Story.FIGHTS * PIP + (Story.FIGHTS - 1) * PIP_GAP)) * 0.5
	for i in Story.FIGHTS:
		var p := Portrait.new()
		p.size = Vector2(PIP, PIP)
		p.position = Vector2(x0 + i * (PIP + PIP_GAP), 628)
		p.zoom = 0.7
		p.flip = true
		p.border_w = 3.0
		# Beaten opponents are greyed out; the ones still to come stay a mystery.
		if i <= st["idx"]:
			p.set_look(Looks.L[st["ladder"][i]["opp"]])
		p.dim = i < st["idx"]
		p.mouth = 2 if i < st["idx"] else 0
		p.bg = Color("3a4468") if i <= st["idx"] else Color("23283c")
		add_child(p)
		pips.append(p)
	Music.play("versus")
	Music.prepare(fight["stage"])
	Sfx.play("gong", -6.0, 1.2)


func _physics_process(delta: float) -> void:
	time += delta
	t += 1
	if t > 30 and Controls.confirm():
		if (t - 30) * 2 < quote_len:
			t = 31 + quote_len / 2  # first press finishes the sentence
		else:
			Sfx.play("ok")
			game.goto("fight")
			return
	if t > 60 * 20:
		game.goto("fight")
		return
	queue_redraw()


func _draw() -> void:
	var st: Dictionary = game.session["story"]
	StageArt.draw(self, fight["stage"], 310.0 + sin(time * 0.3) * 60.0, time)
	draw_rect(Rect2(0, 0, UI.W, UI.H), Color(0.04, 0.03, 0.1, 0.62))
	var slide := 1.0 - pow(1.0 - minf(1.0, t / 22.0), 3.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, 110), Vector2(470, 110), Vector2(380, 610), Vector2(0, 610)]), Color(UI.RED, 0.5))
	draw_colored_polygon(PackedVector2Array([Vector2(UI.W, 110), Vector2(UI.W - 380, 110), Vector2(UI.W - 470, 610), Vector2(UI.W, 610)]), Color(UI.BLUE, 0.5))
	UI.halftone(self, Rect2(0, 110, UI.W, 500), Color(0, 0, 0, 0.16))

	var boss: bool = fight["kind"] == "boss"
	UI.centered(self, 56, Story.heading(game.session), 50, UI.RED if boss else UI.GOLD)
	UI.centered(self, 92, stage_name.to_upper(), 26, UI.CREAM)

	var ids: Array = game.session["ids"]
	for i in 2:
		var def: Dictionary = Roster.get_def(ids[i])
		var look: Dictionary = def["look"]
		var s: float = look.get("scale", 1.0) * 1.3
		var left := i == 0
		var x := lerpf(-260.0, 200.0, slide) if left else lerpf(UI.W + 260.0, UI.W - 200.0, slide)
		var pose := Poses.idle(time + i)
		Rig.draw_shadow(self, Vector2(x, 560), 0.0, s)
		Rig.draw(self, Transform2D(0.0, Vector2(s if left else -s, s), 0.0, Vector2(x, 560)), look, pose, {"time": time})
		var align := HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT
		var tx := 30.0 if left else UI.W - 30.0 - 300.0
		UI.text(self, Vector2(tx, 604), def["name"].to_upper(), 46, UI.CREAM, align, 300)
		UI.text(self, Vector2(tx, 628), ("YOU" if left else def["title"]).to_upper(), 20, UI.P_COL[i].lightened(0.4), align, 300, 3)

	if t > 14:
		var pop := 1.0 + 1.2 * maxf(0.0, 1.0 - (t - 14) / 10.0)
		draw_set_transform(Vector2(UI.W * 0.5, 215), -0.06, Vector2(pop, pop))
		var w := UI.width("VS", 150)
		UI.text(self, Vector2(-w * 0.5 + 6, 8), "VS", 150, UI.RED, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		UI.text(self, Vector2(-w * 0.5, 0), "VS", 150, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		draw_set_transform_matrix(Transform2D.IDENTITY)

	if t > 30:
		var h := 40.0 + quote_lines.size() * 33.0
		var r := Rect2(UI.W * 0.5 - 225.0, 268, 450, h)
		UI.bubble(self, r, Vector2(r.end.x + 46.0, r.end.y + 36.0), quote_lines, 28, (t - 30) * 2)
		var y := r.end.y + 66.0
		for line in tip_lines:
			UI.text(self, Vector2(0, y), line, 22, Color("9ad0ff"), HORIZONTAL_ALIGNMENT_CENTER, UI.W, 3)
			y += 26.0

	# The journey so far.
	for i in Story.FIGHTS:
		var p := pips[i].position
		if i == st["idx"]:
			var g := 4.0 + sin(time * 9.0) * 1.5
			draw_rect(Rect2(p - Vector2(g, g), Vector2(PIP, PIP) + Vector2(g, g) * 2.0), UI.GOLD, false, 5.0)
	UI.centered(self, 708, "PUNCH = FIGHT!", 20, Color("9aa4c0"))


# Crosses on beaten opponents and question marks on the ones still to come.
# They are drawn by a child node so they land on top of the portraits.
func _enter_tree() -> void:
	var over := Node2D.new()
	over.z_index = 1
	over.draw.connect(_draw_marks.bind(over))
	add_child(over)


func _draw_marks(over: Node2D) -> void:
	var st: Dictionary = game.session["story"]
	for i in pips.size():
		var p := pips[i].position
		if i < st["idx"]:
			over.draw_line(p + Vector2(8, 8), p + Vector2(PIP - 8, PIP - 8), UI.RED, 6.0, true)
			over.draw_line(p + Vector2(PIP - 8, 8), p + Vector2(8, PIP - 8), UI.RED, 6.0, true)
		elif i > st["idx"]:
			var last := i == Story.FIGHTS - 1
			UI.text(over, Vector2(p.x, p.y + 38), "!" if last else "?", 34, UI.RED if last else Color("9aa4c0"), HORIZONTAL_ALIGNMENT_CENTER, PIP)
