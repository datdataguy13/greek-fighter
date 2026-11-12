class_name FighterSim
extends RefCounted

# One fighter's game state and rules. No drawing and no engine input here:
# FightSim feeds it an Inp bitmask each tick, so matches can run headless.
# Positions are in pixels; y is 0 on the floor and negative in the air.

enum St { IDLE, PREJUMP, JUMP, LAND, DASH, BACKDASH, ATTACK, HITSTUN, BLOCKSTUN, LAUNCH, DOWN, GETUP, GRAB, GRABBED, KO, WIN }

const GRAVITY := 1.05
const KB_FRICTION := 0.80
const PREJUMP_FRAMES := 4
const DASH_FRAMES := 13
const BACKDASH_FRAMES := 15
const BUFFER := 9  # frames a button press stays live
const MOTION_WINDOW := 20
const MAX_JUGGLE := 3
const DOWN_FRAMES := 30
const GETUP_FRAMES := 16
const BODY_HALF := 34.0
const THROW_RANGE := 40.0  # gap allowed between the two bodies
const THROW_DMG := 110
const GRAB_FRAMES := 36
const GRAB_RELEASE := 18
const MAX_METER := 100.0
const METER_HIT := 0.075  # meter per point of damage dealt
const METER_HURT := 0.045  # ...taken
const METER_BLOCK := 0.02  # ...blocked, for both sides
const SCALING := [1.0, 1.0, 0.85, 0.75, 0.65, 0.55, 0.45, 0.4, 0.35, 0.3]
const BTN_NAME := {Inp.P: "P", Inp.K: "K", Inp.H: "H"}
const BTN_RANK := {Inp.P: 1, Inp.K: 2, Inp.H: 3}

var sim: FightSim
var idx := 0
var def: Dictionary
var opp: FighterSim
var sz := 1.0

var x := 0.0
var y := 0.0
var vx := 0.0
var vy := 0.0
var kvx := 0.0  # knockback sliding along the ground
var facing := 1
var hp := 0
var max_hp := 0
var meter := 0.0
var wins := 0

var st: St = St.IDLE
var t := 0  # frames in the current state
var crouch := false
var move := {}
var move_key := ""
var hits_done := 0
var next_hit_t := 0
var connected := false
var stun := 0
var combo := 0  # hits taken in the combo currently being suffered
var combo_dmg := 0
var juggle := 0
var soft := false  # an air hit that lands on the feet instead of knocking down
var throw_inv := 0
var inv := 0
var helpless := false
var pending_land := 3
var land_frames := 3
var jump_dir := 0
var grab_dmg := 0
var grab_back := false
var hit_low := false
var petrified := false
var proj_live := 0
var walk_phase := 0.0

var held := 0
var prev := 0
var age := {Inp.P: 99, Inp.K: 99, Inp.H: 99, Inp.S: 99}
var dirs: Array = []  # [numpad direction, frame it started], oldest first
var frame := 0
var dash_req := 0
var dash_req_frame := -99


func setup(p_sim: FightSim, p_idx: int, p_def: Dictionary) -> void:
	sim = p_sim
	idx = p_idx
	def = p_def
	sz = def["size"]
	max_hp = def["hp"]


func reset_round(p_x: float, p_facing: int) -> void:
	x = p_x
	y = 0.0
	vx = 0.0
	vy = 0.0
	kvx = 0.0
	facing = p_facing
	hp = max_hp
	st = St.IDLE
	t = 0
	crouch = false
	move = {}
	move_key = ""
	connected = false
	stun = 0
	combo = 0
	combo_dmg = 0
	juggle = 0
	throw_inv = 0
	inv = 0
	helpless = false
	petrified = false
	proj_live = 0
	held = 0
	prev = 0
	dirs = []
	dash_req = 0
	for b in age:
		age[b] = 99


# --- Input -----------------------------------------------------------------

# Forward/back axis relative to facing: +1 toward the opponent.
func axis() -> int:
	return (int(held & Inp.RIGHT != 0) - int(held & Inp.LEFT != 0)) * facing


func numpad() -> int:
	var v := int(held & Inp.UP != 0) - int(held & Inp.DOWN != 0)
	return 5 + axis() + 3 * v


# `aging` is false during hit-stop so buffered presses don't expire while frozen.
func read(inp: int, aging: bool) -> void:
	prev = held
	held = inp
	if aging:
		frame += 1
	for b in age:
		if (held & b) != 0 and (prev & b) == 0:
			age[b] = 0
		elif aging:
			age[b] = mini(age[b] + 1, 99)
	var d := numpad()
	if dirs.is_empty() or dirs.back()[0] != d:
		dirs.append([d, frame])
		if dirs.size() > 14:
			dirs.pop_front()
		# Double-tap forward or back (through neutral) asks for a dash.
		var n := dirs.size()
		if (d == 6 or d == 4) and n >= 3 and dirs[n - 2][0] == 5 and dirs[n - 3][0] == d \
				and frame - dirs[n - 2][1] <= 10 and dirs[n - 2][1] - dirs[n - 3][1] <= 10:
			dash_req = 1 if d == 6 else -1
			dash_req_frame = frame


func pressed(b: int) -> bool:
	return age[b] <= BUFFER


func consume(b: int) -> void:
	age[b] = 99


# True if `seq` was entered in order, ending on the most recent non-neutral
# direction, with each step no older than `window` frames.
func motion(seq: Array, window: int = MOTION_WINDOW) -> bool:
	var i := seq.size() - 1
	var end := frame  # when the direction being examined stopped being held
	var anchored := false
	for k in range(dirs.size() - 1, -1, -1):
		var d: int = dirs[k][0]
		if frame - end > window:
			return false
		if not anchored and d != 5:
			if d != seq[i]:
				return false
			anchored = true
			i -= 1
		elif anchored and d == seq[i]:
			i -= 1
		if i < 0:
			return true
		end = dirs[k][1]
	return false


# --- Per-tick update -------------------------------------------------------

func update(inp: int) -> void:
	read(inp, true)
	t += 1
	throw_inv = maxi(0, throw_inv - 1)
	inv = maxi(0, inv - 1)
	match st:
		St.IDLE:
			_idle()
		St.PREJUMP:
			vx = 0.0
			if t >= PREJUMP_FRAMES:
				st = St.JUMP
				t = 0
				y = -0.5
				vy = -def["jump"]
				vx = jump_dir * facing * def["jump_x"]
				kvx = 0.0
				helpless = false
				pending_land = 3
				sim.emit("jump", self)
		St.JUMP:
			_air()
		St.LAND:
			vx = 0.0
			if t >= land_frames:
				_to_idle()
		St.DASH:
			vx = facing * def["dash"]
			if t >= DASH_FRAMES:
				_to_idle()
		St.BACKDASH:
			vx = -facing * def["dash"] * 0.85
			if t >= BACKDASH_FRAMES:
				_to_idle()
		St.ATTACK:
			_attack()
		St.HITSTUN, St.BLOCKSTUN:
			vx = 0.0
			if t >= stun:
				_to_idle()
		St.DOWN:
			vx = 0.0
			if t >= DOWN_FRAMES:
				st = St.GETUP
				t = 0
				_end_combo()
		St.GETUP:
			if t >= GETUP_FRAMES:
				throw_inv = 10
				_to_idle()
		St.GRAB:
			_grab()
		St.KO, St.WIN:
			vx = 0.0
	_integrate()


func _integrate() -> void:
	if st == St.GRABBED:
		return
	if y < 0.0:
		vy += GRAVITY
		y += vy
		x += vx
		if y >= 0.0:
			y = 0.0
			vy = 0.0
			_on_land()
	else:
		x += vx + kvx
		kvx *= KB_FRICTION
		if absf(kvx) < 0.2:
			kvx = 0.0
		if st == St.IDLE:
			walk_phase += vx * facing * 0.05


func _on_land() -> void:
	match st:
		St.JUMP:
			_land(maxi(3, pending_land))
			sim.emit("land", self)
		St.ATTACK:
			_land(move["land_rec"])
			sim.emit("land", self)
		St.LAUNCH:
			vx = 0.0
			if hp <= 0:
				st = St.KO
				t = 0
				sim.emit("down", self)
			elif soft:
				_land(6)
			else:
				st = St.DOWN
				t = 0
				sim.emit("down", self)


func _land(frames: int) -> void:
	st = St.LAND
	t = 0
	land_frames = frames
	vx = 0.0
	helpless = false
	move = {}


func _to_idle() -> void:
	st = St.IDLE
	t = 0
	move = {}
	move_key = ""
	petrified = false
	crouch = (held & Inp.DOWN) != 0
	_end_combo()


func _end_combo() -> void:
	combo = 0
	combo_dmg = 0
	juggle = 0


func face_opponent() -> void:
	if opp.x > x + 1.0:
		facing = 1
	elif opp.x < x - 1.0:
		facing = -1


func _idle() -> void:
	face_opponent()
	crouch = (held & Inp.DOWN) != 0
	if _try_super() or _try_special() or _try_throw() or _try_normal(0):
		return
	if (held & Inp.UP) != 0:
		st = St.PREJUMP
		t = 0
		jump_dir = axis()
		crouch = false
		vx = 0.0
		return
	if dash_req != 0 and frame - dash_req_frame <= 4 and not crouch:
		st = St.DASH if dash_req > 0 else St.BACKDASH
		t = 0
		dash_req = 0
		sim.emit("dash", self)
		return
	var a := axis()
	if crouch or a == 0:
		vx = 0.0
	else:
		vx = facing * def["walk"] * (1.0 if a > 0 else -0.78)


func _air() -> void:
	if helpless:
		return
	var specials: Dictionary = def["specials"]
	if pressed(Inp.S) and specials.has("sa") and _can_start(specials["sa"]):
		consume(Inp.S)
		start(specials["sa"], "sa")
		return
	for b in [Inp.H, Inp.K, Inp.P]:
		if pressed(b):
			consume(b)
			start(def["normals"]["j" + BTN_NAME[b]], "j" + BTN_NAME[b])
			return


# --- Starting moves --------------------------------------------------------

func start(m: Dictionary, key: String) -> void:
	move = m
	move_key = key
	st = St.ATTACK
	t = 0
	hits_done = 0
	next_hit_t = 0
	connected = false
	if y == 0.0:
		vx = 0.0
	if m["super"]:
		meter = 0.0
		sim.start_super(self)
	elif m["special"]:
		gain(2.0)
	sim.emit("attack", self, {"move": m})


func _can_start(m: Dictionary) -> bool:
	if m.has("proj") and proj_live > 0 and not m["super"]:
		return false
	return (m["air"] == 1) == (y < 0.0)


func _try_super() -> bool:
	if meter < MAX_METER:
		return false
	var by_s := pressed(Inp.S) and motion([2, 5, 2], 26)
	var by_p := pressed(Inp.P) and motion([2, 3, 6, 2, 3, 6], 40)
	if not (by_s or by_p):
		return false
	consume(Inp.S if by_s else Inp.P)
	start(def["super"], "super")
	return true


func _try_special() -> bool:
	var specials: Dictionary = def["specials"]
	# Shortcut: the Special button with a direction.
	if pressed(Inp.S):
		var slot := "sn"
		if (held & Inp.DOWN) != 0:
			slot = "sd"
		elif axis() != 0:
			slot = "sf"
		if _can_start(specials[slot]):
			consume(Inp.S)
			start(specials[slot], slot)
			return true
	# Classic motions.
	if pressed(Inp.P) and motion([6, 2, 3]) and _can_start(specials["sf"]):
		consume(Inp.P)
		start(specials["sf"], "sf")
		return true
	if pressed(Inp.P) and motion([2, 3, 6]) and _can_start(specials["sn"]):
		consume(Inp.P)
		start(specials["sn"], "sn")
		return true
	if pressed(Inp.K) and motion([2, 1, 4]) and _can_start(specials["sd"]):
		consume(Inp.K)
		start(specials["sd"], "sd")
		return true
	return false


func _try_normal(min_rank: int) -> bool:
	for b in [Inp.H, Inp.K, Inp.P]:
		if BTN_RANK[b] > min_rank and pressed(b):
			consume(b)
			crouch = (held & Inp.DOWN) != 0
			var key: String = ("2" if crouch else "5") + BTN_NAME[b]
			start(def["normals"][key], key)
			return true
	return false


func _attack() -> void:
	var m := move
	var su: int = m["startup"]
	if m.has("dash") and t >= m["dash"][0] and t <= m["dash"][1]:
		vx = facing * m["dash"][2]
	elif y == 0.0:
		vx = 0.0
	if m.has("rise") and t == m["rise"][0]:
		vx = facing * m["rise"][1]
		vy = m["rise"][2]
		if y == 0.0:
			y = -0.5
	if m.has("proj") and t == su:
		sim.spawn(self, m)
	if m.has("teleport") and t == m["teleport"]["frame"]:
		_teleport(m["teleport"])
	if m.has("grab") and t == su + 1 and can_throw(m["grab"]["range"]):
		_begin_grab(m["grab"]["dmg"], false)
		return
	if connected and y == 0.0 and t > su and _try_cancel():
		return
	if t >= su + m["active"] + m["recovery"]:
		if y < 0.0:
			st = St.JUMP
			helpless = true
			pending_land = m["land_rec"]
		else:
			_to_idle()


# After a move connects: normals cancel into specials or chain up to a
# stronger normal; anything but a super can cancel into a super.
func _try_cancel() -> bool:
	if move["super"]:
		return false
	if _try_super():
		return true
	if move["special"] or not move["cancel"]:
		return false
	return _try_special() or _try_normal(move["rank"])


func _teleport(tp: Dictionary) -> void:
	if tp["mode"] == "behind":
		var side := 1.0 if opp.x >= x else -1.0
		x = opp.x + side * tp["dist"]
	else:
		x += facing * tp["dist"]
	x = clampf(x, FightSim.WALL, FightSim.STAGE_W - FightSim.WALL)
	face_opponent()
	sim.emit("teleport", self)


# --- Throws ----------------------------------------------------------------

func can_throw(reach: float) -> bool:
	if opp.y < 0.0 or opp.throw_inv > 0 or opp.inv > 0 or sim.phase != FightSim.Phase.FIGHT:
		return false
	if opp.st not in [St.IDLE, St.LAND, St.DASH, St.BACKDASH, St.ATTACK]:
		return false
	if opp.st == St.ATTACK and opp.move["super"]:
		return false
	return absf(opp.x - x) <= BODY_HALF * sz + BODY_HALF * opp.sz + reach


func _try_throw() -> bool:
	if not pressed(Inp.H) or axis() == 0 or crouch or not can_throw(THROW_RANGE):
		return false
	consume(Inp.H)
	_begin_grab(THROW_DMG, axis() < 0)
	return true


func _begin_grab(dmg: int, back: bool) -> void:
	st = St.GRAB
	t = 0
	vx = 0.0
	grab_dmg = dmg
	grab_back = back
	move = {}
	opp.st = St.GRABBED
	opp.t = 0
	opp.vx = 0.0
	opp.vy = 0.0
	opp.kvx = 0.0
	opp.move = {}
	sim.emit("grab", self)


func _grab() -> void:
	if t < GRAB_RELEASE:
		var u := float(t) / GRAB_RELEASE
		opp.x = lerpf(opp.x, x + facing * 62.0 * sz, 0.35)
		opp.y = -70.0 * u
	elif t == GRAB_RELEASE:
		var dir := -facing if grab_back else facing
		if grab_back:
			opp.x = x - facing * 40.0
		opp.x = clampf(opp.x, FightSim.WALL, FightSim.STAGE_W - FightSim.WALL)
		opp.take_throw(self, grab_dmg, dir)
	if t >= GRAB_FRAMES:
		_to_idle()


func take_throw(att: FighterSim, dmg: int, dir: int) -> void:
	hp = maxi(0, hp - dmg)
	combo += 1
	combo_dmg += dmg
	att.gain(dmg * METER_HIT)
	gain(dmg * METER_HURT)
	sim.hitstop = maxi(sim.hitstop, 10)
	sim.emit("hit", self, {"x": x, "y": y - 150.0 * sz, "power": dmg, "throw": true, "dmg": dmg, "move": "throw"})
	st = St.IDLE  # so _launch starts a fresh juggle count
	_launch(dir * 7.5, -10.0, false)
	juggle = MAX_JUGGLE


# --- Getting hit -----------------------------------------------------------

func hurtbox() -> Rect2:
	var r: Rect2
	if st == St.LAUNCH:
		r = Rect2(-46, -190, 92, 150)
	elif y < 0.0:
		r = Rect2(-34, -262, 68, 200)
	elif crouch and st in [St.IDLE, St.ATTACK, St.HITSTUN, St.BLOCKSTUN]:
		r = Rect2(-38, -198, 76, 198)
	else:
		r = Rect2(-34, -272, 68, 272)
	return Rect2(x + r.position.x * sz, y + r.position.y * sz, r.size.x * sz, r.size.y * sz)


func hittable(by_projectile: bool) -> bool:
	if sim.phase != FightSim.Phase.FIGHT or inv > 0 or hp <= 0:
		return false
	if st in [St.DOWN, St.GETUP, St.KO, St.GRAB, St.GRABBED, St.WIN]:
		return false
	if st == St.LAUNCH and juggle >= MAX_JUGGLE:
		return false
	if st == St.ATTACK:
		if move.has("inv") and t >= move["inv"][0] and t <= move["inv"][1]:
			return false
		if by_projectile and move.has("pinv") and t >= move["pinv"][0] and t <= move["pinv"][1]:
			return false
	return true


func can_block(level: String) -> bool:
	if y < 0.0 or st not in [St.IDLE, St.BLOCKSTUN] or axis() >= 0:
		return false
	var down := (held & Inp.DOWN) != 0
	return not ((level == "low" and not down) or (level == "high" and down))


# Returns 0 for a miss, 1 if blocked, 2 if it hit. `dir` is the way the blow pushes.
func receive(att: FighterSim, m: Dictionary, by_projectile: bool, dir: int) -> int:
	if not hittable(by_projectile):
		return 0
	var hit_y := y - (60.0 if m["level"] == "low" else 170.0) * sz
	if can_block(m["level"]):
		hp = maxi(1, hp - int(m["chip"]))
		st = St.BLOCKSTUN
		t = 0
		stun = m["blockstun"]
		_push(att, m["push"] * 0.9, dir, by_projectile)
		att.gain(m["dmg"] * METER_BLOCK)
		gain(m["dmg"] * METER_BLOCK)
		sim.hitstop = maxi(sim.hitstop, int(m["stop"]) - 2)
		sim.emit("block", self, {"x": x + facing * 40.0 * sz, "y": hit_y, "power": m["dmg"]})
		return 1

	var scale: float = SCALING[mini(combo, SCALING.size() - 1)]
	if m["super"]:
		scale = maxf(scale, 0.5)
	if m["level"] == "low" and def["traits"].has("heel"):
		scale *= 1.15
	var dmg := maxi(1, int(round(m["dmg"] * scale)))
	combo += 1
	combo_dmg += dmg
	hp -= dmg
	att.gain(dmg * METER_HIT)
	gain(dmg * METER_HURT)
	hit_low = m["level"] == "low"
	sim.hitstop = maxi(sim.hitstop, m["stop"])
	sim.emit("hit", self, {"x": x - dir * 10.0, "y": hit_y, "power": m["dmg"], "combo": combo, "dmg": dmg, "move": m["name"]})
	if hp <= 0:
		hp = 0
		_launch(dir * 8.0, -13.0, false)
		return 2
	var airborne := y < 0.0 or st == St.LAUNCH
	var launch: Vector2 = m["launch"]
	if airborne or m["kd"] or launch != Vector2.ZERO:
		var is_soft: bool = airborne and st != St.LAUNCH and not m["kd"] and launch == Vector2.ZERO
		if launch == Vector2.ZERO:
			launch = Vector2(5.0, -9.0) if airborne else Vector2(4.0, -7.5)
		_launch(dir * launch.x, launch.y, is_soft)
	else:
		st = St.HITSTUN
		t = 0
		stun = m["hitstun"]
		move = {}
		petrified = m.get("petrify", false)
		_push(att, m["push"], dir, by_projectile)
	return 2


func _launch(p_vx: float, p_vy: float, p_soft: bool) -> void:
	if st == St.LAUNCH:
		juggle += 1
	else:
		juggle = 0
	st = St.LAUNCH
	t = 0
	vx = p_vx
	vy = p_vy
	y = minf(y, -1.0)
	kvx = 0.0
	soft = p_soft
	crouch = false
	move = {}
	petrified = false


# Knockback slides the defender, unless they are cornered: then the attacker
# is pushed away instead so pressure can't go on forever.
func _push(att: FighterSim, amount: float, dir: int, by_projectile: bool) -> void:
	var cornered := (dir < 0 and x <= FightSim.WALL + 6.0) or (dir > 0 and x >= FightSim.STAGE_W - FightSim.WALL - 6.0)
	if cornered and not by_projectile and att.y == 0.0:
		att.kvx = -dir * amount
	else:
		kvx = dir * amount


func gain(amount: float) -> void:
	meter = minf(MAX_METER, meter + amount)


# --- Strike queries used by FightSim ----------------------------------------

func strike_ready() -> bool:
	if st != St.ATTACK or move["box"].size.x <= 0.0:
		return false
	var su: int = move["startup"]
	return t > su and t <= su + move["active"] and hits_done < move["hits"] and t >= next_hit_t


func strike_box() -> Rect2:
	var b: Rect2 = move["box"]
	var w := b.size.x * sz
	var left := x + b.position.x * sz if facing > 0 else x - (b.position.x + b.size.x) * sz
	return Rect2(left, y + b.position.y * sz, w, b.size.y * sz)


func strike_landed() -> void:
	hits_done += 1
	next_hit_t = t + int(move["gap"])
	connected = true
