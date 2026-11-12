class_name FightSim
extends RefCounted

# A whole match: two fighters, projectiles, hit detection, rounds. Advance it
# with step(input_p1, input_p2) once per tick. It never touches the engine's
# input or rendering, so tests and the balance tool can run it headless.

enum Phase { INTRO, FIGHT, KO, OVER }

const STAGE_W := 1900.0
const WALL := 70.0
const MAX_SEP := 1040.0  # keeps both fighters on one screen
const START_GAP := 380.0
const ROUND_SECONDS := 99
const INTRO_FRAMES := 110
const KO_FRAMES := 200
const WINS_NEEDED := 2
const SUPER_FREEZE := 42

var f: Array[FighterSim] = []
var projs: Array = []
var events: Array = []  # what happened this tick, for effects and sound
var phase: Phase = Phase.INTRO
var phase_t := 0
var round_no := 1
var timer := ROUND_SECONDS * 60
var hitstop := 0
var superfreeze := 0
var super_owner := -1
var round_winner := -1
var end_how := ""
var match_winner := -1
var tick := 0


func _init(def0: Dictionary, def1: Dictionary) -> void:
	for i in 2:
		var fighter := FighterSim.new()
		fighter.setup(self, i, def0 if i == 0 else def1)
		f.append(fighter)
	f[0].opp = f[1]
	f[1].opp = f[0]
	_start_round()


func _start_round() -> void:
	projs.clear()
	f[0].reset_round(STAGE_W * 0.5 - START_GAP * 0.5, 1)
	f[1].reset_round(STAGE_W * 0.5 + START_GAP * 0.5, -1)
	phase = Phase.INTRO
	phase_t = 0
	timer = ROUND_SECONDS * 60
	hitstop = 0
	superfreeze = 0
	round_winner = -1
	end_how = ""
	emit("round")


# Breaks the sim <-> fighter reference cycle so a finished match is freed.
func dispose() -> void:
	for fighter in f:
		fighter.opp = null
		fighter.sim = null
	f.clear()


func emit(type: String, who: FighterSim = null, data: Dictionary = {}) -> void:
	var e := {"t": type, "who": -1}
	if who != null:
		e["who"] = who.idx
		e["x"] = who.x
		e["y"] = who.y
	e.merge(data, true)
	events.append(e)


func seconds_left() -> int:
	return ceili(timer / 60.0)


func step(in0: int, in1: int) -> void:
	events.clear()
	tick += 1
	phase_t += 1
	var inputs := [in0, in1]
	match phase:
		Phase.INTRO:
			inputs = [0, 0]
			if phase_t >= INTRO_FRAMES:
				phase = Phase.FIGHT
				phase_t = 0
		Phase.KO:
			inputs = [0, 0]
			if _ko_phase():
				return
		Phase.OVER:
			inputs = [0, 0]

	if superfreeze > 0 or hitstop > 0:
		if superfreeze > 0:
			superfreeze -= 1
		else:
			hitstop -= 1
		f[0].read(inputs[0], false)
		f[1].read(inputs[1], false)
		return

	if phase == Phase.FIGHT:
		timer -= 1
	var first := tick % 2  # alternate who acts first so neither side has an edge
	f[first].update(inputs[first])
	f[1 - first].update(inputs[1 - first])
	_separate()
	_strikes()
	_projectiles()
	if phase == Phase.FIGHT:
		_check_round()


# --- Rounds ----------------------------------------------------------------

func _check_round() -> void:
	var dead0 := f[0].hp <= 0
	var dead1 := f[1].hp <= 0
	if dead0 or dead1:
		_end_round(-1 if dead0 and dead1 else (1 if dead0 else 0), "ko")
	elif timer <= 0:
		var r0 := float(f[0].hp) / f[0].max_hp
		var r1 := float(f[1].hp) / f[1].max_hp
		_end_round(-1 if is_equal_approx(r0, r1) else (0 if r0 > r1 else 1), "time")


func _end_round(winner: int, how: String) -> void:
	phase = Phase.KO
	phase_t = 0
	round_winner = winner
	end_how = how
	if winner >= 0:
		f[winner].wins += 1
	else:
		f[0].wins += 1
		f[1].wins += 1
	emit("ko", null, {"winner": winner, "how": how})


# Returns true when it started a new round (so the caller should stop this tick).
func _ko_phase() -> bool:
	if round_winner >= 0 and phase_t >= 70:
		var w := f[round_winner]
		if w.st == FighterSim.St.IDLE and w.y == 0.0:
			w.st = FighterSim.St.WIN
			w.t = 0
	if phase_t < KO_FRAMES:
		return false
	if f[0].wins >= WINS_NEEDED or f[1].wins >= WINS_NEEDED:
		phase = Phase.OVER
		phase_t = 0
		match_winner = -1
		if f[0].wins != f[1].wins:
			match_winner = 0 if f[0].wins > f[1].wins else 1
		emit("match_over", null, {"winner": match_winner})
		return false
	round_no += 1
	_start_round()
	return true


func start_super(who: FighterSim) -> void:
	superfreeze = SUPER_FREEZE
	super_owner = who.idx
	emit("super", who, {"name": who.move["name"]})


# --- Bodies ----------------------------------------------------------------

func _solid(q: FighterSim) -> bool:
	return q.st not in [FighterSim.St.GRAB, FighterSim.St.GRABBED, FighterSim.St.DOWN, FighterSim.St.KO, FighterSim.St.LAUNCH]


func _separate() -> void:
	var a := f[0]
	var b := f[1]
	var need := FighterSim.BODY_HALF * (a.sz + b.sz)
	var bodies_touch := _solid(a) and _solid(b) and absf(a.y - b.y) < 150.0
	if bodies_touch and absf(b.x - a.x) < need:
		var dir := 1.0 if b.x > a.x or (b.x == a.x and a.facing > 0) else -1.0
		var push := (need - absf(b.x - a.x)) * 0.5
		a.x -= dir * push
		b.x += dir * push
	a.x = clampf(a.x, WALL, STAGE_W - WALL)
	b.x = clampf(b.x, WALL, STAGE_W - WALL)
	# If a wall undid half of that, the fighter in the open takes the rest.
	if bodies_touch and absf(b.x - a.x) < need - 0.01:
		var dir2 := 1.0 if b.x > a.x or (b.x == a.x and a.facing > 0) else -1.0
		var rest := need - absf(b.x - a.x)
		if a.x <= WALL + 0.01 or a.x >= STAGE_W - WALL - 0.01:
			b.x = clampf(b.x + dir2 * rest, WALL, STAGE_W - WALL)
		else:
			a.x = clampf(a.x - dir2 * rest, WALL, STAGE_W - WALL)
	var sep := absf(a.x - b.x)
	if sep > MAX_SEP:
		var pull := (sep - MAX_SEP) * 0.5 * signf(b.x - a.x)
		a.x += pull
		b.x -= pull


# --- Hits ------------------------------------------------------------------

func _strikes() -> void:
	var landed: Array = []
	for i in 2:
		var a := f[i]
		var d := f[1 - i]
		if a.strike_ready() and d.hittable(false) and a.strike_box().intersects(d.hurtbox()):
			landed.append([a, d, a.move, a.facing])
	# Resolve after detection so two simultaneous hits trade.
	for hit in landed:
		var att: FighterSim = hit[0]
		var def: FighterSim = hit[1]
		if def.receive(att, hit[2], false, hit[3]) > 0 and att.st == FighterSim.St.ATTACK and att.move == hit[2]:
			att.strike_landed()


func spawn(owner: FighterSim, m: Dictionary) -> void:
	var p: Dictionary = m["proj"]
	var shots: Array = p.get("spread", [[p["vx"], p["vy"]]])
	for v in shots:
		var px: float = owner.x + owner.facing * p["ox"] * owner.sz
		var py: float = owner.y + p["oy"] * owner.sz
		if p["at_opp"]:
			px = owner.x + owner.facing * clampf(absf(owner.opp.x - owner.x), p["min"], p["max"])
			py = 0.0
		if p["anchor"] == "ground":
			py = 0.0
		projs.append({
			"owner": owner.idx, "kind": p["kind"], "x": clampf(px, 0.0, STAGE_W), "y": py,
			"vx": v[0] * owner.facing, "vy": v[1], "g": p["g"], "w": p["w"], "h": p["h"],
			"life": p["life"], "delay": p["delay"], "hits": p["hits"], "gap": 0,
			"dir": owner.facing, "age": 0, "m": p,
		})
		owner.proj_live += 1
	emit("proj", owner, {"kind": p["kind"]})


func proj_box(p: Dictionary) -> Rect2:
	if p["m"]["anchor"] == "ground":
		return Rect2(p["x"] - p["w"] * 0.5, -p["h"], p["w"], p["h"])
	return Rect2(p["x"] - p["w"] * 0.5, p["y"] - p["h"] * 0.5, p["w"], p["h"])


func _projectiles() -> void:
	for p in projs:
		if p["delay"] > 0:
			p["delay"] -= 1
			if p["delay"] == 0:
				emit("strike", null, {"x": p["x"], "y": p["y"], "kind": p["kind"], "who": p["owner"]})
			continue
		p["age"] += 1
		p["vy"] += p["g"]
		p["x"] += p["vx"]
		p["y"] += p["vy"]
		p["life"] -= 1
		p["gap"] = maxi(0, p["gap"] - 1)
		if p["g"] > 0.0 and p["y"] >= 0.0:
			p["life"] = 0
			emit("splash", null, {"x": p["x"], "y": 0.0, "kind": p["kind"]})
		if p["x"] < -120.0 or p["x"] > STAGE_W + 120.0:
			p["life"] = 0
		var target := f[1 - p["owner"]]
		if p["life"] > 0 and p["gap"] == 0 and target.hittable(true) and proj_box(p).intersects(target.hurtbox()):
			if target.receive(f[p["owner"]], p["m"], true, p["dir"]) > 0:
				p["hits"] -= 1
				p["gap"] = p["m"]["gap"]
				if p["hits"] <= 0:
					p["life"] = 0
	# Opposing projectiles cancel each other out.
	for i in projs.size():
		for k in range(i + 1, projs.size()):
			var a: Dictionary = projs[i]
			var b: Dictionary = projs[k]
			if a["owner"] == b["owner"] or a["life"] <= 0 or b["life"] <= 0 or a["delay"] > 0 or b["delay"] > 0:
				continue
			if a["m"]["pierce"] and b["m"]["pierce"]:
				continue
			if proj_box(a).intersects(proj_box(b)):
				if not a["m"]["pierce"]:
					a["life"] = 0
				if not b["m"]["pierce"]:
					b["life"] = 0
				emit("clash", null, {"x": (a["x"] + b["x"]) * 0.5, "y": (a["y"] + b["y"]) * 0.5})
	for i in range(projs.size() - 1, -1, -1):
		if projs[i]["life"] <= 0:
			f[projs[i]["owner"]].proj_live -= 1
			projs.remove_at(i)
