class_name SelectScreen
extends Node2D

# Fighter select. In 2-player mode each player moves their own cursor; against
# the CPU, player 1 picks both fighters one after the other.

const COLS := 7
const TILE := 96.0
const GAP := 12.0
const GRID_Y := 486.0

var game: Game
var defs: Array = []
var cur := [0, COLS - 1]
var locked := [false, false]
var time := 0.0
var done_t := 0
var tiles: Array[Portrait] = []
var story := false


func _ready() -> void:
	defs = Roster.all()
	story = game.session["mode"] == "story"
	Music.play("select")
	for i in 2:
		for k in defs.size():
			if defs[k]["id"] == game.session["ids"][i]:
				cur[i] = k
	for k in defs.size():
		var p := Portrait.new()
		p.size = Vector2(TILE, TILE)
		p.position = _tile_pos(k)
		p.zoom = 1.3
		p.bg = Color("3a4468")
		p.set_look(defs[k]["look"])
		add_child(p)
		tiles.append(p)


func _tile_pos(k: int) -> Vector2:
	var x0 := (UI.W - (COLS * TILE + (COLS - 1) * GAP)) * 0.5
	return Vector2(x0 + (k % COLS) * (TILE + GAP), GRID_Y + (k / COLS) * (TILE + GAP))


# Which controller drives each cursor right now (-1 = nobody yet).
func _driver(i: int) -> int:
	if game.session["mode"] == "2p":
		return i
	if i == 0:
		return 0
	if story:
		return -1
	return 0 if locked[0] else -1


func _physics_process(delta: float) -> void:
	time += delta
	if locked[0] and (locked[1] or story):
		done_t += 1
		if done_t > 40:
			game.session["ids"] = [defs[cur[0]]["id"], defs[cur[1]]["id"]]
			if story:
				var rng := RandomNumberGenerator.new()
				rng.randomize()
				Story.begin(game.session, rng)
				game.goto("story_intro")
			else:
				game.goto("stage")
		queue_redraw()
		return
	for i in [1, 0]:
		var pad := _driver(i)
		if pad < 0:
			continue
		if game.session["mode"] != "2p" and i == 0 and locked[0]:
			continue
		if locked[i]:
			if Controls.back(pad):
				locked[i] = false
				Sfx.play("back")
			continue
		var d := Controls.menu_dir(pad)
		if d != Vector2i.ZERO:
			var col := posmod(cur[i] % COLS + d.x, COLS)
			var row := posmod(cur[i] / COLS + d.y, 2)
			cur[i] = mini(row * COLS + col, defs.size() - 1)
			Sfx.play("move")
		if Controls.confirm(pad):
			locked[i] = true
			Sfx.play("ok")
			if game.session["mode"] != "2p":
				break
		elif Controls.back(pad):
			if game.session["mode"] != "2p" and i == 1:
				locked[0] = false
			else:
				game.goto("title")
			Sfx.play("back")
			return
	queue_redraw()


func _stat(def: Dictionary) -> Array:
	var n: Dictionary = def["normals"]
	var has_zone := false
	for m in def["specials"].values():
		if m["ai"] == "zone":
			has_zone = true
	return [
		["POWER", inverse_lerp(66.0, 106.0, n["5H"]["dmg"])],
		["SPEED", inverse_lerp(3.2, 5.6, def["walk"])],
		["HEALTH", inverse_lerp(820.0, 1200.0, def["hp"])],
		["RANGE", clampf(inverse_lerp(140.0, 270.0, n["5H"]["box"].end.x) * 0.7 + (0.3 if has_zone else 0.0), 0.0, 1.0)],
	]


func _draw() -> void:
	draw_rect(Rect2(0, 0, UI.W, UI.H), Color("1c2340"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(560, 0), Vector2(720, UI.H), Vector2(0, UI.H)]), Color("5a1a24"))
	UI.halftone(self, Rect2(0, 0, UI.W, UI.H), Color(1, 1, 1, 0.05), 30.0)
	draw_line(Vector2(560, 0), Vector2(720, UI.H), UI.INK, 8.0)
	UI.centered(self, 62, "CHOOSE YOUR FIGHTER", 60, UI.GOLD)

	var two_p: bool = game.session["mode"] == "2p"
	for i in 2:
		var def: Dictionary = defs[cur[i]]
		var look: Dictionary = def["look"]
		var active: bool = _driver(i) >= 0 or locked[i]
		var left := i == 0
		var px := 150.0 if left else UI.W - 150.0
		var s: float = look.get("scale", 1.0) * 1.12
		var pose := Poses.pose("win") if locked[i] else Poses.idle(time + i)
		if active:
			Rig.draw_shadow(self, Vector2(px, 440), 0.0, s)
			Rig.draw(self, Transform2D(0.0, Vector2(s if left else -s, s), 0.0, Vector2(px, 440)), look, pose, {"time": time})
		var tx := 300.0 if left else UI.W - 300.0 - 330.0
		var align := HORIZONTAL_ALIGNMENT_LEFT if left else HORIZONTAL_ALIGNMENT_RIGHT
		var who := ("P%d" % (i + 1)) if (two_p or i == 0) else "CPU"
		if game.session["mode"] == "watch":
			who = "CPU %d" % (i + 1)
		if story and i == 1:
			UI.text(self, Vector2(tx, 128), "STORY MODE", 30, UI.GOLD, align, 330)
			UI.text(self, Vector2(tx, 196), "10 FIGHTS", 66, UI.CREAM, align, 330)
			var yy2 := 236.0
			for line in ["Battle across Greece, from the", "Cyclops' cave to Mount Olympus.", "",
					"Every fighter has a rival waiting,", "a final battle to win, and an", "ending of their own."]:
				UI.text(self, Vector2(tx, yy2), line, 22, Color("e8e0d0"), align, 330, 2)
				yy2 += 26.0
			UI.text(self, Vector2(tx, yy2 + 20.0), "LOSE A FIGHT? YOU CAN CONTINUE.", 20, Color("9ad0ff"), align, 330, 2)
			continue
		UI.text(self, Vector2(tx, 128), who, 30, UI.P_COL[i].lightened(0.35), align, 330)
		if not active:
			UI.text(self, Vector2(tx, 250), "...", 60, Color("9aa4c0"), align, 330)
			continue
		UI.text(self, Vector2(tx, 188), def["name"].to_upper(), 66, UI.CREAM, align, 330)
		UI.text(self, Vector2(tx, 220), def["title"].to_upper(), 24, UI.GOLD, align, 330, 3)
		UI.text(self, Vector2(tx, 246), def["style"].to_upper(), 20, Color("9ad0ff"), align, 330, 3)
		var yy := 276.0
		for line in def["tagline"].split(". "):
			UI.text(self, Vector2(tx, yy), line.trim_suffix(".") + ".", 19, Color("e8e0d0"), align, 330, 2)
			yy += 22.0
		yy += 10.0
		for st in _stat(def):
			var bx := tx + 86.0 if left else tx + 330.0 - 86.0 - 150.0
			UI.text(self, Vector2(tx, yy + 12), st[0], 18, Color("c8d0e8"), align, 330, 2)
			draw_rect(Rect2(bx - 2, yy - 2, 154, 16), UI.INK)
			draw_rect(Rect2(bx, yy, 150, 12), Color("23283c"))
			draw_rect(Rect2(bx, yy, 150.0 * clampf(st[1], 0.08, 1.0), 12), UI.P_COL[i].lightened(0.2))
			yy += 22.0
		if locked[i]:
			UI.text(self, Vector2(tx, 452), "READY!", 40, UI.GOLD, align, 330)

	# Cursor frames sit just outside each tile so they show around the portraits.
	for i in 2:
		if _driver(i) < 0 and not locked[i]:
			continue
		var p := _tile_pos(cur[i])
		var grow := 5.0 + (0.0 if locked[i] else sin(time * 10.0) * 2.0)
		var inset := 0.0 if i == 0 else 5.0
		draw_rect(Rect2(p - Vector2(grow + inset, grow + inset), Vector2(TILE, TILE) + Vector2(grow + inset, grow + inset) * 2.0), UI.P_COL[i], false, 6.0)
		var tag := ("P%d" % (i + 1)) if (two_p or i == 0) else "CPU"
		UI.text(self, p + Vector2(0 if i == 0 else TILE - 44, -10), tag, 22, UI.P_COL[i].lightened(0.35), HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
	UI.centered(self, 712, "PUNCH = SELECT      KICK = BACK", 20, Color("9aa4c0"))
