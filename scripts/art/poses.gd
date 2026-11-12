class_name Poses
extends RefCounted

# Pose library for the Rig. A pose places the hips, feet and hands (facing
# right, feet-centre at the origin, up is -y); the rig solves the rest.
#
#   hip/ff/fb/hf/hb  positions of pelvis, front/back foot, front/back hand
#   lean, head, rot  torso lean, extra head tilt, whole-body rotation (degrees)
#   wa / wt / wb     weapon angle for swung / thrust / bow weapons (degrees)
#   mouth            0 neutral, 1 yell, 2 hurt, 3 grin, 4 out cold
#   bf               1 = draw the back arm in front of the torso
#   draw             0..1 bow string pull

const G := -10.0  # ankle height of a planted foot

# The numbers below were authored for a 121-unit standing hip height. fit()
# re-targets them to the rig's actual leg length, so legs can be lengthened or
# shortened in rig.gd without re-authoring every pose.
const AUTHORED_HIP := 121.0

const STAND := {
	"hip": Vector2(0, -121), "lean": 6.0, "head": 0.0, "rot": 0.0,
	"ff": Vector2(38, G), "fb": Vector2(-46, G),
	"hf": Vector2(54, -176), "hb": Vector2(20, -152),
	"wa": -60.0, "wt": -18.0, "wb": -90.0, "mouth": 0, "bf": 0.0, "draw": 0.0,
}

# name -> [base pose name, overrides]
const DEFS := {
	"stand": ["", {}],
	"crouch": ["stand", {"hip": Vector2(-4, -62), "lean": 20.0, "ff": Vector2(46, G), "fb": Vector2(-40, G), "hf": Vector2(56, -112), "hb": Vector2(24, -96), "wa": -50.0, "wt": -12.0}],
	"prejump": ["stand", {"hip": Vector2(0, -98), "lean": 12.0, "hf": Vector2(40, -140), "hb": Vector2(0, -130)}],
	"jump_up": ["stand", {"hip": Vector2(0, -126), "lean": 4.0, "ff": Vector2(26, -56), "fb": Vector2(-20, -40), "hf": Vector2(40, -190), "hb": Vector2(-14, -166)}],
	"jump_fall": ["stand", {"hip": Vector2(0, -126), "lean": 2.0, "ff": Vector2(32, -30), "fb": Vector2(-30, -20), "hf": Vector2(50, -206), "hb": Vector2(-28, -186)}],
	"dash_f": ["stand", {"hip": Vector2(10, -108), "lean": 26.0, "ff": Vector2(52, G), "fb": Vector2(-58, -22), "hf": Vector2(62, -150), "hb": Vector2(-30, -130)}],
	"dash_b": ["stand", {"hip": Vector2(-8, -116), "lean": -10.0, "ff": Vector2(54, -24), "fb": Vector2(-30, G), "hf": Vector2(50, -172), "hb": Vector2(8, -150)}],
	"block": ["stand", {"hip": Vector2(-6, -118), "lean": -6.0, "head": 6.0, "hf": Vector2(42, -198), "hb": Vector2(36, -170), "wa": -85.0, "wt": -80.0, "bf": 1.0}],
	"block_crouch": ["crouch", {"hip": Vector2(-8, -62), "lean": 10.0, "hf": Vector2(46, -130), "hb": Vector2(40, -106), "wa": -80.0, "wt": -75.0, "bf": 1.0}],
	"hit_high": ["stand", {"hip": Vector2(-10, -118), "lean": -20.0, "head": -18.0, "ff": Vector2(34, G), "fb": Vector2(-46, G), "hf": Vector2(26, -150), "hb": Vector2(-34, -150), "mouth": 2}],
	"hit_low": ["stand", {"hip": Vector2(-14, -110), "lean": 30.0, "head": 14.0, "hf": Vector2(30, -118), "hb": Vector2(8, -112), "mouth": 2}],
	"hit_crouch": ["crouch", {"hip": Vector2(-12, -62), "lean": 4.0, "head": -14.0, "hf": Vector2(30, -100), "hb": Vector2(-20, -90), "mouth": 2}],
	"air_hit": ["stand", {"hip": Vector2(0, -110), "lean": -10.0, "head": -20.0, "ff": Vector2(32, -30), "fb": Vector2(-26, -22), "hf": Vector2(34, -206), "hb": Vector2(-44, -190), "mouth": 2}],
	"down": ["stand", {"hip": Vector2(0, -28), "lean": 0.0, "rot": -90.0, "head": -8.0, "ff": Vector2(-14, 112), "fb": Vector2(-14, 56), "hf": Vector2(-16, -80), "hb": Vector2(-16, -150), "wa": 96.0, "wt": 96.0, "wb": 96.0, "mouth": 4}],
	"win": ["stand", {"hip": Vector2(0, -123), "lean": -3.0, "head": -6.0, "hf": Vector2(34, -270), "hb": Vector2(-24, -128), "wa": -90.0, "wt": -90.0, "mouth": 3}],
	"lose": ["stand", {"hip": Vector2(-4, -116), "lean": 24.0, "head": 20.0, "hf": Vector2(30, -110), "hb": Vector2(0, -108), "mouth": 2}],
	"grabbed": ["stand", {"hip": Vector2(0, -118), "lean": -14.0, "head": -16.0, "hf": Vector2(30, -130), "hb": Vector2(-30, -130), "mouth": 2}],

	"jab_w": ["stand", {"lean": 3.0, "hf": Vector2(34, -180), "hb": Vector2(26, -158)}],
	"jab_h": ["stand", {"hip": Vector2(8, -121), "lean": 13.0, "hf": Vector2(120, -182), "hb": Vector2(8, -150), "wa": -8.0, "wt": 0.0, "mouth": 1}],
	"kick_w": ["stand", {"hip": Vector2(-6, -121), "lean": -6.0, "ff": Vector2(36, -74), "hf": Vector2(40, -170), "hb": Vector2(-10, -150)}],
	"kick_h": ["stand", {"hip": Vector2(-12, -122), "lean": -24.0, "ff": Vector2(126, -132), "fb": Vector2(-28, G), "hf": Vector2(16, -160), "hb": Vector2(-40, -150), "mouth": 1}],
	"swing_w": ["stand", {"hip": Vector2(-4, -121), "lean": -8.0, "hf": Vector2(-16, -252), "hb": Vector2(30, -160), "wa": -125.0, "mouth": 1}],
	"swing_h": ["stand", {"hip": Vector2(14, -116), "lean": 24.0, "ff": Vector2(54, G), "hf": Vector2(104, -138), "hb": Vector2(-10, -140), "wa": 38.0, "mouth": 1}],
	"thrust_w": ["stand", {"hip": Vector2(-6, -120), "lean": -4.0, "hf": Vector2(-14, -172), "hb": Vector2(44, -164), "wt": 0.0, "wa": 0.0}],
	"thrust_h": ["stand", {"hip": Vector2(22, -114), "lean": 22.0, "ff": Vector2(66, G), "fb": Vector2(-46, G), "hf": Vector2(118, -170), "hb": Vector2(-6, -146), "wt": 0.0, "wa": 0.0, "mouth": 1}],
	"hook_w": ["stand", {"hip": Vector2(-4, -121), "lean": -4.0, "hf": Vector2(-6, -172), "hb": Vector2(44, -172)}],
	"hook_h": ["stand", {"hip": Vector2(18, -116), "lean": 26.0, "ff": Vector2(56, G), "hf": Vector2(114, -188), "hb": Vector2(-12, -146), "mouth": 1}],
	"cjab_h": ["crouch", {"lean": 24.0, "hf": Vector2(114, -110), "wa": -6.0, "wt": 0.0, "mouth": 1}],
	"ckick_w": ["crouch", {"ff": Vector2(50, -22)}],
	"ckick_h": ["crouch", {"hip": Vector2(-12, -58), "lean": 6.0, "ff": Vector2(122, -16), "mouth": 1}],
	"sweep_h": ["crouch", {"hip": Vector2(-20, -52), "lean": -14.0, "ff": Vector2(140, -12), "hb": Vector2(-48, -42), "hf": Vector2(20, -100), "mouth": 1}],
	"airkick_h": ["jump_up", {"lean": 12.0, "ff": Vector2(100, -44), "fb": Vector2(-30, -74), "hf": Vector2(30, -176), "hb": Vector2(-30, -170), "mouth": 1}],
	"airstrike_w": ["jump_up", {"hf": Vector2(10, -250), "wa": -110.0, "wt": -60.0}],
	"airstrike_h": ["jump_up", {"lean": 20.0, "hf": Vector2(98, -112), "wa": 50.0, "wt": 38.0, "ff": Vector2(20, -60), "fb": Vector2(-34, -50), "mouth": 1}],
	"cast_w": ["stand", {"lean": -10.0, "hf": Vector2(-18, -182), "hb": Vector2(-8, -170), "bf": 1.0}],
	"cast_h": ["stand", {"hip": Vector2(10, -118), "lean": 16.0, "hf": Vector2(112, -176), "hb": Vector2(88, -160), "wa": -10.0, "wt": 0.0, "bf": 1.0, "mouth": 1}],
	"summon_h": ["stand", {"lean": -6.0, "head": -10.0, "hf": Vector2(26, -274), "hb": Vector2(40, -160), "wa": -90.0, "wt": -90.0, "mouth": 1}],
	"upper_w": ["crouch", {"hip": Vector2(0, -78), "lean": 22.0, "hf": Vector2(34, -92), "hb": Vector2(10, -100), "wa": -30.0, "wt": -40.0}],
	"upper_h": ["jump_up", {"hip": Vector2(0, -124), "lean": -6.0, "head": -12.0, "hf": Vector2(40, -282), "hb": Vector2(-10, -150), "wa": -82.0, "wt": -82.0, "ff": Vector2(26, -64), "fb": Vector2(-8, -14), "mouth": 1}],
	"lunge_w": ["stand", {"hip": Vector2(-10, -112), "lean": 10.0, "hf": Vector2(-12, -162), "hb": Vector2(30, -150), "wt": 0.0, "wa": -10.0}],
	"lunge_h": ["stand", {"hip": Vector2(26, -104), "lean": 34.0, "ff": Vector2(72, G), "fb": Vector2(-62, G), "hf": Vector2(126, -150), "hb": Vector2(-20, -130), "wt": 0.0, "wa": -4.0, "mouth": 1}],
	"tackle_h": ["stand", {"hip": Vector2(20, -100), "lean": 38.0, "ff": Vector2(60, G), "fb": Vector2(-60, G), "hf": Vector2(62, -128), "hb": Vector2(74, -150), "bf": 1.0, "wa": -70.0, "wt": -60.0, "mouth": 1}],
	"flurry_a": ["stand", {"hip": Vector2(12, -118), "lean": 16.0, "hf": Vector2(122, -192), "hb": Vector2(40, -160), "wa": -6.0, "wt": 0.0, "bf": 1.0, "mouth": 1}],
	"flurry_b": ["stand", {"hip": Vector2(12, -118), "lean": 16.0, "hf": Vector2(60, -170), "hb": Vector2(116, -150), "wa": -30.0, "wt": -4.0, "bf": 1.0, "mouth": 1}],
	"legs_a": ["stand", {"hip": Vector2(-10, -122), "lean": -20.0, "ff": Vector2(124, -150), "hf": Vector2(16, -160), "hb": Vector2(-40, -150), "mouth": 1}],
	"legs_b": ["stand", {"hip": Vector2(-10, -122), "lean": -16.0, "ff": Vector2(120, -84), "hf": Vector2(16, -160), "hb": Vector2(-40, -150), "mouth": 1}],
	"spin_h": ["stand", {"hip": Vector2(0, -116), "lean": 4.0, "ff": Vector2(30, G), "fb": Vector2(-30, G), "hf": Vector2(96, -172), "hb": Vector2(-92, -168), "wa": 0.0, "wt": 0.0, "mouth": 1}],
	"slam_w": ["stand", {"hip": Vector2(0, -122), "lean": -10.0, "hf": Vector2(8, -272), "hb": Vector2(-8, -262), "wa": -100.0, "wt": -90.0, "bf": 1.0}],
	"slam_h": ["stand", {"hip": Vector2(12, -88), "lean": 46.0, "ff": Vector2(56, G), "fb": Vector2(-50, G), "hf": Vector2(96, -44), "hb": Vector2(70, -52), "wa": 62.0, "wt": 70.0, "bf": 1.0, "mouth": 1}],
	"grab_h": ["stand", {"hip": Vector2(10, -118), "lean": 14.0, "hf": Vector2(102, -178), "hb": Vector2(92, -150), "bf": 1.0, "mouth": 1}],
	"throw_lift": ["stand", {"lean": -14.0, "hf": Vector2(20, -252), "hb": Vector2(-12, -246), "bf": 1.0, "mouth": 1}],
	"throw_toss": ["stand", {"hip": Vector2(14, -114), "lean": 28.0, "hf": Vector2(112, -150), "hb": Vector2(90, -130), "bf": 1.0, "mouth": 1}],
	"dive_h": ["jump_up", {"hip": Vector2(0, -118), "lean": -22.0, "ff": Vector2(86, -8), "fb": Vector2(-16, -84), "hf": Vector2(10, -180), "hb": Vector2(-40, -170), "mouth": 1}],
	"bow_draw": ["stand", {"hip": Vector2(-4, -121), "lean": -6.0, "hf": Vector2(76, -180), "hb": Vector2(-12, -180), "draw": 1.0, "bf": 1.0}],
	"bow_loose": ["stand", {"lean": 2.0, "hf": Vector2(78, -180), "hb": Vector2(34, -178), "bf": 1.0, "mouth": 1}],
	"airbow_draw": ["jump_up", {"lean": 10.0, "hf": Vector2(60, -150), "hb": Vector2(-10, -176), "wb": -55.0, "draw": 1.0, "bf": 1.0}],
	"airbow_loose": ["jump_up", {"lean": 12.0, "hf": Vector2(62, -150), "hb": Vector2(24, -168), "wb": -55.0, "bf": 1.0, "mouth": 1}],
	"gaze_h": ["stand", {"hip": Vector2(6, -118), "lean": 20.0, "head": 8.0, "hf": Vector2(40, -150), "hb": Vector2(-34, -146), "mouth": 1}],
	"vanish": ["crouch", {"lean": 30.0, "hf": Vector2(20, -120), "hb": Vector2(0, -110)}],
	"quake_h": ["stand", {"hip": Vector2(8, -104), "lean": 30.0, "hf": Vector2(56, -120), "hb": Vector2(40, -150), "wt": 80.0, "wa": 70.0, "bf": 1.0, "mouth": 1}],
}

# Attack animations: wind-up pose, strike pose, and an optional alternate
# strike pose that multi-hit moves flicker between.
const ANIMS := {
	"jab": {"wind": "jab_w", "hit": "jab_h"},
	"kick": {"wind": "kick_w", "hit": "kick_h"},
	"swing": {"wind": "swing_w", "hit": "swing_h"},
	"thrust": {"wind": "thrust_w", "hit": "thrust_h"},
	"hook": {"wind": "hook_w", "hit": "hook_h"},
	"cjab": {"wind": "crouch", "hit": "cjab_h"},
	"ckick": {"wind": "ckick_w", "hit": "ckick_h"},
	"sweep": {"wind": "ckick_w", "hit": "sweep_h"},
	"airkick": {"wind": "jump_up", "hit": "airkick_h"},
	"airstrike": {"wind": "airstrike_w", "hit": "airstrike_h"},
	"cast": {"wind": "cast_w", "hit": "cast_h"},
	"summon": {"wind": "jab_w", "hit": "summon_h"},
	"upper": {"wind": "upper_w", "hit": "upper_h"},
	"lunge": {"wind": "lunge_w", "hit": "lunge_h"},
	"tackle": {"wind": "lunge_w", "hit": "tackle_h"},
	"flurry": {"wind": "jab_w", "hit": "flurry_a", "alt": "flurry_b"},
	"legs": {"wind": "kick_w", "hit": "legs_a", "alt": "legs_b"},
	"spin": {"wind": "thrust_w", "hit": "spin_h"},
	"slam": {"wind": "slam_w", "hit": "slam_h"},
	"grab": {"wind": "jab_w", "hit": "grab_h"},
	"dive": {"wind": "jump_up", "hit": "dive_h"},
	"bow": {"wind": "bow_draw", "hit": "bow_loose"},
	"airbow": {"wind": "airbow_draw", "hit": "airbow_loose"},
	"gaze": {"wind": "jab_w", "hit": "gaze_h"},
	"vanish": {"wind": "vanish", "hit": "vanish"},
	"quake": {"wind": "slam_w", "hit": "quake_h"},
}

static var _cache := {}
static var _fitted := {}


static func _raw(name: String) -> Dictionary:
	if _cache.has(name):
		return _cache[name]
	var def: Array = DEFS[name]
	var out: Dictionary = STAND.duplicate() if def[0] == "" else _raw(def[0]).duplicate()
	out.merge(def[1], true)
	_cache[name] = out
	return out


static func pose(name: String) -> Dictionary:
	if not _fitted.has(name):
		_fitted[name] = fit(_raw(name))
	return _fitted[name]


static func fit(p: Dictionary) -> Dictionary:
	if p["rot"] != 0.0:
		return p
	var k := (Rig.THIGH + Rig.SHIN - 1.0) / AUTHORED_HIP
	var out := p.duplicate()
	var hip: Vector2 = p["hip"]
	var rise := hip.y * k - hip.y
	out["hip"] = Vector2(hip.x, hip.y * k)
	out["hf"] = p["hf"] + Vector2(0, rise)
	out["hb"] = p["hb"] + Vector2(0, rise)
	for key in ["ff", "fb"]:
		var f: Vector2 = p[key]
		if f.y < G - 1.0:
			out[key] = Vector2(f.x * k, f.y * k)
	return out


static func blend(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	if t <= 0.0:
		return a
	if t >= 1.0:
		return b
	var out := {}
	for key in b:
		var vb = b[key]
		var va = a.get(key, vb)
		if vb is Vector2:
			out[key] = (va as Vector2).lerp(vb, t)
		elif vb is float:
			out[key] = lerpf(va, vb, t)
		else:
			out[key] = vb if t > 0.4 else va
	return out


static func idle(time: float) -> Dictionary:
	var p: Dictionary = pose("stand").duplicate()
	var s := sin(time * 5.5)
	p["hip"] = p["hip"] + Vector2(0, s * 2.4)
	p["hf"] = p["hf"] + Vector2(0, sin(time * 5.5 + 0.9) * 3.5)
	p["hb"] = p["hb"] + Vector2(0, sin(time * 5.5 + 1.6) * 3.0)
	return p


# `phase` advances with distance walked, so the feet step in the direction of travel.
static func walk(phase: float) -> Dictionary:
	var p: Dictionary = pose("stand").duplicate()
	var s := sin(phase)
	var c := cos(phase)
	p["ff"] = Vector2(38.0 + s * 26.0, G - maxf(0.0, c) * 16.0)
	p["fb"] = Vector2(-36.0 - s * 26.0, G - maxf(0.0, -c) * 16.0)
	p["hip"] = p["hip"] + Vector2(0, absf(c) * 3.5)
	p["hf"] = p["hf"] + Vector2(0, c * 3.0)
	return p


static func jump(vy: float) -> Dictionary:
	return blend(pose("jump_up"), pose("jump_fall"), clampf(inverse_lerp(-6.0, 9.0, vy), 0.0, 1.0))


# Pose for frame `t` of an attack: ease into the wind-up, snap to the strike,
# hold it through the active frames, then relax back to `base`.
static func attack(anim: String, t: int, startup: int, active: int, recovery: int, base: Dictionary) -> Dictionary:
	var a: Dictionary = ANIMS.get(anim, ANIMS["jab"])
	var wind := pose(a["wind"])
	var hit := pose(a["hit"])
	if t <= startup:
		var u := float(t) / maxf(1.0, startup)
		if u < 0.6:
			return blend(base, wind, 1.0 - pow(1.0 - u / 0.6, 2.0))
		return blend(wind, hit, pow((u - 0.6) / 0.4, 2.0))
	if t <= startup + active:
		if a.has("alt") and ((t - startup) / 3) % 2 == 1:
			return pose(a["alt"])
		return hit
	var u2 := float(t - startup - active) / maxf(1.0, recovery)
	if u2 < 0.25:
		return hit
	return blend(hit, base, smoothstep(0.0, 1.0, (u2 - 0.25) / 0.75))
