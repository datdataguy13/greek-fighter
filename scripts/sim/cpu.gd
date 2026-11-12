class_name Cpu
extends RefCounted

# Computer opponent. It plays through the same Inp bitmask a human does, so it
# can't do anything a player couldn't. `level` runs from 0 (easy) to 1 (hard)
# and mostly changes how often it blocks, follows up combos and how quickly it
# makes decisions.
#
# Internally it thinks in directions relative to its facing (FWD/BACK) and
# converts to left/right at the end.

const St := FighterSim.St
const FWD := Inp.RIGHT
const BACK := Inp.LEFT
const SLOT_BITS := {"sn": Inp.S, "sf": Inp.S | Inp.RIGHT, "sd": Inp.S | Inp.DOWN}

var rng := RandomNumberGenerator.new()
var level := 0.5
var queue: Array = []  # [relative bits, frames] steps being played out
var cooldown := 0
var hold := 0  # bits held between decisions (walking, guarding)
var guard_until := 0
var reacted_attack := -1
var reacted_jump := -1
var reacted_proj := -1
var followed_up := -1
var punished := -1
var punish_ok := false


func _init(p_seed: int = 1, p_level: float = 0.5) -> void:
	rng.seed = p_seed
	level = p_level


func think(sim: FightSim, i: int) -> int:
	var me := sim.f[i]
	if sim.phase != FightSim.Phase.FIGHT:
		queue.clear()
		hold = 0
		return 0
	var bits := _decide(sim, me, sim.f[1 - i])
	if me.facing < 0:
		var flipped := bits & ~(Inp.LEFT | Inp.RIGHT)
		if bits & Inp.LEFT:
			flipped |= Inp.RIGHT
		if bits & Inp.RIGHT:
			flipped |= Inp.LEFT
		return flipped
	return bits


func _chance(p: float) -> bool:
	return rng.randf() < p


# A usable special with this purpose ("" if none); random among several.
func _slot(me: FighterSim, tag: String) -> String:
	var found: Array = []
	for slot in ["sn", "sf", "sd"]:
		var m: Dictionary = me.def["specials"][slot]
		if m["ai"] == tag and not (m.has("proj") and me.proj_live > 0):
			found.append(slot)
	return "" if found.is_empty() else found[rng.randi() % found.size()]


func _reach(m: Dictionary) -> float:
	var box: Rect2 = m["box"]
	if m.has("grab"):
		return 150.0
	return box.end.x if box.size.x > 0.0 else 0.0


func _guard(opp: FighterSim) -> int:
	var low := false
	if opp.st == St.ATTACK and opp.y == 0.0:
		low = opp.move["level"] == "low" or (opp.crouch and opp.move["level"] != "high")
	elif opp.y == 0.0 and opp.crouch:
		low = true
	return BACK | (Inp.DOWN if low else 0)


func _decide(sim: FightSim, me: FighterSim, opp: FighterSim) -> int:
	var gap := absf(opp.x - me.x) - FighterSim.BODY_HALF * (me.sz + opp.sz)

	# 1. Play out a scripted sequence, unless we got interrupted.
	if not queue.is_empty():
		if me.st in [St.HITSTUN, St.LAUNCH, St.DOWN, St.GRABBED]:
			queue.clear()
			return 0
		var step: Array = queue[0]
		step[1] -= 1
		if step[1] <= 0:
			queue.pop_front()
		return step[0]

	match me.st:
		St.BLOCKSTUN:
			return _guard(opp)
		St.GETUP:
			return _guard(opp) if _chance(0.5 + 0.4 * level) else 0
		St.ATTACK:
			return _follow_up(me, opp, gap)
		St.JUMP:
			if me.helpless:
				return 0
			if me.vy > -3.0 and gap < 150.0 and opp.y == 0.0:
				return Inp.H if _chance(0.5) else Inp.K
			if me.def["specials"].has("sa") and me.vy > 0.0 and gap < 420.0 and _chance(0.04):
				return Inp.S
			return 0
		St.IDLE:
			pass
		_:
			return 0

	# 2. Reactions.
	var react := 0.3 + 0.55 * level
	for p in sim.projs:
		if p["owner"] == me.idx:
			continue
		var pd := absf(p["x"] - me.x)
		if p["delay"] > 0:
			if pd < p["w"] * 0.5 + 60.0 and reacted_proj != p["age"] + p["delay"] * 1000:
				reacted_proj = p["age"] + p["delay"] * 1000
				if _chance(react):
					if p["m"]["level"] == "low" or _chance(0.5):
						guard_until = sim.tick + p["delay"] + 10
						hold = BACK | (Inp.DOWN if p["m"]["level"] == "low" else 0)
					else:
						queue = [[FWD, 2], [0, 2], [FWD, 2]] if gap > 200.0 else [[BACK, 2], [0, 2], [BACK, 2]]
					return 0
		elif pd < 230.0 and (p["x"] - me.x) * p["vx"] < 0.0:
			var esc := _slot(me, "esc")
			if esc != "" and pd > 120.0 and _chance(0.25):
				return SLOT_BITS[esc]
			if _chance(react + 0.15):
				guard_until = sim.tick + 12
				hold = BACK
			break
	if opp.st == St.ATTACK and opp.t <= opp.move["startup"] + opp.move["active"]:
		var start := opp.frame - opp.t
		if reacted_attack != start and gap < _reach(opp.move) * opp.sz + 30.0:
			reacted_attack = start
			if opp.move.has("grab"):
				if _chance(react):
					queue = [[Inp.UP | BACK, 3]]
					return 0
			elif _chance(react):
				guard_until = sim.tick + 16
				hold = _guard(opp)
	if opp.y < 0.0 and opp.st in [St.JUMP, St.ATTACK] and gap < 230.0 and (me.x - opp.x) * opp.vx > 0.0:
		var jump_id := opp.frame - opp.t if opp.st == St.JUMP else reacted_jump
		if reacted_jump != jump_id:
			reacted_jump = jump_id
			var aa := _slot(me, "aa")
			if aa != "" and _chance(0.25 + 0.5 * level):
				queue = [[0, rng.randi_range(6, 12)], [SLOT_BITS[aa], 1]]
				return 0
			if _chance(react):
				guard_until = sim.tick + 26
				hold = BACK
	# Punish: the opponent is stuck recovering from something that missed or was blocked.
	var stuck := 0
	if opp.y == 0.0 and opp.st == St.ATTACK and opp.t > opp.move["startup"] + opp.move["active"]:
		stuck = opp.move["startup"] + opp.move["active"] + opp.move["recovery"] - opp.t
	elif opp.st == St.LAND:
		stuck = opp.land_frames - opp.t
	elif opp.st == St.JUMP and opp.helpless and opp.vy > 0.0 and opp.y > -140.0:
		stuck = 6 + opp.pending_land
	if stuck >= 7:
		var id := opp.frame - opp.t
		if punished != id:
			punished = id
			punish_ok = _chance(0.45 + 0.5 * level)
		if punish_ok:
			var normals: Dictionary = me.def["normals"]
			if stuck >= normals["5H"]["startup"] + 2 and gap < _reach(normals["5H"]) * me.sz - 45.0:
				return Inp.H
			if stuck >= normals["5K"]["startup"] + 1 and gap < _reach(normals["5K"]) * me.sz - 45.0:
				return Inp.K
			if gap < _reach(normals["5P"]) * me.sz - 45.0:
				return Inp.P
			var rush := _slot(me, "rush")
			if rush != "" and stuck >= 16 and gap < 300.0:
				return SLOT_BITS[rush]
			return FWD
	if guard_until > sim.tick:
		return _guard(opp) if (hold & Inp.DOWN) == 0 and opp.st == St.ATTACK else hold

	# 3. Neutral: pick something new every so often, otherwise keep doing it.
	cooldown -= 1
	if cooldown > 0:
		return hold
	cooldown = rng.randi_range(5, int(20.0 - 10.0 * level))
	hold = 0
	var opp_open := opp.y == 0.0 and opp.st not in [St.DOWN, St.GETUP, St.LAUNCH]

	if me.meter >= FighterSim.MAX_METER and opp_open and _chance(0.5):
		var sup: Dictionary = me.def["super"]
		var range_ok := gap < 110.0 if sup.has("grab") else (gap < 620.0 if sup.has("proj") else gap < _reach(sup) * me.sz + 120.0)
		if range_ok:
			queue = [[Inp.DOWN, 2], [0, 2], [Inp.DOWN, 2], [Inp.DOWN | Inp.S, 1]]
			return 0

	var r := rng.randf()
	# A stunned opponent out of reach (petrified, say) is an invitation.
	if opp.st == St.HITSTUN and opp.stun - opp.t > 16 and gap > 120.0 and gap < 520.0:
		var chase := _slot(me, "rush")
		if chase != "" and gap < 330.0:
			return SLOT_BITS[chase]
		queue = [[FWD, 2], [0, 2], [FWD, 2], [0, 9]]
		return 0
	var step_in := _slot(me, "esc")
	if step_in != "" and gap > 220.0 and r > 0.88:
		return SLOT_BITS[step_in]
	if opp.st in [St.DOWN, St.GETUP]:
		hold = FWD if gap > 110.0 else 0
		return hold
	if gap > 430.0:
		var zone := _slot(me, "zone")
		if zone != "" and r < 0.45:
			return SLOT_BITS[zone]
		if r < 0.8:
			hold = FWD
		elif r < 0.9:
			queue = [[FWD, 2], [0, 2], [FWD, 2]]
		else:
			queue = [[Inp.UP | FWD, 3]]
		return hold
	if gap > 140.0:
		var normals: Dictionary = me.def["normals"]
		var rush := _slot(me, "rush")
		var zone2 := _slot(me, "zone")
		if rush != "" and gap < 330.0 and r < 0.16:
			return SLOT_BITS[rush]
		if zone2 != "" and r < 0.30:
			return SLOT_BITS[zone2]
		if r < 0.48 and gap < _reach(normals["5H"]) * me.sz - 50.0:
			return Inp.H
		if r < 0.58 and gap < _reach(normals["2H"]) * me.sz - 40.0:
			return Inp.DOWN | Inp.H
		if r < 0.70:
			queue = [[Inp.UP | FWD, 3]]
			return 0
		if r < 0.94:
			hold = FWD
		else:
			hold = BACK
		return hold

	# Close range.
	var grab := _slot(me, "grab")
	if grab != "" and opp_open and r < 0.22:
		return SLOT_BITS[grab]
	if r < 0.45:
		return Inp.P if _chance(0.5) else (Inp.DOWN | Inp.K)
	if r < 0.55:
		return Inp.K
	if r < 0.67 and gap <= FighterSim.THROW_RANGE and opp_open:
		return FWD | Inp.H
	if r < 0.75:
		return Inp.DOWN | Inp.H
	var close := _slot(me, "close")
	if close != "" and r < 0.83:
		return SLOT_BITS[close]
	if r < 0.90:
		guard_until = sim.tick + 14
		hold = BACK | Inp.DOWN
		return hold
	if r < 0.95:
		queue = [[BACK, 2], [0, 2], [BACK, 2]]
		return 0
	hold = BACK
	return hold


# Mid-attack: when a normal connects, chain up or cancel into a special.
func _follow_up(me: FighterSim, opp: FighterSim, gap: float) -> int:
	var m := me.move
	if not me.connected or me.y < 0.0 or m["special"] or not m["cancel"]:
		return 0
	var id := me.frame - me.t
	if followed_up == id:
		return 0
	followed_up = id
	if not _chance(0.4 + 0.5 * level):
		return 0
	var down := Inp.DOWN if me.crouch else 0
	if m["rank"] == 1:
		return Inp.K | down
	if m["rank"] == 2 and _chance(0.7):
		return Inp.H
	if me.meter >= FighterSim.MAX_METER and opp.st == St.HITSTUN and not me.def["super"].has("grab"):
		queue = [[Inp.DOWN, 2], [0, 2], [Inp.DOWN, 2], [Inp.DOWN | Inp.S, 1]]
		return 0
	for tag in ["rush", "close", "aa"]:
		var slot := _slot(me, tag)
		if slot != "" and gap < 200.0:
			return SLOT_BITS[slot]
	return 0
