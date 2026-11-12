class_name Fx
extends RefCounted

# Projectile art and one-shot effects (hit sparks, comic words, dust).
# Callers pass screen positions; `dir` is +1 when the thing travels right.

const INK := Color("17121c")
const WORDS := ["POW!", "WHAM!", "BAM!", "KRAK!", "THWACK!", "BOOM!"]

static var _ci: CanvasItem


static func _poly(flat: Array, col: Color, ink := 3.0) -> void:
	var pts := PackedVector2Array()
	for i in range(0, flat.size(), 2):
		pts.append(Vector2(flat[i], flat[i + 1]))
	_ci.draw_colored_polygon(pts, col)
	if ink > 0.0:
		pts.append(pts[0])
		_ci.draw_polyline(pts, INK, ink, true)


static func _circle(x: float, y: float, r: float, col: Color) -> void:
	_ci.draw_circle(Vector2(x, y), r, col, true, -1.0, true)


static func _ball(x: float, y: float, r: float, col: Color) -> void:
	_circle(x, y, r + 1.5, INK)
	_circle(x, y, r - 1.5, col)


static func _line(x0: float, y0: float, x1: float, y1: float, col: Color, w: float) -> void:
	_ci.draw_line(Vector2(x0, y0), Vector2(x1, y1), col, w, true)


static func _zigzag(from: Vector2, to: Vector2, steps: int, amp: float, seed: float) -> PackedVector2Array:
	var pts := PackedVector2Array([from])
	var d := to - from
	var n := Vector2(-d.y, d.x).normalized()
	for i in range(1, steps):
		var off := sin(seed * 7.3 + i * 12.7) * amp
		pts.append(from + d * (float(i) / steps) + n * off)
	pts.append(to)
	return pts


static func _burst(r_out: float, r_in: float, spikes: int, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in spikes * 2:
		var a := rot + i * PI / spikes
		pts.append(Vector2(cos(a), sin(a)) * (r_out if i % 2 == 0 else r_in))
	return pts


# --- projectiles -----------------------------------------------------------

static func projectile(ci: CanvasItem, p: Dictionary, pos: Vector2, floor_y: float, t: float) -> void:
	_ci = ci
	var dir: int = p["dir"]
	var kind: String = p["kind"]
	var age: float = p["age"]
	if p["delay"] > 0:
		# Telegraph on the ground where a delayed strike will land.
		var pulse := 0.5 + 0.5 * sin(t * 30.0)
		ci.draw_set_transform(Vector2(pos.x, floor_y), 0.0, Vector2(1.0, 0.25))
		ci.draw_arc(Vector2.ZERO, p["w"] * 0.6, 0.0, TAU, 24, Color(1, 0.9, 0.4, 0.4 + 0.5 * pulse), 6.0, true)
		_circle(0, 0, p["w"] * 0.45 * pulse, Color(1, 0.9, 0.4, 0.25))
		ci.draw_set_transform_matrix(Transform2D.IDENTITY)
		return
	var spin := 0.0
	if kind in ["caduceus", "axe", "apple", "boulder"]:
		spin = age * 0.45 * dir
	elif kind == "arrow" or kind == "venom":
		spin = Vector2(p["vx"] * dir, p["vy"]).angle()
	ci.draw_set_transform(pos, spin, Vector2(dir, 1.0))
	match kind:
		"bolt":
			_circle(0, 0, 40, Color(1, 0.95, 0.5, 0.25))
			var z := [-60, -4, -20, -14, -26, -3, 20, -13, 14, -2, 64, 0, 16, 12, 22, 3, -22, 13, -16, 4, -58, 8]
			_poly(z, Color("fff4a8"))
			_line(-50, 0, 54, 0, Color.WHITE, 3.0)
			for i in 3:
				var a := t * 30.0 + i * 2.1
				_line(-30 - i * 22, sin(a) * 14.0, -50 - i * 22, sin(a + 1.0) * 18.0, Color(1, 0.95, 0.5, 0.8), 3.0)
		"spear":
			_line(-70, 0, 40, 0, INK, 9.0)
			_line(-70, 0, 40, 0, Color("8a5a34"), 5.0)
			_poly([36, 0, 46, -9, 78, 0, 46, 9], Color("d9dde6"), 2.5)
			for i in 3:
				_line(-80 - i * 26, -8 + i * 8, -110 - i * 26, -8 + i * 8, Color(1, 1, 1, 0.5), 3.0)
		"arrow":
			_line(-40, 0, 26, 0, Color("e8dcc0"), 4.0)
			_poly([22, 0, 28, -7, 46, 0, 28, 7], Color("d9dde6"), 2.0)
			_poly([-44, 0, -52, -8, -38, -8, -30, 0, -38, 8, -52, 8], Color("d8dde8"), 2.0)
			_line(-56, 0, -96, 0, Color(1, 1, 1, 0.45), 3.0)
		"moonbeam", "megarrow":
			var c := Color("bfe0ff") if kind == "moonbeam" else Color("ffd98a")
			_poly([-130, -22, 60, -16, 120, 0, 60, 16, -130, 22, -100, 0], Color(c, 0.45), 0.0)
			_poly([-100, -10, 70, -8, 112, 0, 70, 8, -100, 10], c)
			_line(-90, 0, 96, 0, Color.WHITE, 4.0)
			for i in 4:
				_line(-140 - i * 30, sin(t * 20.0 + i) * 16.0, -180 - i * 30, sin(t * 20.0 + i) * 16.0, Color(c, 0.7), 4.0)
		"soul":
			var wob := sin(t * 9.0) * 5.0
			_circle(0, 0, 44, Color(0.6, 0.4, 1.0, 0.2))
			_poly([-70 + wob, -6, -30, -24, 0, -30, 24, -18, 30, 0, 24, 18, 0, 30, -30, 24, -62 - wob, 12, -40, 2], Color("9a6af0"))
			_ball(4, 0, 20, Color("e8e0ff"))
			_circle(-2, -4, 5, INK)
			_circle(12, -4, 5, INK)
			_poly([0, 8, 5, 14, 10, 8], INK, 0.0)
		"caduceus":
			_line(-34, 0, 34, 0, INK, 9.0)
			_line(-34, 0, 34, 0, Color("e8c14a"), 5.0)
			_poly([20, -4, 30, -26, 6, -22, 14, -14], Color("f7f7ff"), 2.0)
			_poly([20, 4, 30, 26, 6, 22, 14, 14], Color("f7f7ff"), 2.0)
			_ball(36, 0, 7, Color("fff2a8"))
		"axe":
			_line(-30, 0, 30, 0, INK, 9.0)
			_line(-30, 0, 30, 0, Color("8a5a34"), 5.0)
			_poly([10, -4, 2, -32, 20, -38, 36, -30, 28, -4], Color("d9dde6"), 2.5)
			_poly([10, 4, 2, 32, 20, 38, 36, 30, 28, 4], Color("d9dde6"), 2.5)
		"apple":
			_ball(0, 0, 18, Color("f5c542"))
			_circle(-5, -6, 5, Color("fff2a8"))
			_poly([0, -16, 10, -30, 16, -18], Color("5aa84a"), 2.0)
		"boulder":
			_poly([-34, -10, -18, -34, 14, -36, 36, -14, 32, 20, 6, 36, -24, 30], Color("8a8078"))
			_line(-14, -18, 4, -6, INK, 3.0)
			_line(10, 10, 22, 0, INK, 3.0)
			_circle(-10, 12, 5, Color("6a625c"))
		"venom":
			_poly([-46, 0, -10, -16, 14, -18, 26, 0, 14, 18, -10, 16], Color("6fd04a"))
			_circle(8, -5, 5, Color("c8ff9a"))
			_circle(-58, 4, 5, Color("6fd04a"))
		"wave", "bigwave":
			var s: float = p["h"] / 112.0
			var roll := sin(t * 10.0) * 6.0
			_poly([-60 * s, 0, -50 * s, -60 * s, -10 * s, -104 * s, 40 * s + roll, -112 * s, 62 * s + roll, -84 * s, 34 * s, -78 * s,
				20 * s, -50 * s, 44 * s, 0], Color("2f8fd6"))
			_poly([-10 * s, -104 * s, 40 * s + roll, -112 * s, 62 * s + roll, -84 * s, 34 * s, -78 * s, 12 * s, -90 * s], Color("eaf8ff"), 2.5)
			_line(-34 * s, -10 * s, -26 * s, -62 * s, Color("8fd0ff"), 5.0)
			_line(-6 * s, -10 * s, 0, -52 * s, Color("8fd0ff"), 5.0)
			for i in 3:
				_circle(-70 * s - i * 26.0, -8.0 - absf(sin(t * 12.0 + i)) * 20.0, 8.0, Color("eaf8ff"))
		"horse":
			var wood := Color("9a6a3c")
			var bobble := sin(t * 14.0) * 2.0
			for k in [-30.0, 26.0]:
				_poly([k - 6, -22, k + 6, -22, k + 6, -50, k - 6, -50], wood.darkened(0.15), 2.5)
			_poly([-48, -52 + bobble, -42, -92 + bobble, 36, -92 + bobble, 44, -52 + bobble], wood)
			_poly([22, -88 + bobble, 36, -132 + bobble, 54, -138 + bobble, 72, -116 + bobble, 62, -108 + bobble, 50, -116 + bobble, 44, -88 + bobble], wood)
			_circle(56, -126 + bobble, 3, INK)
			_poly([-46, -90 + bobble, -64, -64 + bobble, -54, -60 + bobble, -42, -78 + bobble], Color("5a3a24"), 2.5)
			_poly([-56, -24, 56, -24, 56, -16, -56, -16], wood.darkened(0.3), 2.5)
			for k in [-38.0, 38.0]:
				_ball(k, -12, 13, wood.darkened(0.1))
				_line(k, -12, k + cos(age * 0.4) * 9.0, -12 + sin(age * 0.4) * 9.0, INK, 3.0)
		"argo":
			var wood2 := Color("a8743e")
			var bob := sin(t * 5.0) * 4.0
			_poly([-150, -70 + bob, -120, -10 + bob, 110, -10 + bob, 170, -96 + bob, 120, -66 + bob, -110, -66 + bob], wood2, 4.0)
			_line(-10, -66 + bob, -10, -230 + bob, INK, 12.0)
			_line(-10, -66 + bob, -10, -230 + bob, wood2.darkened(0.15), 7.0)
			_poly([-96, -214 + bob, 80, -214 + bob, 96, -150 + bob, 80, -92 + bob, -96, -92 + bob, -84, -150 + bob], Color("f4ead0"), 4.0)
			_poly([-88, -170 + bob, 90, -170 + bob, 94, -146 + bob, -84, -146 + bob], Color("2f5fb8"), 0.0)
			for k in 5:
				_ball(-100.0 + k * 44.0, -52 + bob, 13, [Color("a8201e"), Color("e2b93b"), Color("2f7a4f")][k % 3])
				var sw := sin(t * 8.0 + k) * 12.0
				_line(-100.0 + k * 44.0, -30 + bob, -120.0 + k * 44.0 - sw, 8, Color("6a4a2a"), 4.0)
			_circle(150, -84 + bob, 5, Color.WHITE)
			for i in 4:
				_circle(-170.0 - i * 30.0, -6.0 - absf(sin(t * 10.0 + i)) * 22.0, 10.0, Color("eaf8ff"))
		"skybolt", "megabolt":
			var wide: float = p["w"]
			var top := -floor_y - 20.0
			for k in (3 if kind == "megabolt" else 1):
				var ox := (k - 1) * wide * 0.3 if kind == "megabolt" else 0.0
				var pts := _zigzag(Vector2(ox + sin(t * 50.0 + k) * 10.0, top), Vector2(ox, 0), 9, wide * 0.22, floor(t * 30.0) + k)
				ci.draw_polyline(pts, Color(1, 0.95, 0.5, 0.35), wide * 0.5, true)
				ci.draw_polyline(pts, Color("fff4a8"), 14.0, true)
				ci.draw_polyline(pts, Color.WHITE, 5.0, true)
			_circle(0, 0, wide * 0.5, Color(1, 0.95, 0.6, 0.5))
			ci.draw_colored_polygon(_burst(wide * 0.6, wide * 0.25, 8, t * 20.0), Color("fff4a8"))
		"pillar":
			var w2: float = p["w"]
			for k in 5:
				var fx := (k - 2) * w2 * 0.2
				var fh := floor_y * (0.7 + 0.3 * sin(t * 14.0 + k * 1.9))
				_poly([fx - w2 * 0.16, 0, fx - w2 * 0.1, -fh * 0.6, fx + sin(t * 20.0 + k) * 10.0, -fh, fx + w2 * 0.1, -fh * 0.6, fx + w2 * 0.16, 0],
					Color("7a3ad0") if k % 2 == 0 else Color("b86af0"), 0.0)
			_poly([-w2 * 0.2, 0, -w2 * 0.1, -floor_y * 0.5, 0, -floor_y * 0.75, w2 * 0.1, -floor_y * 0.5, w2 * 0.2, 0], Color("e8d0ff"), 0.0)
			ci.draw_set_transform(pos, 0.0, Vector2(1.0, 0.25))
			ci.draw_arc(Vector2.ZERO, w2 * 0.6, 0.0, TAU, 24, Color("b86af0"), 8.0, true)
		"hands":
			var up := minf(1.0, age / 4.0)
			for k in [-28.0, 4.0, 34.0]:
				var hh: float = (110.0 + k * 0.6) * up + sin(t * 16.0 + k) * 5.0
				_line(k, 0, k + 6, -hh, INK, 17.0)
				_line(k, 0, k + 6, -hh, Color("7fd8c0"), 11.0)
				for fng in [-10.0, -3.0, 4.0, 11.0]:
					_line(k + 6, -hh, k + 6 + fng, -hh - 18.0, INK, 7.0)
					_line(k + 6, -hh, k + 6 + fng, -hh - 18.0, Color("b8f5e0"), 3.5)
			_circle(0, 0, 50, Color(0.5, 1.0, 0.85, 0.2))
		"spartoi":
			var rise := minf(1.0, age / 3.0) * 150.0
			var bone := Color("ece6d2")
			_line(0, 0, 0, -rise * 0.62, INK, 12.0)
			_line(0, 0, 0, -rise * 0.62, bone, 7.0)
			for rb in [0.3, 0.42, 0.54]:
				_line(-18, -rise * rb, 18, -rise * rb, INK, 8.0)
				_line(-18, -rise * rb, 18, -rise * rb, bone, 4.0)
			_ball(0, -rise * 0.8, 19, bone)
			_circle(-6, -rise * 0.82, 4, INK)
			_circle(7, -rise * 0.82, 4, INK)
			_line(-7, -rise * 0.72, 8, -rise * 0.72, INK, 2.5)
			_line(18, -rise * 0.54, 44, -rise * 0.9, INK, 8.0)
			_line(18, -rise * 0.54, 44, -rise * 0.9, bone, 4.0)
			_poly([40, -rise * 0.9, 52, -rise * 0.9 - 60, 60, -rise * 0.9 - 56, 52, -rise * 0.9 + 4], Color("d9dde6"), 2.5)
			_poly([-12, -rise * 0.94, 0, -rise * 0.94 - 22, 12, -rise * 0.94], Color("c9973a"), 2.5)
			for k in [-40.0, 40.0]:
				_poly([k - 14, 0, k, -22, k + 14, 0], Color("6a4a32"), 2.5)
		_:
			_ball(0, 0, 22, Color("ffd24a"))
			_circle(-4, -5, 7, Color.WHITE)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


# --- one-shot effects ------------------------------------------------------

# e: {kind, x, y, t, life, size, col, word, rot} with x/y already on screen.
static func effect(ci: CanvasItem, e: Dictionary) -> void:
	_ci = ci
	var u: float = float(e["t"]) / e["life"]
	var size: float = e.get("size", 1.0)
	var pos := Vector2(e["x"], e["y"])
	match e["kind"]:
		"spark":
			var grow := 0.55 + 0.75 * sqrt(u)
			var a := 1.0 if u < 0.55 else 1.0 - (u - 0.55) / 0.45
			ci.draw_set_transform(pos, e["rot"], Vector2(size * grow, size * grow))
			var outer := _burst(64.0, 26.0, 9, 0.0)
			ci.draw_colored_polygon(outer, Color(e["col"], a))
			outer.append(outer[0])
			ci.draw_polyline(outer, Color(INK, a), 3.5, true)
			ci.draw_colored_polygon(_burst(40.0, 16.0, 9, 0.35), Color(1, 0.95, 0.55, a))
			ci.draw_colored_polygon(_burst(20.0, 9.0, 9, 0.0), Color(1, 1, 1, a))
		"block":
			var a2 := 1.0 - u
			ci.draw_set_transform(pos, 0.0, Vector2(size, size))
			ci.draw_arc(Vector2.ZERO, 20.0 + u * 46.0, 0.0, TAU, 24, Color(0.7, 0.9, 1.0, a2), 7.0 * (1.0 - u) + 1.0, true)
			for i in 6:
				var d := Vector2.RIGHT.rotated(i * TAU / 6.0 + e["rot"])
				ci.draw_line(d * (24.0 + u * 30.0), d * (40.0 + u * 50.0), Color(1, 1, 1, a2), 4.0, true)
		"dust":
			ci.draw_set_transform(pos, 0.0, Vector2.ONE)
			for i in 4:
				var dx := (i - 1.5) * 26.0 * (0.4 + u) * size
				_circle(dx, -u * 18.0 - (i % 2) * 6.0, (15.0 - u * 9.0) * size, Color(0.92, 0.88, 0.8, 0.6 * (1.0 - u)))
		"ring":
			ci.draw_set_transform(pos, 0.0, Vector2(size, size))
			ci.draw_arc(Vector2.ZERO, 16.0 + u * 90.0, 0.0, TAU, 28, Color(e["col"], 1.0 - u), 9.0 * (1.0 - u) + 1.0, true)
		"word":
			var pop := 1.0 + 0.5 * maxf(0.0, 1.0 - u * 5.0)
			var a3 := 1.0 if u < 0.7 else 1.0 - (u - 0.7) / 0.3
			ci.draw_set_transform(pos + Vector2(0, -u * 30.0), e["rot"], Vector2(pop, pop) * size)
			var w := UI.width(e["word"], 54)
			UI.text(ci, Vector2(-w * 0.5, 0), e["word"], 54, Color(e["col"], a3))
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
