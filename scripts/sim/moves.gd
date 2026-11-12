class_name Moves
extends RefCounted

# Move data and the builders the roster uses to make it. A move is a plain
# Dictionary; FighterSim/FightSim interpret the fields. Frame counts are sim
# ticks (60 per second) and boxes are local to a fighter facing right with the
# feet at the origin (up is -y), before the fighter's size is applied.
#
# Common fields
#   anim                 animation name from Poses.ANIMS
#   startup/active/recovery
#   box                  Rect2 strike box (size 0 = no strike)
#   dmg, chip            damage on hit / when blocked
#   hitstun, blockstun   frames the defender is stuck
#   push                 knockback speed along the ground
#   level                "mid", "low" (block crouching), "high" (block standing)
#   hits, gap            multi-hit count and frames between hits
#   kd, launch           knock down / launch velocity (x away, y up is negative)
#   cancel, rank         can cancel into specials; normals chain to a higher rank
#   air                  0 ground only, 1 air only
#   stop                 hit-stop frames
# Optional fields
#   dash   [from, to, speed]     move forward during these frames
#   rise   [frame, vx, vy]       take off (uppercuts, dives)
#   inv / pinv  [from, to]       fully / projectile invulnerable frames
#   proj   {...}                 projectile spawned on the last startup frame
#   teleport {frame, mode, dist} "behind" the opponent or "dx" forward
#   grab   {range, dmg}          command grab attempted after startup
#   weapon                       weapon to show while the move plays
#   ai                           hint for the CPU: zone, rush, aa, close, esc, grab

const DEFAULTS := {
	"name": "", "anim": "jab", "startup": 5, "active": 3, "recovery": 10,
	"box": Rect2(), "dmg": 0, "chip": 0, "hitstun": 14, "blockstun": 10, "push": 5.0,
	"level": "mid", "hits": 1, "gap": 4, "kd": false, "launch": Vector2.ZERO,
	"cancel": false, "rank": 0, "air": 0, "special": false, "super": false,
	"land_rec": 4, "stop": 7, "ai": "",
}

const SUPER_SCALE := 0.9  # one knob for how hard every super hits

const PROJ_DEFAULTS := {
	"kind": "orb", "vx": 10.0, "vy": 0.0, "g": 0.0, "w": 56.0, "h": 40.0,
	"ox": 96.0, "oy": -196.0, "life": 110, "delay": 0, "anchor": "",
	"dmg": 60, "chip": 8, "hitstun": 17, "blockstun": 12, "push": 5.0, "level": "mid",
	"hits": 1, "gap": 5, "kd": false, "launch": Vector2.ZERO, "stop": 6, "super": false,
	"pierce": false, "at_opp": false,
}


static func mk(d: Dictionary) -> Dictionary:
	var m: Dictionary = DEFAULTS.duplicate()
	m.merge(d, true)
	if m.has("proj"):
		var p: Dictionary = PROJ_DEFAULTS.duplicate()
		p.merge(m["proj"], true)
		p["super"] = m["super"]
		p["name"] = m["name"]
		m["proj"] = p
	return m


static func _special(base: Dictionary, name: String, o: Dictionary) -> Dictionary:
	var out: Dictionary = base.duplicate(true)
	for key in o:
		if key == "proj" and out.has("proj"):
			out["proj"].merge(o[key], true)
		else:
			out[key] = o[key]
	out["name"] = name
	out["special"] = true
	return mk(out)


# --- Normals ---------------------------------------------------------------

# kind: "fist", "swing" (sword/club/axe) or "thrust" (spear/trident).
# power scales damage; speed shifts startup (-1 fast, +1 slow).
static func normals(kind: String, power: float, speed: int, o: Dictionary = {}) -> Dictionary:
	var reach: float = {"fist": 0.0, "swing": 22.0, "thrust": 34.0}[kind]
	var heavy := {
		"fist": {"anim": "hook", "startup": 9, "recovery": 16, "dmg": 84, "box": Rect2(40, -246, 112, 76)},
		"swing": {"anim": "swing", "startup": 12, "recovery": 20, "dmg": 88, "box": Rect2(35, -278, 145, 185)},
		"thrust": {"anim": "thrust", "startup": 12, "recovery": 24, "dmg": 78, "box": Rect2(50, -222, 198, 44)},
	}
	var n := {
		"5P": {"anim": "jab", "startup": 4, "active": 3, "recovery": 7, "dmg": 28, "hitstun": 14, "blockstun": 11,
			"push": 4.5, "box": Rect2(40, -224, 95 + reach, 44), "cancel": true, "rank": 1, "stop": 5},
		"5K": {"anim": "kick", "startup": 7, "active": 3, "recovery": 12, "dmg": 52, "hitstun": 18, "blockstun": 13,
			"push": 6.0, "box": Rect2(40, -188, 126, 58), "cancel": true, "rank": 2, "stop": 7},
		"5H": {"active": 4, "hitstun": 22, "blockstun": 16, "push": 8.0, "cancel": true, "rank": 3, "stop": 10},
		"2P": {"anim": "cjab", "startup": 4, "active": 3, "recovery": 7, "dmg": 24, "hitstun": 13, "blockstun": 10,
			"push": 4.5, "box": Rect2(40, -144, 95 + reach, 42), "cancel": true, "rank": 1, "stop": 5},
		"2K": {"anim": "ckick", "startup": 6, "active": 3, "recovery": 11, "dmg": 44, "hitstun": 16, "blockstun": 12,
			"push": 5.5, "box": Rect2(40, -54, 124, 48), "level": "low", "cancel": true, "rank": 2, "stop": 6},
		"2H": {"anim": "sweep", "startup": 10, "active": 4, "recovery": 24, "dmg": 72, "hitstun": 20, "blockstun": 15,
			"push": 6.0, "box": Rect2(40, -52, 144, 50), "level": "low", "kd": true, "rank": 3, "stop": 9},
		"jP": {"anim": "airstrike", "startup": 4, "active": 40, "recovery": 0, "dmg": 40, "hitstun": 16, "blockstun": 12,
			"push": 4.0, "box": Rect2(25, -182, 105 + reach, 114), "level": "high", "air": 1, "rank": 1, "stop": 6},
		"jK": {"anim": "airkick", "startup": 6, "active": 40, "recovery": 0, "dmg": 56, "hitstun": 18, "blockstun": 14,
			"push": 5.0, "box": Rect2(20, -114, 120, 86), "level": "high", "air": 1, "rank": 2, "stop": 7},
		"jH": {"anim": "airstrike", "startup": 9, "active": 40, "recovery": 0, "dmg": 78, "hitstun": 22, "blockstun": 16,
			"push": 6.0, "box": Rect2(25, -188, 118 + reach, 128), "level": "high", "air": 1, "rank": 3, "stop": 9},
	}
	n["5H"].merge(heavy[kind])
	var out := {}
	for key in n:
		var d: Dictionary = n[key]
		d["name"] = key
		if o.has(key):
			d.merge(o[key], true)
		d["dmg"] = int(round(d["dmg"] * power))
		d["chip"] = 0
		d["startup"] = maxi(3, d["startup"] + speed)
		out[key] = mk(d)
	return out


# --- Specials --------------------------------------------------------------

static func projectile(name: String, o: Dictionary = {}) -> Dictionary:
	return _special({"anim": "cast", "startup": 13, "active": 2, "recovery": 27, "ai": "zone", "proj": {}}, name, o)


static func uppercut(name: String, o: Dictionary = {}) -> Dictionary:
	return _special({
		"anim": "upper", "startup": 4, "active": 12, "recovery": 12, "dmg": 105, "chip": 10,
		"hitstun": 20, "blockstun": 14, "box": Rect2(15, -305, 100, 240), "launch": Vector2(4.5, -17.0),
		"rise": [4, 2.5, -17.0], "inv": [1, 7], "land_rec": 16, "stop": 10, "ai": "aa"}, name, o)


static func lunge(name: String, o: Dictionary = {}) -> Dictionary:
	return _special({
		"anim": "lunge", "startup": 10, "active": 8, "recovery": 21, "dmg": 90, "chip": 10,
		"hitstun": 20, "blockstun": 13, "box": Rect2(40, -218, 155, 64), "dash": [6, 18, 13.0],
		"kd": true, "launch": Vector2(7.0, -9.0), "push": 8.0, "stop": 9, "ai": "rush"}, name, o)


static func flurry(name: String, o: Dictionary = {}) -> Dictionary:
	return _special({
		"anim": "flurry", "startup": 8, "active": 20, "recovery": 17, "hits": 5, "gap": 4, "dmg": 20, "chip": 3,
		"hitstun": 17, "blockstun": 12, "box": Rect2(40, -236, 132, 96), "dash": [8, 28, 2.4],
		"push": 2.0, "stop": 3, "ai": "close"}, name, o)


static func teleport(name: String, o: Dictionary = {}) -> Dictionary:
	return _special({
		"anim": "vanish", "startup": 12, "active": 1, "recovery": 15, "inv": [7, 17],
		"teleport": {"frame": 12, "mode": "behind", "dist": 115.0}, "ai": "esc"}, name, o)


static func command_grab(name: String, o: Dictionary = {}) -> Dictionary:
	return _special({
		"anim": "grab", "startup": 6, "active": 2, "recovery": 36,
		"grab": {"range": 60.0, "dmg": 150}, "ai": "grab"}, name, o)


static func dive(name: String, o: Dictionary = {}) -> Dictionary:
	return _special({
		"anim": "dive", "air": 1, "startup": 5, "active": 60, "recovery": 0, "dmg": 60, "chip": 6,
		"level": "high", "hitstun": 18, "blockstun": 12, "box": Rect2(15, -74, 104, 84),
		"rise": [5, 9.0, 12.0], "land_rec": 10, "stop": 7, "ai": "air"}, name, o)


# A strike that lands where the opponent is standing after a delay.
static func remote(name: String, o: Dictionary = {}) -> Dictionary:
	return _special({
		"anim": "summon", "startup": 14, "active": 2, "recovery": 25, "ai": "zone",
		"proj": {"kind": "skybolt", "at_opp": true, "min": 150.0, "max": 660.0, "delay": 17, "vx": 0.0,
			"w": 84.0, "h": 560.0, "anchor": "ground", "life": 7, "dmg": 70, "pierce": true, "hitstun": 20}}, name, o)


static func beam(name: String, o: Dictionary = {}) -> Dictionary:
	return _special({
		"anim": "gaze", "startup": 15, "active": 4, "recovery": 28, "dmg": 36, "chip": 5,
		"hitstun": 46, "blockstun": 14, "box": Rect2(40, -252, 440, 44), "push": 0.5, "stop": 8,
		"petrify": true, "ai": "zone"}, name, o)


# A one-off special built from scratch.
static func custom(name: String, o: Dictionary) -> Dictionary:
	return _special({}, name, o)


static func super_move(base: Dictionary, o: Dictionary = {}) -> Dictionary:
	var out: Dictionary = base.duplicate(true)
	for key in o:
		if key == "proj" and out.has("proj"):
			out["proj"].merge(o[key], true)
		else:
			out[key] = o[key]
	out["super"] = true
	out["special"] = true
	out["dmg"] = int(round(out["dmg"] * SUPER_SCALE))
	if out.has("grab"):
		out["grab"]["dmg"] = int(round(out["grab"]["dmg"] * SUPER_SCALE))
	if out.has("proj"):
		out["proj"]["name"] = out["name"]
		out["proj"]["dmg"] = int(round(out["proj"]["dmg"] * SUPER_SCALE))
	if not out.has("inv"):
		out["inv"] = [1, out["startup"]]
	if out.has("proj"):
		out["proj"]["super"] = true
	return out
