class_name Rig
extends RefCounted

# Draws a posed, ink-outlined cartoon fighter with immediate-mode canvas calls.
# Everything is authored facing right with the feet at the origin (up is -y);
# the caller's base transform handles position, mirroring and scale.
#
# A "look" (see roster.gd) says what to draw: build, outfit, hair, headgear,
# weapon. A "pose" (see poses.gd) says where the hips, feet and hands are;
# knees and elbows are solved here with two-bone IK.

const INK := Color("17121c")
const OUT := 3.0
const THIGH := 70.0
const SHIN := 72.0
const TORSO := 86.0
const UPPER := 46.0
const FORE := 44.0
const HEAD_R := 23.0
const THRUST_WEAPONS := ["spear", "trident", "bident"]

static var _ci: CanvasItem
static var _base: Transform2D
static var _mix := 0.0
static var _mixc := Color.WHITE
static var _alpha := 1.0


static func draw(ci: CanvasItem, base: Transform2D, look: Dictionary, pose: Dictionary, opts: Dictionary = {}) -> void:
	_ci = ci
	_base = base
	_mix = opts.get("flash", 0.0)
	_mixc = opts.get("flash_col", Color.WHITE)
	_alpha = opts.get("alpha", 1.0)
	var t: float = opts.get("time", 0.0)
	var vel: Vector2 = opts.get("vel", Vector2.ZERO)
	var sway := clampf(-vel.x * 2.2, -34.0, 34.0) + sin(t * 3.1) * 2.5
	var lift := clampf(vel.y * 1.6, -26.0, 26.0)
	var j := solve(pose, look)
	var two_handed: bool = pose.get("bf", 0.0) > 0.5 or look.has("shield")

	ci.draw_set_transform_matrix(base)
	if look.has("cape"):
		_cape(j, look, sway, lift)
	if look.get("quiver", false):
		_quiver(j, look)
	_head_xf(j, look)
	_head_back(look, sway, lift)
	ci.draw_set_transform_matrix(base)
	if not two_handed:
		_arm(j, look, "b")
	_leg(j, look, "b")
	_leg(j, look, "f")
	_skirt(j, look)
	_torso(j, look)
	if two_handed:
		_arm(j, look, "b")
		if look.has("shield"):
			_shield(j, look)
	_seg(j["neck"] - j["up"] * 6.0, j["head"], 8.5 * j["nb"] + OUT * 0.5, INK)
	_seg(j["neck"] - j["up"] * 6.0, j["head"], 8.5 * j["nb"] - OUT * 0.5, look["skin"])
	_head_xf(j, look)
	_head(look, pose, sway, lift, t)
	ci.draw_set_transform_matrix(base)
	_weapon(j, look, pose, t)
	_arm(j, look, "f")
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


static func draw_shadow(ci: CanvasItem, pos: Vector2, height: float, size: float) -> void:
	var s := clampf(1.0 - height / 520.0, 0.45, 1.0) * size
	ci.draw_set_transform(pos, 0.0, Vector2(s, s * 0.22))
	ci.draw_circle(Vector2.ZERO, 62.0, Color(0, 0, 0, 0.32), true, -1.0, true)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


# ---------------------------------------------------------------------------
# Skeleton
# ---------------------------------------------------------------------------

static func solve(pose: Dictionary, look: Dictionary) -> Dictionary:
	var bulk: float = look.get("bulk", 1.0)
	var fem: bool = look.get("female", false)
	var hip: Vector2 = pose["hip"]
	var lean := deg_to_rad(pose.get("lean", 0.0))
	var up := Vector2(sin(lean), -cos(lean))
	var fwd := Vector2(cos(lean), sin(lean))
	var neck := hip + up * TORSO
	var sw := (15.0 if fem else 19.0) * bulk
	var head_ang := lean * 0.55 + deg_to_rad(pose.get("head", 0.0))
	var j := {
		"hip": hip, "neck": neck, "up": up, "fwd": fwd,
		"sh_f": neck + fwd * sw - up * 12.0,
		"sh_b": neck - fwd * sw - up * 12.0,
		"hp_f": hip + Vector2(9, 0),
		"hp_b": hip + Vector2(-9, 0),
		"head": neck + Vector2(sin(head_ang), -cos(head_ang)) * (HEAD_R + 3.0) + fwd * 3.0,
		"head_ang": head_ang,
		"bulk": bulk, "fem": fem,
	}
	var lb := lerpf(1.0, bulk, 0.8) * (0.9 if fem else 1.0)
	var ab := pow(bulk, 1.25) * (0.8 if fem else 1.0)
	j["r_thigh"] = 14.5 * lb
	j["r_shin"] = 11.0 * lb
	j["r_upper"] = 11.0 * ab
	j["r_fore"] = 9.5 * ab
	j["nb"] = lerpf(1.0, bulk, 0.7) * (0.82 if fem else 1.0)

	# Limb thickness: [root, muscle, joint, muscle, wrist/ankle].
	j["arm_r"] = [11.0 * ab, 12.0 * ab, 8.6 * ab, 9.6 * ab, 6.6 * ab]
	j["leg_r"] = [14.5 * lb, 15.6 * lb, 10.0 * lb, 11.4 * lb, 7.0 * lb]

	var leg_f := _ik(j["hp_f"], pose["ff"], THIGH, SHIN, -1.0)
	var leg_b := _ik(j["hp_b"], pose["fb"], THIGH, SHIN, -1.0)
	var arm_f := _ik(j["sh_f"], pose["hf"], UPPER, FORE, 1.0)
	var arm_b := _ik(j["sh_b"], pose["hb"], UPPER, FORE, 1.0)
	j["kn_f"] = leg_f[0]
	j["ft_f"] = leg_f[1]
	j["kn_b"] = leg_b[0]
	j["ft_b"] = leg_b[1]
	j["el_f"] = arm_f[0]
	j["hd_f"] = arm_f[1]
	j["el_b"] = arm_b[0]
	j["hd_b"] = arm_b[1]

	var rot := deg_to_rad(pose.get("rot", 0.0))
	j["rot"] = rot
	if rot != 0.0:
		for key in ["neck", "sh_f", "sh_b", "hp_f", "hp_b", "head", "kn_f", "ft_f", "kn_b", "ft_b", "el_f", "hd_f", "el_b", "hd_b"]:
			j[key] = hip + (j[key] - hip).rotated(rot)
		j["up"] = up.rotated(rot)
		j["fwd"] = fwd.rotated(rot)
		j["head_ang"] = head_ang + rot
	return j


# Two-bone IK. Returns [joint, end]. `bend` is +1 for an arm and -1 for a leg:
# seen from the side, an elbow only ever folds the forearm towards the front
# of the body and a knee only folds the shin towards the back, wherever the
# hand or foot happens to be. (Choosing the side from a fixed "preferred
# direction" instead turns elbows inside out as soon as an arm is raised.)
static func _ik(a: Vector2, target: Vector2, l1: float, l2: float, bend: float) -> Array:
	var d := target - a
	var raw := d.length()
	var dir := d / raw if raw > 0.001 else Vector2.DOWN
	var dist := clampf(raw, absf(l1 - l2) + 0.5, l1 + l2 - 0.5)
	var x := (l1 * l1 - l2 * l2 + dist * dist) / (2.0 * dist)
	var h := sqrt(maxf(0.0, l1 * l1 - x * x))
	var perp := Vector2(-dir.y, dir.x)
	return [a + dir * x + perp * h * bend, a + dir * dist]


static func _tp(j: Dictionary, u: float, v: float) -> Vector2:
	return j["hip"] + j["fwd"] * u + j["up"] * v


# ---------------------------------------------------------------------------
# Primitives
# ---------------------------------------------------------------------------

static func _c(col: Color) -> Color:
	var c := col.lerp(_mixc, _mix) if _mix > 0.0 else col
	c.a *= _alpha
	return c


static func _seg(a: Vector2, b: Vector2, r: float, col: Color) -> void:
	var c := _c(col)
	if a.distance_squared_to(b) > 0.01:
		_ci.draw_line(a, b, c, r * 2.0, true)
	_ci.draw_circle(a, r, c, true, -1.0, true)
	_ci.draw_circle(b, r, c, true, -1.0, true)


static func _dot(p: Vector2, r: float, col: Color) -> void:
	_ci.draw_circle(p, r, _c(col), true, -1.0, true)


static func _ball(p: Vector2, r: float, col: Color) -> void:
	_dot(p, r + OUT * 0.5, INK)
	_dot(p, r - OUT * 0.5, col)


static func _line(pts: PackedVector2Array, col: Color, w: float) -> void:
	_ci.draw_polyline(pts, _c(col), w, true)


static func _stroke(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	_ci.draw_line(a, b, _c(col), w, true)


static func _poly(pts: PackedVector2Array, col: Color, outline := OUT) -> void:
	_ci.draw_colored_polygon(pts, _c(col))
	if outline > 0.0:
		var loop := PackedVector2Array(pts)
		loop.append(pts[0])
		_ci.draw_polyline(loop, _c(INK), outline, true)


static func _pts(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size(), 2):
		out.append(Vector2(flat[i], flat[i + 1]))
	return out


static func _arc(cx: float, cy: float, r: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var a := deg_to_rad(lerpf(a0, a1, float(i) / n))
		out.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	return out


static func _hull(pts: PackedVector2Array) -> PackedVector2Array:
	var hull := Geometry2D.convex_hull(pts)
	if hull.size() > 1 and hull[0].is_equal_approx(hull[hull.size() - 1]):
		hull.remove_at(hull.size() - 1)
	return hull


static func _shade_of(col: Color) -> Color:
	return col.darkened(0.24)


# A chain of round-capped segments drawn ink-first so the joints merge.
static func _limb(pts: Array, radii: Array, col: Color) -> void:
	var n := pts.size() - 1
	for i in n:
		_seg(pts[i], pts[i + 1], radii[i] + OUT * 0.5, INK)
	for i in n:
		_seg(pts[i], pts[i + 1], radii[i] - OUT * 0.5, col)
	var shade := _shade_of(col)
	for i in n:
		var d: Vector2 = pts[i + 1] - pts[i]
		if d.length() < 8.0:
			continue
		d = d.normalized()
		var nrm := Vector2(-d.y, d.x)
		if nrm.dot(Vector2(-0.5, 0.85)) < 0.0:
			nrm = -nrm
		var r: float = radii[i] - OUT * 0.5
		_stroke(pts[i] + d * 3.0 + nrm * r * 0.5, pts[i + 1] - d * 3.0 + nrm * r * 0.5, shade, r * 0.8)


# Thickness `f` of the way along the second bone of an arm or leg.
static func _lower_r(r: Array, f: float) -> float:
	return lerpf(r[2], r[3], f / 0.3) if f <= 0.3 else lerpf(r[3], r[4], (f - 0.3) / 0.7)


# An ink-outlined tube that tapers from radius `ra` to `rb` (bracers, greaves).
static func _taper(a: Vector2, b: Vector2, ra: float, rb: float, col: Color) -> void:
	for layer in 2:
		var grow := OUT * 0.5 if layer == 0 else -OUT * 0.5
		var c := _c(INK if layer == 0 else col)
		for i in 4:
			var f := i / 3.0
			var r := lerpf(ra, rb, f) + grow
			_ci.draw_circle(a.lerp(b, f), r, c, true, -1.0, true)
			if i > 0:
				_ci.draw_line(a.lerp(b, f - 1.0 / 3.0), a.lerp(b, f), c, r * 2.0 + (ra - rb) / 3.0, true)


# An arm or leg: one smooth tube from `a` through the joint `j` to `b`. It
# swells over the muscles, narrows at the joint and the wrist or ankle, and the
# joint itself is a short curve instead of a hinge between two sausages.
# `r` is [at a, muscle, at the joint, muscle, at b].
static func _organic(a: Vector2, j: Vector2, b: Vector2, r: Array, col: Color) -> void:
	var d1 := j - a
	var d2 := b - j
	var l1 := maxf(d1.length(), 0.01)
	var l2 := maxf(d2.length(), 0.01)
	var corner := minf(l1, l2) * 0.24
	var ja := j - d1 / l1 * corner
	var jb := j + d2 / l2 * corner
	var pts := PackedVector2Array()
	var rr := PackedFloat32Array()
	for f in [0.0, 0.2, 0.42, 0.7]:
		pts.append(a.lerp(ja, f))
		rr.append(lerpf(r[0], r[1], f / 0.42) if f < 0.42 else lerpf(r[1], r[2], (f - 0.42) / 0.58))
	pts.append(ja)
	rr.append(r[2])
	pts.append(ja * 0.25 + j * 0.5 + jb * 0.25)
	rr.append(r[2])
	pts.append(jb)
	rr.append(r[2])
	for f in [0.3, 0.55, 0.8, 1.0]:
		pts.append(jb.lerp(b, f))
		rr.append(_lower_r(r, f))
	for layer in 2:
		var grow := OUT * 0.5 if layer == 0 else -OUT * 0.5
		var c := _c(INK if layer == 0 else col)
		for i in pts.size():
			_ci.draw_circle(pts[i], rr[i] + grow, c, true, -1.0, true)
			if i > 0 and pts[i].distance_squared_to(pts[i - 1]) > 0.01:
				_ci.draw_line(pts[i - 1], pts[i], c, rr[i - 1] + rr[i] + grow * 2.0, true)
	# Cel shading down the under-side of each bone.
	var shade := _c(_shade_of(col))
	for bone in [[0, 5, d1 / l1], [6, 11, d2 / l2]]:
		var d: Vector2 = bone[2]
		var nrm := Vector2(-d.y, d.x)
		if nrm.dot(Vector2(-0.5, 0.85)) < 0.0:
			nrm = -nrm
		var strip := PackedVector2Array()
		var w := 0.0
		for i in range(bone[0], bone[1]):
			strip.append(pts[i] + nrm * rr[i] * 0.56)
			w += rr[i]
		if strip[0].distance_to(strip[strip.size() - 1]) > 8.0:
			w = w / strip.size() * 0.58
			_ci.draw_polyline(strip, shade, w, true)
			_ci.draw_circle(strip[0], w * 0.5, shade, true, -1.0, true)
			_ci.draw_circle(strip[strip.size() - 1], w * 0.5, shade, true, -1.0, true)


# ---------------------------------------------------------------------------
# Body parts
# ---------------------------------------------------------------------------

static func _leg(j: Dictionary, look: Dictionary, side: String) -> void:
	var h: Vector2 = j["hp_" + side]
	var k: Vector2 = j["kn_" + side]
	var a: Vector2 = j["ft_" + side]
	var skin: Color = look["skin"]
	if side == "b":
		skin = skin.darkened(0.12)
	var lr: Array = j["leg_r"]
	var rs: float = lr[3]
	_organic(h, k, a, lr, skin)

	var legs: String = look.get("legs", "sandals")
	var gear: Color = look.get("leg_col", look.get("metal", Color("c9973a")))
	if side == "b":
		gear = gear.darkened(0.12)
	var shin_dir := (a - k).normalized()
	# Foot: flat on the ground, otherwise it follows the shin.
	var toe_dir := shin_dir.rotated(deg_to_rad(-80.0))
	var on_ground := 0.0 if j["rot"] != 0.0 else clampf((a.y + 26.0) / 14.0, 0.0, 1.0)
	toe_dir = toe_dir.lerp(Vector2(1, 0), on_ground).normalized()
	var down := Vector2(-toe_dir.y, toe_dir.x)
	var heel := a - toe_dir * 5.0 + down * 3.5
	var toe := a + toe_dir * 21.0 + down * 4.0
	var foot_col := skin
	if legs == "greaves" or legs == "boots":
		foot_col = gear.darkened(0.2)
	_seg(heel, toe, 6.5 + OUT * 0.5, INK)
	_seg(heel, toe, 6.5 - OUT * 0.5, foot_col)

	match legs:
		"greaves":
			var top := k.lerp(a, 0.14)
			_taper(top, a, _lower_r(lr, 0.14) + 2.0, lr[4] + 2.2, gear)
			var nrm := Vector2(-shin_dir.y, shin_dir.x)
			_stroke(top + nrm * 3.0, a + nrm * 3.0, gear.lightened(0.35), 2.5)
			_ball(k, rs * 0.75, gear)
		"boots":
			var top2 := k.lerp(a, 0.45)
			_taper(top2, a, _lower_r(lr, 0.45) + 1.4, lr[4] + 1.6, gear)
		"wings", "sandals":
			var strap: Color = look.get("leg_col", Color("7a4a2a"))
			var nrm2 := Vector2(-shin_dir.y, shin_dir.x)
			for f in [0.55, 0.75, 0.95]:
				var c: Vector2 = k.lerp(a, f)
				var half := _lower_r(lr, f) - 2.2
				_stroke(c - nrm2 * half, c + nrm2 * half, strap, 2.6)
			_stroke(heel, toe, strap, 3.0)
			if legs == "wings":
				var w := a - shin_dir * 6.0
				var back := -toe_dir
				var wing := PackedVector2Array([
					w, w + back * 12.0 - down * 16.0, w + back * 30.0 - down * 22.0,
					w + back * 22.0 - down * 10.0, w + back * 30.0 - down * 6.0, w + back * 12.0 + down * 2.0])
				_poly(wing, Color("f7f7ff"), 2.2)


static func _arm(j: Dictionary, look: Dictionary, side: String) -> void:
	var s: Vector2 = j["sh_" + side]
	var e: Vector2 = j["el_" + side]
	var h: Vector2 = j["hd_" + side]
	var skin: Color = look["skin"]
	if side == "b":
		skin = skin.darkened(0.12)
	var ar: Array = j["arm_r"]
	var ru: float = ar[0]
	var rf: float = ar[3]
	_organic(s, e, h, ar, skin)
	var arms: String = look.get("arms", "bare")
	var gear: Color = look.get("arm_col", look.get("metal", Color("c9973a")))
	if side == "b":
		gear = gear.darkened(0.12)
	if arms == "bracer" or arms == "wrap":
		var a := e.lerp(h, 0.36)
		var b := e.lerp(h, 0.86)
		_taper(a, b, _lower_r(ar, 0.36) + 1.0, _lower_r(ar, 0.86) + 1.2, gear)
		if arms == "wrap":
			var d := (h - e).normalized()
			var nrm := Vector2(-d.y, d.x)
			for f in [0.42, 0.58, 0.74]:
				var c: Vector2 = e.lerp(h, f)
				var half := _lower_r(ar, f)
				_stroke(c - nrm * half, c + nrm * half, gear.darkened(0.25), 1.6)
	if look.get("pauldron", false):
		_ball(s - j["up"] * -3.0, ru + 4.0, look.get("metal", Color("c9973a")) if side == "f" else look.get("metal", Color("c9973a")).darkened(0.12))
	_ball(h, rf + 1.4, skin)


static func _torso_outline(j: Dictionary) -> PackedVector2Array:
	var b: float = j["bulk"]
	var flat: Array
	if j["fem"]:
		flat = [-17, -6, -12.5, 28, -17, 54, -19 * b, 74, -14 * b, 84, -8, 88, 8, 88, 14 * b, 84,
			19 * b, 75, 22 * b, 62, 20 * b, 48, 12.5, 30, 17.5, -6]
	else:
		flat = [-16 * b, -6, -15 * b, 26, -22 * b, 54, -25 * b, 74, -17 * b, 85, -8, 88, 8, 88, 17 * b, 85,
			25 * b, 74, 23 * b, 52, 15 * b, 26, 16 * b, -6]
	var out := PackedVector2Array()
	for i in range(0, flat.size(), 2):
		out.append(_tp(j, flat[i], flat[i + 1]))
	return out


static func _torso(j: Dictionary, look: Dictionary) -> void:
	var b: float = j["bulk"]
	var fem: bool = j["fem"]
	var outfit: String = look.get("outfit", "chiton")
	var skin: Color = look["skin"]
	var cloth: Color = look.get("cloth", Color.WHITE)
	var trim: Color = look.get("trim", Color("e2b93b"))
	var metal: Color = look.get("metal", Color("c9973a"))
	var outline := _torso_outline(j)
	var base_col := skin
	match outfit:
		"armor":
			base_col = metal
		"chiton":
			base_col = cloth
	_poly(outline, base_col)
	# Back-side shadow strip.
	var wb := 12.5 if fem else 15.0 * b
	var cb := 17.0 if fem else 22.0 * b
	var shade := PackedVector2Array([
		_tp(j, -wb - 1.0, -4), _tp(j, -wb, 27), _tp(j, -cb, 54), _tp(j, -cb + 1.0, 72),
		_tp(j, -cb + 9.0, 72), _tp(j, -wb + 7.0, 27), _tp(j, -wb + 7.0, -4)])
	_ci.draw_colored_polygon(shade, _c(_shade_of(base_col)))

	match outfit:
		"bare":
			_line(PackedVector2Array([_tp(j, 1, 60), _tp(j, 9 * b, 55), _tp(j, 20 * b, 59)]), INK, 2.0)
			_line(PackedVector2Array([_tp(j, -3, 60), _tp(j, -12 * b, 56)]), INK, 2.0)
			_stroke(_tp(j, 2, 52), _tp(j, 3, 14), INK, 1.6)
			for v in [42.0, 30.0, 19.0]:
				_stroke(_tp(j, -5, v), _tp(j, 11 * b, v + 1.0), INK, 1.4)
		"armor":
			_line(PackedVector2Array([_tp(j, 1, 61), _tp(j, 10 * b, 55), _tp(j, 21 * b, 60)]), INK, 2.0)
			_line(PackedVector2Array([_tp(j, -3, 61), _tp(j, -13 * b, 56)]), INK, 2.0)
			_stroke(_tp(j, 2, 52), _tp(j, 3, 12), INK, 1.6)
			for v in [40.0, 27.0]:
				_stroke(_tp(j, -6, v), _tp(j, 11 * b, v + 1.0), INK, 1.4)
			_stroke(_tp(j, 12 * b, 68), _tp(j, 19 * b, 44), metal.lightened(0.45), 3.0)
			var rim := PackedVector2Array([_tp(j, -16 * b, -6), _tp(j, -15.6 * b, 5), _tp(j, 15.6 * b, 5), _tp(j, 16 * b, -6)])
			_poly(rim, trim, 2.0)
		"chiton":
			if look.get("one_shoulder", false):
				var bare := PackedVector2Array([
					_tp(j, -8, 88), _tp(j, -14 * b, 84), _tp(j, -18 * b, 74), _tp(j, -17 * b, 58), _tp(j, 6, 82)])
				_poly(bare, skin, 2.0)
			else:
				_poly(PackedVector2Array([_tp(j, -6, 88), _tp(j, 8, 88), _tp(j, 3, 70)]), skin, 2.0)
			_stroke(_tp(j, 10 * b, 70), _tp(j, 6 * b, 36), INK, 1.4)
			_stroke(_tp(j, -4, 62), _tp(j, -2, 36), INK, 1.4)
	if look.has("sash"):
		var sash := PackedVector2Array([
			_tp(j, 6 * b, 87), _tp(j, 22 * b, 78), _tp(j, -9 * b, 20), _tp(j, -15.5 * b, 30)])
		_poly(sash, look["sash"], 2.2)
	if outfit != "armor" or look.has("belt"):
		var bw := 13.0 if fem else 15.3 * b
		var belt := PackedVector2Array([_tp(j, -bw, 20), _tp(j, bw, 20), _tp(j, bw - 0.4, 29), _tp(j, -bw + 0.4, 29)])
		_poly(belt, look.get("belt", trim), 2.2)
		_ball(_tp(j, 5, 24.5), 4.5, look.get("belt", trim).lightened(0.4))


static func _skirt(j: Dictionary, look: Dictionary) -> void:
	var b: float = j["bulk"]
	var length: float = look.get("skirt", 0.55)
	var col: Color = look.get("skirt_col", look.get("cloth", Color.WHITE))
	var trim: Color = look.get("trim", Color("e2b93b"))
	var ww := (13.0 if j["fem"] else 16.0 * b) + 1.5
	var pts := PackedVector2Array([_tp(j, -ww, 12), _tp(j, ww, 12)])
	var hems: Array = []
	var r: float = j["r_thigh"] + 6.0
	for side in ["b", "f"]:
		var h: Vector2 = j["hp_" + side]
		var k: Vector2 = j["kn_" + side]
		var d := (k - h).normalized()
		var n := Vector2(-d.y, d.x)
		var q := h + d * THIGH * length
		var m := h + d * THIGH * length * 0.5
		pts.append_array(PackedVector2Array([q + n * r, q - n * r, m + n * r, m - n * r]))
		hems.append(q + n * r)
		hems.append(q - n * r)
	var hull := _hull(pts)
	_ci.draw_colored_polygon(hull, _c(col))
	# Hem trim just inside the lower edge, then pleats, then the ink outline.
	hems.sort_custom(func(p: Vector2, q2: Vector2) -> bool: return p.x < q2.x)
	var centre := _tp(j, 0, 12)
	var hem_line := PackedVector2Array()
	for p: Vector2 in hems:
		hem_line.append(p + (centre - p).normalized() * 4.5)
	_line(hem_line, trim, 4.5)
	var strips: bool = look.get("outfit", "") == "armor"
	for f in ([0.0, 0.25, 0.5, 0.75, 1.0] if strips else [0.2, 0.5, 0.8]):
		var bottom: Vector2 = hems[0].lerp(hems[3], f)
		var top := _tp(j, lerpf(-ww, ww, f) * 0.8, 12)
		_stroke(top, bottom.lerp(top, 0.12), INK, 1.4)
	var loop := PackedVector2Array(hull)
	loop.append(hull[0])
	_ci.draw_polyline(loop, _c(INK), OUT, true)


static func _cape(j: Dictionary, look: Dictionary, sway: float, lift: float) -> void:
	var col: Color = look["cape"]
	var a1: Vector2 = j["neck"] - j["fwd"] * 20.0 * j["bulk"] - j["up"] * 6.0
	var a2: Vector2 = j["neck"] + j["fwd"] * 12.0 - j["up"] * 2.0
	var length: float = look.get("cape_len", 128.0)
	var b1 := a1 + Vector2(-30.0 + sway, length - lift - 10.0)
	var b2 := a1 + Vector2(18.0 + sway * 0.55, length - lift * 0.6)
	var mid := a1 + Vector2(-22.0 + sway * 0.5, length * 0.5)
	var hull := _hull(PackedVector2Array([a2, a1, mid, b1, b2]))
	_poly(hull, col)
	_stroke(a1 + Vector2(2, 14), b1.lerp(b2, 0.45) + Vector2(0, -8), _shade_of(col), 5.0)
	if look.get("fleece", false):
		for f in [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]:
			_ball(a1.lerp(mid, f).lerp(mid.lerp(b1, f), f), 9.0, col.lightened(0.25))
		for f in [0.15, 0.5, 0.85]:
			_ball(b1.lerp(b2, f), 9.0, col.lightened(0.25))
	else:
		_stroke(b1 + Vector2(1, -4), b2 + Vector2(-1, -4), look.get("cape_trim", _shade_of(col)), 4.0)


static func _quiver(j: Dictionary, look: Dictionary) -> void:
	var top: Vector2 = j["neck"] - j["fwd"] * 26.0 + j["up"] * 14.0
	var bot: Vector2 = j["neck"] - j["fwd"] * 12.0 - j["up"] * 52.0
	_seg(top, bot, 8.0 + OUT * 0.5, INK)
	_seg(top, bot, 8.0 - OUT * 0.5, Color("7a4a2a"))
	var d := (top - bot).normalized()
	for off in [-4.0, 0.0, 4.0]:
		var p := top + Vector2(off, 0)
		_stroke(p, p + d * 14.0, Color("e8dcc0"), 2.0)
		_dot(p + d * 15.0, 3.0, look.get("trim", Color.WHITE))


static func _shield(j: Dictionary, look: Dictionary) -> void:
	var c: Vector2 = j["hd_b"].lerp(j["el_b"], 0.25)
	var metal: Color = look.get("metal", Color("c9973a"))
	var face: Color = look.get("shield_col", Color("8a1f1f"))
	_ci.draw_set_transform_matrix(_base * Transform2D(j["rot"], Vector2(0.86, 1.0), 0.0, c))
	_dot(Vector2.ZERO, 34.0 + OUT * 0.5, INK)
	_dot(Vector2.ZERO, 34.0 - OUT * 0.5, metal)
	_dot(Vector2.ZERO, 27.0, INK)
	_dot(Vector2.ZERO, 25.5, face)
	_ci.draw_arc(Vector2.ZERO, 30.5, deg_to_rad(200), deg_to_rad(300), 10, _c(metal.lightened(0.5)), 2.5, true)
	match look["shield"]:
		"sun":
			for k in 8:
				var d := Vector2.RIGHT.rotated(k * TAU / 8.0)
				_stroke(d * 9.0, d * 20.0, metal.lightened(0.3), 3.0)
			_ball(Vector2.ZERO, 8.0, metal.lightened(0.3))
		"gorgon":
			for k in 7:
				var d2 := Vector2.RIGHT.rotated(deg_to_rad(180.0 + k * 30.0))
				_stroke(d2 * 9.0, d2 * 19.0, Color("3f7a4a"), 3.5)
			_ball(Vector2(0, 2), 11.0, Color("9fc7a0"))
			_dot(Vector2(-4, 0), 2.2, Color("ffe14a"))
			_dot(Vector2(4, 0), 2.2, Color("ffe14a"))
			_stroke(Vector2(-4, 7), Vector2(4, 7), INK, 1.8)
		"lambda":
			_line(PackedVector2Array([Vector2(-12, 14), Vector2(0, -15), Vector2(12, 14)]), metal.lightened(0.3), 5.0)
	_ci.draw_set_transform_matrix(_base)


# ---------------------------------------------------------------------------
# Head
# ---------------------------------------------------------------------------

static func _head_xf(j: Dictionary, look: Dictionary) -> void:
	var hs: float = look.get("head_scale", 1.0)
	_ci.draw_set_transform_matrix(_base * Transform2D(j["head_ang"], Vector2(hs, hs), 0.0, j["head"]))


static func _hair_cap(col: Color) -> void:
	var pts := _arc(0, 0, HEAD_R + 2.5, 160, 338, 12)
	pts.append_array(_pts([19, -13, 12, -11, 8, -14, 3, -9, -1, -3, -5, -6, -9, 3, -13, 8, -18, 11]))
	_poly(pts, col)


# Hair and gear that sits behind the skull.
static func _head_back(look: Dictionary, sway: float, lift: float) -> void:
	var hair: Color = look.get("hair", Color("3a2a1a"))
	var s := sway * 0.6
	match look.get("hair_style", "short"):
		"long":
			_poly(_pts([-4, -24, -20, -16, -28, 2, -31 + s, 30, -27 + s, 56 - lift * 0.4, -11 + s, 60 - lift * 0.4, -7, 34, -2, 10, 6, -10]), hair.darkened(0.12))
		"ponytail":
			var p0 := Vector2(-20, -10)
			var p1 := Vector2(-37 + s, -5 - lift * 0.3)
			var p2 := Vector2(-47 + s * 1.5, 16 - lift * 0.6)
			var p3 := Vector2(-45 + s * 2.0, 40 - lift)
			_limb([p0, p1, p2, p3], [8.0, 7.0, 5.0], hair)
		"braid":
			var q := Vector2(-20, -4)
			for k in 6:
				_ball(q + Vector2(-5.0 - k * 1.5 + s * k * 0.3, k * 11.0 - lift * k * 0.12), 7.5 - k * 0.6, hair)
		"bun":
			_ball(Vector2(-23, -11), 10.0, hair)
	if look.get("headgear", "") == "lion":
		var mane := PackedVector2Array()
		var k2 := 0
		for a in range(95, 336, 20):
			var r := HEAD_R + (17.0 if k2 % 2 == 0 else 9.0)
			mane.append(Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * r)
			k2 += 1
		mane.append(Vector2(6, -8))
		mane.append(Vector2(-2, 16))
		_poly(mane, look.get("gear_col", Color("c9a15a")).darkened(0.15))
	if look.get("headgear", "") in ["helm", "corinthian"]:
		var crest: Color = look.get("crest", Color("b3261e"))
		var pts := _arc(0, 0, HEAD_R + 4.0, 205, 318, 8)
		pts.append_array(_arc(0, 0, HEAD_R + 21.0, 318, 200, 9))
		pts.append_array(_pts([-48 + s, 0, -50 + s * 1.5, 22 - lift * 0.5, -41 + s * 1.5, 26 - lift * 0.5, -36 + s * 0.5, 8, -30, -4]))
		_poly(pts, crest)
		for a in range(214, 318, 13):
			var d := Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a)))
			_stroke(d * (HEAD_R + 6.0), d * (HEAD_R + 19.0), crest.darkened(0.35), 1.6)


static func _head(look: Dictionary, pose: Dictionary, sway: float, lift: float, t: float) -> void:
	var skin: Color = look["skin"]
	var hair: Color = look.get("hair", Color("3a2a1a"))
	var gear: Color = look.get("gear_col", look.get("metal", Color("c9973a")))
	var fem: bool = look.get("female", false)
	var headgear: String = look.get("headgear", "")
	var mouth: int = int(pose.get("mouth", 0))  # 0 neutral, 1 yell, 2 hurt, 3 grin, 4 out cold
	var s := sway * 0.6

	# Skull + face profile.
	var skull := _arc(0, 0, HEAD_R, 150, 345, 14)
	skull.append_array(_pts([23, -4, 22.5, 1, 29, 8, 23.5, 11, 24, 15, 22, 17, 23, 20.5, 19.5, 27, 7, 28.5, -8, 21]))
	_poly(skull, skin)
	_ci.draw_colored_polygon(_pts([-8, 21, 7, 28.5, 19.5, 27, 16, 23, 2, 22, -12, 14]), _c(_shade_of(skin)))
	if headgear != "corinthian":
		_ball(Vector2(-5, 1), 5.0, skin)

	# Beard under the mouth and eye.
	var beard_col: Color = look.get("beard_col", hair)
	match look.get("beard", ""):
		"short":
			_poly(_pts([-7, 9, 4, 13, 14, 12, 21.5, 17, 23.5, 21, 20, 30, 8, 34, -4, 28]), beard_col)
		"long":
			_poly(_pts([-7, 9, 4, 13, 14, 12, 22, 17, 24.5, 24, 21, 44, 11, 62, 0, 50, -6, 30]), beard_col)
		"curly":
			var balls := [[-4, 17, 8], [6, 23, 9], [17, 24, 8], [12, 35, 9], [1, 33, 8], [8, 45, 8]]
			for bl in balls:
				_dot(Vector2(bl[0], bl[1]), bl[2] + OUT * 0.5, INK)
			for bl in balls:
				_dot(Vector2(bl[0], bl[1]), bl[2] - OUT * 0.5, beard_col)
			_dot(Vector2(10, 30), 6.0, beard_col.darkened(0.12))

	if headgear != "corinthian":
		var glow: bool = look.has("eye_col")
		if mouth == 2 or mouth == 4:
			_line(_pts([5, -3, 11, -1.5, 18, -4]), INK, 2.6)
			_stroke(Vector2(3, -8), Vector2(19, -11.5), INK, 3.2)
		else:
			if glow:
				_dot(Vector2(11.5, -3.6), 9.0, Color(look["eye_col"], 0.35))
			_poly(_pts([5, -3, 11, -7.8, 18, -4.2, 11, -0.4]), look["eye_col"] if glow else Color.WHITE, 1.8)
			if not glow:
				_dot(Vector2(13.0, -3.9), 2.5, INK)
			if fem:
				_stroke(Vector2(4, -3.5), Vector2(11, -8.6), INK, 2.4)
				_stroke(Vector2(3, -11.5), Vector2(19, -9.5), INK, 2.4)
			else:
				_stroke(Vector2(2.5, -11.5), Vector2(20, -7.2), INK, 3.6)
		match mouth:
			0:
				_stroke(Vector2(15.5, 16.8), Vector2(22, 17), INK, 2.0)
			1:
				_poly(_pts([12, 14, 23, 14.2, 22.2, 23.5, 14, 21.5]), Color("5a1420"), 1.8)
				_ci.draw_colored_polygon(_pts([14, 14.6, 22.4, 14.8, 22.2, 17, 14.6, 16.6]), _c(Color.WHITE))
			2:
				_poly(_pts([14, 15, 22.6, 15, 22, 21.5, 15.5, 20.5]), Color("5a1420"), 1.8)
			3:
				_poly(_pts([12.5, 13.5, 23, 14.5, 21.5, 20.5, 14, 18.5]), Color.WHITE, 1.8)
			4:
				_stroke(Vector2(15, 18), Vector2(22, 16.5), INK, 2.0)
		if fem and mouth == 0:
			_dot(Vector2(21.5, 17.4), 2.2, Color("b8434f"))

	# Hair on top.
	var style: String = look.get("hair_style", "short")
	if headgear not in ["helm", "corinthian", "lion", "pilos", "wingcap"]:
		match style:
			"short", "long", "ponytail", "braid", "bun":
				_hair_cap(hair)
			"curly":
				var curls := [[-16, -16, 11], [-4, -23, 11], [9, -21, 10], [18, -14, 7], [-23, -3, 10], [-21, 9, 8]]
				for cl in curls:
					_dot(Vector2(cl[0], cl[1]), cl[2] + OUT * 0.5, INK)
				for cl in curls:
					_dot(Vector2(cl[0], cl[1]), cl[2] - OUT * 0.5, hair)
	if style == "ponytail":
		_ball(Vector2(-21, -10), 4.5, look.get("trim", Color.WHITE))

	match headgear:
		"helm":
			var bowl := _arc(0, 0, HEAD_R + 4.0, 152, 340, 12)
			bowl.append_array(_pts([28.5, -7, 3, -8.5, 1, 5, 10, 11, 7, 22, -3, 20, -7, 9, -13, 15, -22, 16]))
			_poly(bowl, gear)
			_ci.draw_arc(Vector2.ZERO, HEAD_R + 0.5, deg_to_rad(215), deg_to_rad(300), 10, _c(gear.lightened(0.5)), 2.5, true)
			_stroke(Vector2(27, -7.5), Vector2(4, -8.8), look.get("trim", gear.darkened(0.3)), 2.2)
		"corinthian":
			var plate := _arc(0, 0, HEAD_R + 4.0, 152, 340, 12)
			plate.append_array(_pts([29, -5, 29, 12, 24.5, 14, 24.5, 24, 18, 31, 4, 30, -6, 22, -12, 16, -22, 16]))
			_poly(plate, gear)
			_ci.draw_arc(Vector2.ZERO, HEAD_R + 0.5, deg_to_rad(215), deg_to_rad(300), 10, _c(gear.lightened(0.45)), 2.5, true)
			_poly(_pts([6, -7.5, 23, -6.5, 22, -0.5, 8, -1]), Color("140c12"), 2.0)
			_line(_pts([20.5, -1, 22.5, 12, 21, 26]), INK, 2.4)
			var ec: Color = look.get("eye_col", Color.WHITE)
			_dot(Vector2(14, -4), 5.5, Color(ec, 0.4))
			_dot(Vector2(14, -4), 2.6, ec)
		"laurel":
			for k in 7:
				var a := deg_to_rad(196.0 + k * 21.0)
				var c := Vector2(cos(a), sin(a)) * (HEAD_R + 0.5)
				var tang := Vector2(-sin(a), cos(a))
				var lf := (tang + Vector2(cos(a), sin(a)) * 0.45).normalized()
				_seg(c - lf * 4.0, c + lf * 5.0, 3.4 + 1.2, INK)
				_seg(c - lf * 4.0, c + lf * 5.0, 3.4 - 0.6, gear)
		"crown":
			var band := _arc(0, 0, HEAD_R + 0.5, 216, 328, 8)
			band.append_array(_arc(0, 0, HEAD_R + 8.0, 328, 216, 8))
			for a2 in [228.0, 250.0, 272.0, 294.0, 316.0]:
				var tri := PackedVector2Array()
				for da in [-7.0, 0.0, 7.0]:
					var rr := HEAD_R + (21.0 if da == 0.0 else 6.0)
					tri.append(Vector2(cos(deg_to_rad(a2 + da)), sin(deg_to_rad(a2 + da))) * rr)
				_poly(tri, gear, 2.2)
			_poly(band, gear, 2.2)
			var gp := Vector2(cos(deg_to_rad(300.0)), sin(deg_to_rad(300.0))) * (HEAD_R + 4.0)
			_ball(gp, 3.6, look.get("crest", Color("b04adf")))
		"wingcap":
			var cap := _arc(0, 0, HEAD_R + 3.0, 185, 352, 12)
			_poly(cap, gear)
			_seg(Vector2(-28, 2), Vector2(31, -3), 2.6 + 1.3, INK)
			_seg(Vector2(-28, 2), Vector2(31, -3), 2.0, gear.lightened(0.2))
			_poly(_pts([-6, -14, -20, -36, -40 + s, -44, -31, -30, -46 + s, -29, -31, -19, -40 + s, -13, -20, -7]), Color("f7f7ff"), 2.4)
		"pilos":
			var pil := _pts([-25.5, -1, -23, -22, -9, -44, 4, -46, 17, -30, 25, -8])
			_poly(pil, gear)
			_seg(Vector2(-27, 0), Vector2(27, -7), 2.6 + 1.3, INK)
			_seg(Vector2(-27, 0), Vector2(27, -7), 2.0, gear.darkened(0.2))
		"lion":
			var hood := _arc(0, 0, HEAD_R + 5.0, 170, 335, 12)
			hood.append_array(_pts([31, -13, 30, -5.5, 4, -7, -2, -2, -8, 6, -16, 10]))
			_poly(hood, gear)
			for a3 in [232.0, 282.0]:
				var ear := PackedVector2Array()
				for da2 in [-11.0, 0.0, 11.0]:
					var re := HEAD_R + (17.0 if da2 == 0.0 else 4.0)
					ear.append(Vector2(cos(deg_to_rad(a3 + da2)), sin(deg_to_rad(a3 + da2))) * re)
				_poly(ear, gear, 2.2)
			_poly(_pts([21, -6, 23.5, 2.5, 26.5, -5.6]), Color.WHITE, 1.6)
			_poly(_pts([10, -6.6, 12.5, 0.5, 15.5, -6.4]), Color.WHITE, 1.6)
			_stroke(Vector2(14, -17), Vector2(21, -14.5), INK, 2.6)
			_dot(Vector2(29.5, -10), 2.6, INK)
		"snakes":
			var green: Color = look.get("hair", Color("3f8a4f"))
			for i in 8:
				var a4 := deg_to_rad(168.0 + i * 24.0)
				var dir := Vector2(cos(a4), sin(a4))
				var perp := Vector2(-dir.y, dir.x)
				var pts: Array = []
				var radii: Array = []
				var n := 4 + (i % 2)
				for k in n + 1:
					var w := sin(t * 4.0 + i * 1.7 + k * 1.2) * (2.0 + k * 1.8)
					pts.append(dir * (HEAD_R - 4.0 + k * 8.5) + perp * w + Vector2(s * k * 0.12, 0))
					radii.append(4.6 - k * 0.25)
				_limb(pts, radii, green if i % 2 == 0 else green.darkened(0.15))
				var hd: Vector2 = pts[n]
				_ball(hd, 5.6, green.lightened(0.1))
				_dot(hd + perp * 1.5 + dir * 1.5, 1.5, Color("ffe14a"))
				_stroke(hd + dir * 5.0, hd + dir * 10.0, Color("d8324a"), 1.6)
		"diadem":
			_line(_arc(0, 0, HEAD_R + 1.5, 208, 334, 10), INK, 7.0)
			_line(_arc(0, 0, HEAD_R + 1.5, 209, 333, 10), gear, 4.0)
			var mc := Vector2(cos(deg_to_rad(292.0)), sin(deg_to_rad(292.0))) * (HEAD_R + 10.0)
			var moon := _arc(mc.x, mc.y, 9.0, 0, 180, 10)
			moon.append_array(_arc(mc.x, mc.y - 3.0, 9.3, 157, 23, 8))
			_poly(moon, gear.lightened(0.35), 2.0)
		"headband":
			var band_col: Color = look.get("crest", Color("c8322b"))
			var knot := Vector2(cos(deg_to_rad(202.0)), sin(deg_to_rad(202.0))) * (HEAD_R + 1.5)
			for dy in [-3.0, 5.0]:
				var e := knot + Vector2(-30 + s * 1.6, dy * 2.0 + 2.0 - lift * 0.5)
				_seg(knot, e, 2.6 + 1.3, INK)
				_seg(knot, e, 2.0, band_col)
			_line(_arc(0, 0, HEAD_R + 1.5, 200, 336, 10), INK, 8.0)
			_line(_arc(0, 0, HEAD_R + 1.5, 201, 335, 10), band_col, 5.0)


# ---------------------------------------------------------------------------
# Weapons (drawn in a frame at the front hand, x along the weapon)
# ---------------------------------------------------------------------------

static func weapon_angle(look: Dictionary, pose: Dictionary) -> float:
	var weapon: String = look.get("weapon", "none")
	if weapon in THRUST_WEAPONS:
		return pose.get("wt", pose.get("wa", -20.0))
	if weapon == "bow":
		return pose.get("wb", -90.0)
	return pose.get("wa", -60.0)


static func _weapon(j: Dictionary, look: Dictionary, pose: Dictionary, t: float) -> void:
	var weapon: String = look.get("weapon", "none")
	if weapon == "none":
		return
	var ang: float = deg_to_rad(weapon_angle(look, pose)) + j["rot"]
	_ci.draw_set_transform_matrix(_base * Transform2D(ang, j["hd_f"]))
	var metal: Color = look.get("weapon_col", Color("d9dde6"))
	var wood := Color("8a5a34")
	match weapon:
		"spear":
			_seg(Vector2(-62, 0), Vector2(98, 0), 3.0 + 1.5, INK)
			_seg(Vector2(-62, 0), Vector2(98, 0), 2.4, wood)
			_poly(_pts([94, 0, 104, -8, 134, 0, 104, 8]), metal, 2.4)
			_stroke(Vector2(100, 0), Vector2(128, 0), metal.darkened(0.25), 1.6)
			_poly(_pts([-62, -3.5, -76, 0, -62, 3.5]), metal, 2.0)
		"trident":
			_seg(Vector2(-66, 0), Vector2(84, 0), 3.4 + 1.5, INK)
			_seg(Vector2(-66, 0), Vector2(84, 0), 2.8, metal.darkened(0.25))
			_poly(_pts([82, -5, 88, -24, 122, -26, 114, -19, 96, -17, 95, -5, 128, 0, 95, 5, 96, 17, 114, 19, 122, 26, 88, 24, 82, 5]), metal, 2.4)
		"bident":
			_seg(Vector2(-66, 0), Vector2(84, 0), 3.4 + 1.5, INK)
			_seg(Vector2(-66, 0), Vector2(84, 0), 2.8, metal.darkened(0.3))
			_poly(_pts([80, -5, 88, -20, 126, -17, 118, -10, 98, -9, 96, 0, 98, 9, 118, 10, 126, 17, 88, 20, 80, 5]), metal, 2.4)
			_ball(Vector2(84, 0), 5.0, look.get("crest", Color("b04adf")))
		"sword":
			_poly(_pts([4, -5.5, 30, -7.5, 56, -5, 70, 0, 56, 5, 30, 7.5, 4, 5.5]), metal, 2.4)
			_stroke(Vector2(8, 0), Vector2(62, 0), metal.darkened(0.22), 1.6)
			_poly(_pts([0, -11, 5, -11, 5, 11, 0, 11]), look.get("trim", Color("e2b93b")), 2.0)
			_seg(Vector2(-12, 0), Vector2(0, 0), 3.2, wood.darkened(0.3))
			_ball(Vector2(-14, 0), 4.0, look.get("trim", Color("e2b93b")))
		"kopis":
			_poly(_pts([4, -5, 30, -9, 62, -15, 86, -8, 92, 2, 70, 10, 40, 8, 4, 5]), metal, 2.4)
			_line(_pts([10, 0, 44, -2, 80, -4]), metal.darkened(0.3), 1.8)
			_poly(_pts([0, -12, 5, -12, 5, 12, 0, 12]), look.get("trim", Color("3a3038")), 2.0)
			_seg(Vector2(-13, 0), Vector2(0, 0), 3.4, Color("2a2026"))
		"club":
			_poly(_pts([-12, -4, 30, -7, 62, -13, 84, -12, 92, 0, 84, 12, 62, 13, 30, 7, -12, 4]), wood, 2.6)
			for kp in [[58, -5], [72, 4], [80, -6], [66, 8], [46, 2]]:
				_dot(Vector2(kp[0], kp[1]), 2.4, wood.darkened(0.4))
			_line(_pts([0, -3.5, 40, -6, 70, -10]), wood.lightened(0.25), 2.0)
		"axe":
			_seg(Vector2(-34, 0), Vector2(80, 0), 3.2 + 1.5, INK)
			_seg(Vector2(-34, 0), Vector2(80, 0), 2.6, wood)
			_poly(_pts([58, -4, 50, -30, 66, -36, 82, -30, 74, -4]), metal, 2.4)
			_poly(_pts([58, 4, 50, 30, 66, 36, 82, 30, 74, 4]), metal, 2.4)
			_line(_pts([54, -28, 66, -32, 78, -28]), metal.lightened(0.5), 2.0)
			_line(_pts([54, 28, 66, 32, 78, 28]), metal.lightened(0.5), 2.0)
			_ball(Vector2(66, 0), 4.5, look.get("trim", Color("e2b93b")))
		"caduceus":
			var gold: Color = look.get("weapon_col", Color("e8c14a"))
			_seg(Vector2(-22, 0), Vector2(74, 0), 2.8 + 1.5, INK)
			_seg(Vector2(-22, 0), Vector2(74, 0), 2.2, gold)
			for sgn in [-1.0, 1.0]:
				var snake := PackedVector2Array()
				for k in 9:
					snake.append(Vector2(22.0 + k * 5.5, sgn * sin(k * 0.9) * 7.0))
				_line(snake, INK, 4.6)
				_line(snake, Color("4fa06a") if sgn < 0 else Color("3f8a8a"), 2.4)
				_poly(_pts([62, sgn * 3, 70, sgn * 22, 50, sgn * 26, 56, sgn * 16, 46, sgn * 14, 54, sgn * 5]), Color("f7f7ff"), 2.0)
			_ball(Vector2(77, 0), 5.0, gold.lightened(0.3))
		"bolt":
			var jit := sin(t * 40.0) * 1.5
			var zig := _pts([-34, -3, 0, -11 + jit, -4, -2, 34, -10 - jit, 30, -1, 98, 0, 40, 10, 44, 3 + jit, 6, 11, 10, 4 - jit, -30, 7])
			_line(zig, Color(1.0, 0.95, 0.5, 0.35), 12.0)
			_poly(zig, Color("fff4a8"), 2.4)
			_line(_pts([-30, -1, -2, -4, 30, -3, 60, -2, 88, 0]), Color.WHITE, 2.0)
		"bow":
			var limb_col: Color = look.get("weapon_col", Color("9a6a3a"))
			var bow := PackedVector2Array()
			for k in 13:
				var u := k / 12.0 * 2.0 - 1.0
				bow.append(Vector2(u * 56.0, (1.0 - u * u) * 20.0 - 4.0))
			# x runs along the bow stave (so "wb" = -90 holds it upright) and
			# +y is the way the arrow flies.
			_line(bow, INK, 8.0)
			_line(bow, limb_col, 5.0)
			var pull: float = pose.get("draw", 0.0)
			var mid := Vector2(0, -4.0 - pull * 44.0)
			_line(PackedVector2Array([bow[0], mid, bow[12]]), Color("efe9da"), 1.6)
			if pull > 0.3:
				_stroke(mid, mid + Vector2(0, 70), Color("e8dcc0"), 2.4)
				_poly(PackedVector2Array([mid + Vector2(-4, 68), mid + Vector2(0, 82), mid + Vector2(4, 68)]), Color("d9dde6"), 1.6)
	_ci.draw_set_transform_matrix(_base)
