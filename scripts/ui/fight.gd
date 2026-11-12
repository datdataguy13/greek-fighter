class_name FightScreen
extends Node2D

# The match itself: steps the FightSim from player/CPU input, then draws the
# stage, fighters, projectiles, effects and HUD from the sim's state.

const FLOOR := StageArt.FLOOR
const BAR_W := 470.0
const BAR_X := 120.0
const BAR_Y := 36.0
const BAR_H := 30.0
const PAUSE_ITEMS := ["RESUME", "QUIT TO MENU"]
const OVER_ITEMS := ["REMATCH", "CHANGE FIGHTERS", "MAIN MENU"]
const CONTINUE_SECS := 10

var game: Game
var sim: FightSim
var views := [FighterView.new(), FighterView.new()]
var cpus: Array = [null, null]
var portraits: Array[Portrait] = []
var stage_id := "olympus"
var cam_x := 310.0
var shake := 0.0
var time := 0.0
var fx: Array = []
var hp_lag := [1.0, 1.0]
var combos := [{"n": 0, "dmg": 0, "t": 0}, {"n": 0, "dmg": 0, "t": 0}]
var ko_flash := 0.0
var half_step := false
var paused := false
var menu_sel := 0
var over_t := 0
var quote := ""
var super_name := ""
var rng := RandomNumberGenerator.new()
var story := false
var over_items: Array = OVER_ITEMS
var gave_up := -1  # frames since the continue countdown ran out


func _ready() -> void:
	var s: Dictionary = game.session
	story = s["mode"] == "story"
	if story:
		Story.setup_fight(s)
	stage_id = s["stage"]
	Music.play(stage_id)
	sim = FightSim.new(Roster.get_def(s["ids"][0]), Roster.get_def(s["ids"][1]))
	rng.randomize()
	if s["mode"] == "cpu" or story:
		cpus[1] = Cpu.new(rng.randi(), s["level"])
	elif s["mode"] == "watch":
		cpus = [Cpu.new(rng.randi(), s["level"]), Cpu.new(rng.randi(), s["level"])]
	for i in 2:
		var p := Portrait.new()
		p.size = Vector2(88, 88)
		p.position = Vector2(20, 14) if i == 0 else Vector2(UI.W - 108, 14)
		p.flip = i == 1
		p.zoom = 1.25
		p.bg = UI.P_COL[i].darkened(0.35)
		p.set_look(sim.f[i].def["look"])
		add_child(p)
		portraits.append(p)
	for i in 2:
		views[i].update(sim.f[i], sim, 0.0)


func _exit_tree() -> void:
	sim.dispose()


func _label(i: int) -> String:
	return "CPU" if cpus[i] != null else "P%d" % (i + 1)


# --- update ----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	time += delta
	if gave_up >= 0:
		gave_up += 1
		if gave_up > 150:
			game.goto("title")
			return
	elif sim.phase == FightSim.Phase.OVER:
		over_t += 1
		if over_t > 50:
			_menu(over_items)
		if _counting() and (over_t - 50) % 60 == 0:
			if _count_left() <= 0:
				gave_up = 0
				Sfx.play("ko", -6.0)
			else:
				Sfx.play("move", -4.0, 0.8)
	elif Input.is_action_just_pressed("pause"):
		paused = not paused
		menu_sel = 0
		Sfx.play("ok" if paused else "back")
	if paused:
		_menu(PAUSE_ITEMS)
		queue_redraw()
		return

	# Half-speed for the first moments after a knockout.
	half_step = not half_step
	var slow := sim.phase == FightSim.Phase.KO and sim.end_how == "ko" and sim.phase_t < 46
	if not slow or half_step:
		var in0: int = cpus[0].think(sim, 0) if cpus[0] != null else Controls.read(0)
		var in1: int = cpus[1].think(sim, 1) if cpus[1] != null else Controls.read(1)
		sim.step(in0, in1)
		_handle_events()
		if sim.f.size() == 2:
			for i in 2:
				views[i].update(sim.f[i], sim, time)
		if sim.phase == FightSim.Phase.INTRO and sim.phase_t == 70:
			Sfx.play("gong", -6.0, 1.5)

	var target := clampf((sim.f[0].x + sim.f[1].x) * 0.5 - UI.W * 0.5, 0.0, FightSim.STAGE_W - UI.W)
	cam_x = lerpf(cam_x, target, 0.18)
	shake *= 0.84
	ko_flash = maxf(0.0, ko_flash - 0.06)
	for i in range(fx.size() - 1, -1, -1):
		fx[i]["t"] += 1
		if fx[i]["t"] >= fx[i]["life"]:
			fx.remove_at(i)
	for i in 2:
		var ratio := float(sim.f[i].hp) / sim.f[i].max_hp
		if sim.f[i].combo == 0:
			hp_lag[i] = maxf(ratio, hp_lag[i] - 0.012)
		hp_lag[i] = maxf(hp_lag[i], ratio)
		combos[i]["t"] = maxi(0, combos[i]["t"] - 1)
		portraits[i].mouth = 2 if sim.f[i].st in [FighterSim.St.HITSTUN, FighterSim.St.LAUNCH, FighterSim.St.DOWN, FighterSim.St.KO] else (3 if sim.f[i].st == FighterSim.St.WIN else 0)
		portraits[i].queue_redraw()
	queue_redraw()


func _add_fx(kind: String, x: float, y: float, life: int, extra: Dictionary = {}) -> void:
	var e := {"kind": kind, "wx": x, "wy": y, "t": 0, "life": life, "rot": rng.randf_range(-0.4, 0.4), "col": Color("ff9a2e"), "size": 1.0}
	e.merge(extra, true)
	fx.append(e)


func _handle_events() -> void:
	for e in sim.events:
		var who: int = e["who"]
		match e["t"]:
			"hit":
				views[who].hit_flash()
				var power: float = e["power"]
				var heavy := power >= 70.0
				_add_fx("spark", e["x"], e["y"], 14, {"size": clampf(0.55 + power / 100.0, 0.6, 1.7)})
				if heavy and rng.randf() < 0.45:
					_add_fx("word", e["x"], e["y"] - 70.0, 34, {"word": Fx.WORDS[rng.randi() % Fx.WORDS.size()],
						"col": Color("ffe14a"), "rot": rng.randf_range(-0.25, 0.25)})
				shake = maxf(shake, 12.0 if heavy else 5.0)
				Sfx.play("hit_heavy" if heavy else "hit_light", -5.0 if heavy else -8.0)
				var victim := sim.f[who]
				combos[1 - who] = {"n": victim.combo, "dmg": victim.combo_dmg, "t": 100}
			"block":
				_add_fx("block", e["x"], e["y"], 12)
				shake = maxf(shake, 3.0)
				Sfx.play("block")
			"attack":
				var m: Dictionary = e["move"]
				if m["special"] and not m["super"]:
					_add_fx("word", e["x"], e["y"] - 330.0 * sim.f[who].sz, 46, {"word": m["name"].to_upper() + "!", "size": 0.5,
						"col": UI.CREAM, "rot": 0.0})
				Sfx.play("whoosh", -12.0, 1.3 if m["rank"] == 1 else 1.0)
			"proj":
				Sfx.play("proj")
			"strike":
				shake = maxf(shake, 7.0)
				Sfx.play("zap", -6.0)
			"jump":
				_add_fx("dust", e["x"], 0.0, 14)
				Sfx.play("jump", -14.0)
			"land":
				_add_fx("dust", e["x"], 0.0, 14)
				Sfx.play("land", -10.0)
			"dash":
				_add_fx("dust", e["x"], 0.0, 16)
				Sfx.play("whoosh", -12.0, 0.8)
			"down":
				_add_fx("dust", e["x"], 0.0, 20, {"size": 1.6})
				shake = maxf(shake, 7.0)
				Sfx.play("land", -4.0, 0.7)
			"teleport":
				_add_fx("ring", e["x"], -140.0, 16, {"col": Color("b86af0")})
				Sfx.play("proj", -8.0, 0.6)
			"splash", "clash":
				_add_fx("ring", e["x"], e["y"], 14, {"col": Color("fff2a8"), "size": 0.7})
				Sfx.play("block", -10.0, 0.7)
			"grab":
				Sfx.play("whoosh", -6.0, 0.7)
			"super":
				super_name = e["name"]
				Sfx.play("super", -4.0)
			"ko":
				if e["how"] == "ko":
					ko_flash = 1.0
					shake = 18.0
					Sfx.play("ko", -2.0)
				else:
					Sfx.play("gong", -6.0)
			"round":
				Sfx.play("gong", -8.0)
			"match_over":
				over_t = 0
				menu_sel = 0
				if e["winner"] >= 0:
					var quotes: Array = sim.f[e["winner"]].def["quotes"]
					quote = quotes[rng.randi() % quotes.size()]
				# A fanfare when a human (or, in watch mode, anyone) wins.
				if e["winner"] >= 0 and (cpus[e["winner"]] == null or cpus[0] != null):
					Music.play("victory")
				else:
					Music.stop()
				if story and e["winner"] == 0:
					var last: bool = game.session["story"]["idx"] == Story.FIGHTS - 1
					over_items = ["SEE THE ENDING" if last else "NEXT FIGHT", "MAIN MENU"]
				elif story:
					over_items = ["CONTINUE", "GIVE UP"]


func _menu(items: Array) -> void:
	var d := Controls.menu_dir().y
	if d != 0:
		menu_sel = posmod(menu_sel + d, items.size())
		Sfx.play("move")
	if not Controls.confirm():
		return
	Sfx.play("ok")
	match items[menu_sel]:
		"RESUME":
			paused = false
		"NEXT FIGHT", "SEE THE ENDING":
			game.goto("ending" if Story.advance(game.session) else "versus")
		"CONTINUE":
			Story.use_continue(game.session)
			game.goto("fight")
		"GIVE UP":
			game.goto("title")
		"REMATCH":
			game.goto("fight")
		"CHANGE FIGHTERS":
			game.goto("select")
		"QUIT TO MENU", "MAIN MENU":
			game.goto("title")


# Story mode: after a loss the player has a few seconds to choose to continue.
func _counting() -> bool:
	return story and sim.phase == FightSim.Phase.OVER and sim.match_winner != 0 and over_t > 50 and gave_up < 0


func _count_left() -> int:
	return CONTINUE_SECS - (over_t - 50) / 60


# --- drawing ---------------------------------------------------------------

func _screen(wx: float, wy: float, off: Vector2) -> Vector2:
	return Vector2(wx - cam_x, FLOOR + wy) + off


func _draw() -> void:
	if sim.f.size() < 2:
		return
	var off := Vector2(sin(time * 71.0), cos(time * 53.0)) * shake
	StageArt.draw(self, stage_id, cam_x - off.x, time)

	if sim.superfreeze > 0:
		draw_rect(Rect2(0, 0, UI.W, UI.H), Color(0.02, 0.0, 0.08, 0.6))
		var o := sim.f[sim.super_owner]
		var c := _screen(o.x, -150.0 * o.sz, off)
		for i in 18:
			var a := i * TAU / 18.0 + time * 2.0
			var d := Vector2(cos(a), sin(a))
			draw_line(c + d * 120.0, c + d * 1500.0, Color(1, 0.85, 0.3, 0.35), 14.0)

	var order := [0, 1]
	if sim.f[0].st in [FighterSim.St.ATTACK, FighterSim.St.GRAB] and sim.f[1].st != FighterSim.St.ATTACK:
		order = [1, 0]
	for i in order:
		var f := sim.f[i]
		views[i].draw(self, f, _screen(f.x, f.y, off), FLOOR + off.y, time)
	for p in sim.projs:
		Fx.projectile(self, p, _screen(p["x"], p["y"], off), FLOOR, time)
	for e in fx:
		var pos := _screen(e["wx"], e["wy"], off)
		e["x"] = pos.x
		e["y"] = pos.y
		Fx.effect(self, e)
	if ko_flash > 0.0:
		draw_rect(Rect2(0, 0, UI.W, UI.H), Color(1, 1, 1, ko_flash * 0.8))

	_draw_hud()
	_draw_banner()
	if paused:
		_draw_pause()
	elif sim.phase == FightSim.Phase.OVER:
		_draw_over()


func _draw_hud() -> void:
	for i in 2:
		var f := sim.f[i]
		var x := BAR_X if i == 0 else UI.W - BAR_X - BAR_W
		var ratio := clampf(float(f.hp) / f.max_hp, 0.0, 1.0)
		# Both bars drain toward the outside edge, away from the timer.
		draw_rect(Rect2(x - 5, BAR_Y - 5, BAR_W + 10, BAR_H + 10), UI.INK)
		draw_rect(Rect2(x, BAR_Y, BAR_W, BAR_H), Color("5a1420"))
		var lag_w: float = BAR_W * hp_lag[i]
		var hp_w := BAR_W * ratio
		var low := ratio < 0.25 and fposmod(time, 0.4) < 0.2
		var col := Color("ff5a3a") if low else Color("ffd23a")
		if i == 0:
			draw_rect(Rect2(x + BAR_W - lag_w, BAR_Y, lag_w, BAR_H), Color("f2f2f2"))
			draw_rect(Rect2(x + BAR_W - hp_w, BAR_Y, hp_w, BAR_H), col)
		else:
			draw_rect(Rect2(x, BAR_Y, lag_w, BAR_H), Color("f2f2f2"))
			draw_rect(Rect2(x, BAR_Y, hp_w, BAR_H), col)
		draw_rect(Rect2(x, BAR_Y, BAR_W, 7), Color(1, 1, 1, 0.3))
		draw_rect(Rect2(x, BAR_Y + BAR_H - 6, BAR_W, 6), Color(0, 0, 0, 0.18))
		var align := HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		UI.text(self, Vector2(x, BAR_Y + BAR_H + 34), f.def["name"].to_upper(), 30, UI.CREAM, align, BAR_W)
		var name_w := UI.width(f.def["name"].to_upper(), 30)
		var tag_x := x + name_w + 14.0 if i == 0 else x + BAR_W - name_w - 14.0 - UI.width(_label(i), 22)
		UI.text(self, Vector2(tag_x, BAR_Y + BAR_H + 32), _label(i), 22, UI.P_COL[i].lightened(0.3))
		for w in FightSim.WINS_NEEDED:
			var wx := (UI.W * 0.5 - 86.0 - w * 30.0) if i == 0 else (UI.W * 0.5 + 86.0 + w * 30.0)
			draw_circle(Vector2(wx, BAR_Y + BAR_H + 22), 11.0, UI.INK, true, -1.0, true)
			draw_circle(Vector2(wx, BAR_Y + BAR_H + 22), 7.5, UI.GOLD if f.wins > w else Color("4a4458"), true, -1.0, true)

		# Super meter.
		var mw := 280.0
		var mx := 60.0 if i == 0 else UI.W - 60.0 - mw
		var full := f.meter >= FighterSim.MAX_METER
		draw_rect(Rect2(mx - 4, 672, mw + 8, 26), UI.INK)
		draw_rect(Rect2(mx, 676, mw, 18), Color("23283c"))
		var fill := mw * f.meter / FighterSim.MAX_METER
		var mcol := (Color("ffe14a") if fposmod(time, 0.3) < 0.15 else Color("ff9a2e")) if full else Color("3fc8f0")
		draw_rect(Rect2(mx if i == 0 else mx + mw - fill, 676, fill, 18), mcol)
		UI.text(self, Vector2(mx, 664), "SUPER READY!" if full else "SUPER", 22, UI.GOLD if full else Color("9aa4c0"), align, mw)

		# Combo counter on the attacker's side.
		var c: Dictionary = combos[i]
		if c["t"] > 0 and c["n"] >= 2:
			var a := minf(1.0, c["t"] / 20.0)
			var cx := 40.0 if i == 0 else UI.W - 440.0
			UI.text(self, Vector2(cx, 230), "%d HITS!" % c["n"], 64, Color(UI.GOLD, a), align, 400)
			UI.text(self, Vector2(cx, 262), "%d DAMAGE" % c["dmg"], 26, Color(UI.CREAM, a), align, 400)

	# Timer.
	var tc := Vector2(UI.W * 0.5, BAR_Y + 18)
	draw_circle(tc, 50.0, UI.INK, true, -1.0, true)
	draw_circle(tc, 44.0, Color("2a3350"), true, -1.0, true)
	draw_arc(tc, 44.0, 0.0, TAU, 40, UI.GOLD, 4.0, true)
	var secs := sim.seconds_left()
	UI.text(self, Vector2(tc.x - 60, tc.y + 22), "%02d" % secs, 58, UI.RED if secs <= 10 else UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, 120)


func _big(text: String, y: float, size: int, col: Color, pop_t: int) -> void:
	var pop := 1.0 + 0.7 * maxf(0.0, 1.0 - pop_t / 9.0)
	var w := UI.width(text, size)
	draw_set_transform(Vector2(UI.W * 0.5, y), -0.04, Vector2(pop, pop))
	UI.text(self, Vector2(-w * 0.5, 0), text, size, col, HORIZONTAL_ALIGNMENT_LEFT, -1, size / 5)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_banner() -> void:
	var t := sim.phase_t
	match sim.phase:
		FightSim.Phase.INTRO:
			if t < 70:
				var final := sim.f[0].wins == FightSim.WINS_NEEDED - 1 and sim.f[1].wins == FightSim.WINS_NEEDED - 1
				_big("FINAL ROUND" if final else "ROUND %d" % sim.round_no, 360, 130, UI.CREAM, t)
			else:
				_big("FIGHT!", 370, 190, UI.GOLD, t - 70)
		FightSim.Phase.FIGHT:
			if sim.superfreeze > 0:
				_big(super_name.to_upper() + "!", 250, 92, UI.GOLD, FightSim.SUPER_FREEZE - sim.superfreeze)
		FightSim.Phase.KO:
			if t < 90:
				if sim.end_how == "time":
					_big("TIME UP", 370, 170, UI.CREAM, t)
				else:
					_big("DOUBLE K.O.!" if sim.round_winner < 0 else "K.O.!", 380, 220, UI.RED, t)
			elif sim.round_winner < 0:
				_big("DRAW", 370, 170, UI.CREAM, t - 90)
			else:
				var w := sim.f[sim.round_winner]
				_big(w.def["name"].to_upper() + " WINS", 350, 130, UI.GOLD, t - 90)
				if w.hp == w.max_hp:
					_big("PERFECT!", 450, 90, UI.CREAM, t - 100)


func _move_list(i: int, x: float, y: float) -> void:
	var d: Dictionary = sim.f[i].def
	UI.text(self, Vector2(x, y), "%s  -  %s" % [d["name"].to_upper(), _label(i)], 34, UI.P_COL[i].lightened(0.35))
	var rows := [["SPECIAL", "sn", "or  D, DF, F + PUNCH"], ["FWD / BACK + SPECIAL", "sf", "or  F, D, DF + PUNCH"],
		["DOWN + SPECIAL", "sd", "or  D, DB, B + KICK"], ["SPECIAL IN THE AIR", "sa", ""]]
	var yy := y + 36.0
	for r in rows:
		if not d["specials"].has(r[1]):
			continue
		UI.text(self, Vector2(x, yy), d["specials"][r[1]]["name"].to_upper(), 26, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
		UI.text(self, Vector2(x + 20, yy + 22), r[0] + "    " + r[2], 18, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
		yy += 54.0
	UI.text(self, Vector2(x, yy), "SUPER: " + d["super"]["name"].to_upper(), 26, Color("ff9a2e"), HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
	UI.text(self, Vector2(x + 20, yy + 22), "DOWN, DOWN + SPECIAL   with a full meter", 18, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT, -1, 2)
	if cpus[i] != null:
		return
	var k: Dictionary = Controls.KEY_LABELS[i]
	UI.text(self, Vector2(x, yy + 62), "MOVE %s    PUNCH %s   KICK %s   HEAVY %s   SPECIAL %s" % [k["move"], k["p"], k["k"], k["h"], k["s"]],
		18, Color("9aa4c0"), HORIZONTAL_ALIGNMENT_LEFT, -1, 2)


func _draw_menu_items(items: Array, y: float) -> void:
	for i in items.size():
		var sel := i == menu_sel
		UI.text(self, Vector2(0, y + i * 50.0), ("> %s <" % items[i]) if sel else items[i], 44 if sel else 36,
			UI.GOLD if sel else UI.CREAM, HORIZONTAL_ALIGNMENT_CENTER, UI.W)


func _draw_pause() -> void:
	draw_rect(Rect2(0, 0, UI.W, UI.H), Color(0.03, 0.02, 0.08, 0.82))
	UI.centered(self, 100, "PAUSED", 90, UI.GOLD)
	_move_list(0, 70, 170)
	_move_list(1, 690, 170)
	UI.centered(self, 530, "PUNCH > KICK > HEAVY CHAINS INTO A COMBO.  HOLD BACK TO BLOCK.  FWD + HEAVY UP CLOSE THROWS.", 20, Color("9aa4c0"))
	_draw_menu_items(PAUSE_ITEMS, 600)


func _draw_over() -> void:
	var a := minf(1.0, over_t / 30.0)
	draw_rect(Rect2(0, 0, UI.W, UI.H), Color(0.03, 0.02, 0.08, 0.7 * a))
	if gave_up >= 0:
		draw_rect(Rect2(0, 0, UI.W, UI.H), Color(0.03, 0.02, 0.08, 0.5))
		UI.centered(self, 390, "GAME OVER", 170, UI.RED)
		return
	if story and sim.match_winner != 0:
		UI.centered(self, 180, "DEFEATED" if sim.match_winner == 1 else "DRAW GAME", 110, UI.RED)
		if sim.match_winner == 1:
			UI.centered(self, 236, "%s:  \"%s\"" % [sim.f[1].def["name"].to_upper(), quote], 30, Color("ffe9a8"))
		if over_t > 50:
			UI.centered(self, 330, "CONTINUE?", 60, UI.CREAM)
			UI.centered(self, 440, str(maxi(0, _count_left())), 120, UI.GOLD)
			_draw_menu_items(over_items, 530)
		return
	if sim.match_winner < 0:
		UI.centered(self, 230, "DRAW GAME", 130, UI.CREAM)
	else:
		var w: Dictionary = sim.f[sim.match_winner].def
		UI.centered(self, 210, w["name"].to_upper() + " WINS!", 130, UI.GOLD)
		UI.centered(self, 270, w["title"].to_upper(), 34, UI.CREAM)
		UI.centered(self, 350, "\"%s\"" % quote, 34, Color("ffe9a8"))
		if story:
			UI.centered(self, 410, "FIGHT %d OF %d WON" % [game.session["story"]["idx"] + 1, Story.FIGHTS], 30, Color("9ad0ff"))
	if over_t > 50:
		_draw_menu_items(over_items, 470)
