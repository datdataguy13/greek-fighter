class_name StageArt
extends RefCounted

# The arenas, drawn in code as layered parallax scenes. Everything is in
# 1280x720 screen space; _x() turns a world x into a screen x for a layer
# (par 0 = fixed sky, 1 = moves with the fighters). To add a stage, add an
# entry to LIST and a matching _<id>() function.

const FLOOR := 620.0  # where fighters' feet stand
const GROUND_TOP := 584.0
const INK := Color("17121c")

const LIST := [
	{"id": "olympus", "name": "Mount Olympus", "sub": "Home of the gods"},
	{"id": "troy", "name": "Walls of Troy", "sub": "The Iliad"},
	{"id": "styx", "name": "River Styx", "sub": "The Underworld"},
	{"id": "labyrinth", "name": "The Labyrinth", "sub": "Crete"},
	{"id": "argo", "name": "Deck of the Argo", "sub": "The Argonautica"},
	{"id": "acropolis", "name": "The Acropolis", "sub": "Athens"},
	{"id": "delphi", "name": "Oracle of Delphi", "sub": "Mount Parnassus"},
	{"id": "cyclops", "name": "Cyclops' Cave", "sub": "The Odyssey"},
]

static var _ci: CanvasItem
static var _cam := 0.0
static var _t := 0.0
static var _xf := Transform2D.IDENTITY


static func draw(ci: CanvasItem, id: String, cam_x: float, time: float, xf: Transform2D = Transform2D.IDENTITY) -> void:
	_ci = ci
	_cam = cam_x
	_t = time
	_xf = xf
	ci.draw_set_transform_matrix(xf)
	match id:
		"olympus":
			_olympus()
		"troy":
			_troy()
		"styx":
			_styx()
		"labyrinth":
			_labyrinth()
		"argo":
			_argo()
		"acropolis":
			_acropolis()
		"delphi":
			_delphi()
		"cyclops":
			_cyclops()
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


# --- helpers ---------------------------------------------------------------

static func _x(wx: float, par: float) -> float:
	return wx - _cam * par


static func _h(i: float) -> float:
	return fposmod(sin(i * 12.9898) * 43758.5453, 1.0)


static func _grad(r: Rect2, top: Color, bot: Color) -> void:
	_ci.draw_polygon(
		PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bot, bot]))


static func _rect(x: float, y: float, w: float, h: float, col: Color, ink := 0.0) -> void:
	_ci.draw_rect(Rect2(x, y, w, h), col)
	if ink > 0.0:
		_ci.draw_rect(Rect2(x, y, w, h), INK, false, ink)


static func _poly(flat: Array, col: Color, ox := 0.0, oy := 0.0, ink := 0.0) -> void:
	var pts := PackedVector2Array()
	for i in range(0, flat.size(), 2):
		pts.append(Vector2(flat[i] + ox, flat[i + 1] + oy))
	_ci.draw_colored_polygon(pts, col)
	if ink > 0.0:
		pts.append(pts[0])
		_ci.draw_polyline(pts, INK, ink, true)


static func _circle(x: float, y: float, r: float, col: Color) -> void:
	_ci.draw_circle(Vector2(x, y), r, col, true, -1.0, true)


static func _line(x0: float, y0: float, x1: float, y1: float, col: Color, w: float) -> void:
	_ci.draw_line(Vector2(x0, y0), Vector2(x1, y1), col, w, true)


static func _cloud(x: float, y: float, s: float, col: Color) -> void:
	for c in [[0, 0, 34], [38, -12, 42], [84, -2, 36], [122, 6, 26], [-34, 8, 24], [44, 14, 40]]:
		_circle(x + c[0] * s, y + c[1] * s, c[2] * s, col)


static func _stars(n: int, max_y: float, col: Color) -> void:
	for i in n:
		var tw := 0.6 + 0.4 * sin(_t * 2.0 + i * 1.7)
		_circle(_h(i + 1.0) * 1280.0, _h(i + 50.0) * max_y, 1.0 + _h(i + 99.0) * 1.6, Color(col, col.a * tw))


# A rolling ridge line across the screen for hills and far mountains.
static func _ridge(par: float, base_y: float, amp: float, freq: float, col: Color, seed := 0.0) -> void:
	var pts := PackedVector2Array([Vector2(-10, 720)])
	var x := -10.0
	while x <= 1300.0:
		var wx := x + _cam * par + seed * 311.0
		var y := base_y - amp * (0.6 * sin(wx * freq) + 0.4 * sin(wx * freq * 2.3 + 1.7))
		pts.append(Vector2(x, y))
		x += 26.0
	pts.append(Vector2(1300, 720))
	_ci.draw_colored_polygon(pts, col)


static func _column(x: float, top: float, bot: float, w: float, col: Color, ink := 3.0) -> void:
	var shade := col.darkened(0.16)
	_rect(x - w * 0.5, top, w, bot - top, col)
	_rect(x + w * 0.12, top, w * 0.38, bot - top, shade)
	for k in [-0.3, -0.1, 0.1, 0.3]:
		_line(x + w * k, top + 6, x + w * k, bot - 6, col.darkened(0.28), 1.5)
	if ink > 0.0:
		_ci.draw_rect(Rect2(x - w * 0.5, top, w, bot - top), INK, false, ink)
	_rect(x - w * 0.72, top - w * 0.3, w * 1.44, w * 0.3, col, ink)
	_rect(x - w * 0.6, top - w * 0.12, w * 1.2, w * 0.18, shade, ink)
	_rect(x - w * 0.68, bot - w * 0.2, w * 1.36, w * 0.24, col, ink)


static func _flame(x: float, y: float, s: float, seed: float, core := Color("ffe27a"), outer := Color("f2762e")) -> void:
	var f1 := sin(_t * 11.0 + seed) * 6.0 * s
	var f2 := sin(_t * 17.0 + seed * 2.0) * 4.0 * s
	_circle(x, y - 20.0 * s, 70.0 * s, Color(outer, 0.13))
	_poly([-22 * s, 0, -26 * s, -26 * s, -8 * s + f2, -44 * s, f1, -84 * s, 12 * s + f2, -46 * s, 26 * s, -24 * s, 20 * s, 0], outer, x, y)
	_poly([-11 * s, 0, -12 * s, -18 * s, f2, -52 * s, 12 * s, -16 * s, 10 * s, 0], core, x, y)


static func _brazier(x: float, y: float, seed: float, core := Color("ffe27a"), outer := Color("f2762e")) -> void:
	_flame(x, y - 96, 1.0, seed, core, outer)
	_poly([-34, -100, 34, -100, 22, -78, -22, -78], Color("6a5a48"), x, y, 3.0)
	_rect(x - 5, y - 78, 10, 70, Color("5a4a3a"), 3.0)
	_poly([-26, 0, -8, -12, 8, -12, 26, 0], Color("5a4a3a"), x, y, 3.0)


static func _floor(top: Color, bot: Color, line: Color, tile := 150.0) -> void:
	_grad(Rect2(0, GROUND_TOP, 1280, 720 - GROUND_TOP), top, bot)
	var first := floorf(_cam / tile) * tile
	var wx := first - tile * 4.0
	while wx < _cam + 1280.0 + tile * 4.0:
		var sx := wx - _cam
		_line(sx, GROUND_TOP, 640.0 + (sx - 640.0) * 1.45, 720.0, line, 2.0)
		wx += tile
	for y in [GROUND_TOP + 22.0, GROUND_TOP + 62.0]:
		_line(0, y, 1280, y, line, 2.0)
	_line(0, GROUND_TOP, 1280, GROUND_TOP, INK, 4.0)


static func _temple(cx: float, base: float, cols: int, gap: float, height: float, col: Color, par: float) -> void:
	var x0 := _x(cx, par) - (cols - 1) * gap * 0.5
	var half := (cols - 1) * gap * 0.5 + gap * 0.6
	var c := _x(cx, par)
	for k in 3:
		_rect(c - half - 30 + k * 12, base - 14.0 * (k + 1), (half + 30 - k * 12) * 2.0, 14, col.darkened(0.06 * k), 3.0)
	var top := base - 42.0 - height
	_rect(c - half + 10, top + 30, (half - 10) * 2.0, height - 30, col.darkened(0.45))
	for i in cols:
		_column(x0 + i * gap, top + 34, base - 42, gap * 0.34, col)
	_rect(c - half, top - 16, half * 2.0, 34, col, 3.0)
	for i in range(int(-half / 30.0) + 1, int(half / 30.0)):
		_line(c + i * 30.0, top - 10, c + i * 30.0, top + 12, col.darkened(0.3), 3.0)
	_poly([-half - 12, -16, 0, -16 - half * 0.42, half + 12, -16], col.lightened(0.05), c, top, 3.0)
	_circle(c, top - 16 - half * 0.16, half * 0.09, Color("f5c542"))


# --- stages ----------------------------------------------------------------

static func _olympus() -> void:
	_grad(Rect2(0, 0, 1280, 720), Color("21409a"), Color("f9cf96"))
	var sx := _x(760, 0.05)
	_circle(sx, 260, 190, Color(1, 0.93, 0.7, 0.18))
	_circle(sx, 260, 130, Color(1, 0.93, 0.7, 0.28))
	_circle(sx, 260, 86, Color("fff1c4"))
	for i in 6:
		_cloud(fposmod(i * 300.0 + _t * 7.0 - _cam * 0.1, 1700.0) - 200.0, 150.0 + _h(i + 3.0) * 150.0, 1.1, Color(1, 1, 1, 0.5))
	for p in [[200, 250, 260], [760, 190, 330], [1350, 270, 240]]:
		var px := _x(p[0], 0.2)
		_poly([-p[2], 520, 0, p[1], p[2], 520], Color("6a78c2"), px)
		_poly([-p[2] * 0.2, p[1] + (520 - p[1]) * 0.2, 0, p[1], p[2] * 0.2, p[1] + (520 - p[1]) * 0.2, p[2] * 0.06, p[1] + 44, -p[2] * 0.08, p[1] + 58],
			Color("eef2ff"), px)
	for i in 9:
		_cloud(_x(i * 230.0 - 80.0, 0.3), 500.0 + _h(i + 9.0) * 26.0, 1.5, Color("fdf6ea"))
	_rect(0, 520, 1280, 80, Color("fdf6ea"))
	_temple(1000, 590, 6, 86, 250, Color("f3ead6"), 0.5)
	for i in 5:
		_cloud(_x(i * 420.0 + 100.0, 0.7), 566.0, 1.2, Color(1, 1, 1, 0.85))
	_floor(Color("f1e8d4"), Color("b5a688"), Color("9a8a6c"))
	_rect(0, GROUND_TOP, 1280, 7, Color("e2b93b"))
	for wx in [140.0, 1760.0]:
		_column(_x(wx, 1.0), 40, GROUND_TOP + 4, 96, Color("f7efdc"), 4.0)
	for wx in [560.0, 1340.0]:
		_brazier(_x(wx, 1.0), GROUND_TOP + 6, wx)


static func _troy() -> void:
	_grad(Rect2(0, 0, 1280, 720), Color("160f2a"), Color("b8432a"))
	_stars(60, 300, Color(1, 0.95, 0.85, 0.9))
	_circle(_x(300, 0.04), 130, 54, Color("f6e7c8"))
	_circle(_x(322, 0.04), 118, 50, Color("2a1634"))
	# Burning city behind the wall.
	for i in 9:
		var fx := _x(i * 190.0 + 40.0, 0.25)
		_flame(fx, 390, 1.9 + _h(i + 1.0) * 0.9, i * 3.1)
		_circle(fx + sin(_t * 0.6 + i) * 30.0, 250 - fposmod(_t * 18.0 + i * 37.0, 160.0), 44, Color(0.1, 0.07, 0.12, 0.22))
	# The wall.
	var wall := Color("7a5a48")
	_rect(0, 330, 1280, 270, wall)
	var bx := -fposmod(_cam * 0.35, 96.0)
	while bx < 1290.0:
		_rect(bx, 300, 56, 34, wall, 3.0)
		bx += 96.0
	_line(0, 332, 1280, 332, INK, 3.0)
	for row in 7:
		var y := 360.0 + row * 34.0
		_line(0, y, 1280, y, wall.darkened(0.25), 2.0)
		var ox := -fposmod(_cam * 0.35 + (48.0 if row % 2 == 0 else 0.0), 96.0)
		while ox < 1290.0:
			_line(ox, y, ox, y + 34, wall.darkened(0.25), 2.0)
			ox += 96.0
	for wx in [260.0, 1180.0]:
		var tx := _x(wx, 0.35)
		_rect(tx - 80, 220, 160, 380, wall.lightened(0.06), 4.0)
		for k in 3:
			_rect(tx - 80 + k * 60, 190, 40, 32, wall.lightened(0.06), 3.0)
		_poly([-22, 0, -22, -60, 0, -84, 22, -60, 22, 0], Color("1c1016"), tx, 420, 3.0)
	# The gate.
	var gx := _x(760, 0.35)
	_poly([-110, 0, -110, -190, -60, -250, 60, -250, 110, -190, 110, 0], Color("2a1a18"), gx, 600, 4.0)
	for k in [-55.0, 0.0, 55.0]:
		_line(gx + k, 600, gx + k, 372, Color("5a3a24"), 6.0)
	# The horse.
	var hx := _x(1240, 0.6)
	var wood := Color("9a6a3c")
	for k in [-90.0, -40.0, 50.0, 100.0]:
		_rect(hx + k - 10, 430, 20, 130, wood.darkened(0.15), 3.0)
	_poly([-130, 440, -120, 330, 110, 330, 130, 440], wood, hx, 0, 4.0)
	_poly([70, 340, 110, 210, 150, 196, 200, 250, 176, 268, 150, 250, 140, 340], wood, hx, 0, 4.0)
	_poly([112, 210, 100, 176, 128, 198], wood.darkened(0.2), hx, 0, 3.0)
	_poly([-124, 340, -170, 420, -150, 430, -110, 370], Color("5a3a24"), hx, 0, 3.0)
	_circle(hx + 160, 224, 5, INK)
	for k in [-70.0, -20.0, 30.0, 80.0]:
		_line(hx + k, 334, hx + k, 436, wood.darkened(0.3), 2.5)
	_rect(hx - 150, 556, 300, 16, wood.darkened(0.3), 3.0)
	for k in [-110.0, 110.0]:
		_circle(hx + k, 580, 26, INK)
		_circle(hx + k, 580, 21, wood.darkened(0.1))
		_circle(hx + k, 580, 6, INK)
	_floor(Color("b08a5a"), Color("5c4026"), Color("7c5c3a"), 190.0)
	for wx in [420.0, 980.0, 1560.0]:
		var px := _x(wx, 1.0)
		_line(px, GROUND_TOP + 14, px + 26, GROUND_TOP - 96, Color("6a4a2a"), 5.0)
		_poly([18, -92, 30, -128, 38, -94], Color("c9ccd6"), px, GROUND_TOP, 2.5)
	_circle(_x(700, 1.0), GROUND_TOP + 8, 30, INK)
	_circle(_x(700, 1.0), GROUND_TOP + 8, 26, Color("a8201e"))
	_circle(_x(700, 1.0), GROUND_TOP + 8, 9, Color("c9973a"))


static func _styx() -> void:
	_grad(Rect2(0, 0, 1280, 720), Color("07090f"), Color("0f3a3c"))
	_ridge(0.2, 430, 60, 0.006, Color("0c1c22"), 1.0)
	# The river.
	_grad(Rect2(0, 440, 1280, 160), Color("1c7a6c"), Color("0c3a3e"))
	for row in 6:
		var y := 456.0 + row * 24.0
		var pts := PackedVector2Array()
		var x := -20.0
		while x <= 1300.0:
			pts.append(Vector2(x, y + sin((x + _cam * 0.4) * 0.03 + _t * 1.6 + row * 1.3) * 4.0))
			x += 40.0
		_ci.draw_polyline(pts, Color(0.6, 1.0, 0.85, 0.28), 3.0, true)
	# Charon's boat.
	var bx := fposmod(_t * 14.0, 2300.0) - 200.0 - _cam * 0.4
	var by := 478.0 + sin(_t * 1.4) * 4.0
	_poly([-110, 0, -90, 34, 90, 34, 124, -14, 70, 6, -70, 6], Color("1a1418"), bx, by, 3.0)
	_poly([-14, 8, -22, -70, 0, -96, 20, -70, 14, 8], Color("241c26"), bx - 20, by, 3.0)
	_circle(bx - 12, by - 72, 5, Color("9ff5d8"))
	_line(bx + 40, by + 30, bx + 6, by - 110, Color("3a2a22"), 4.0)
	_circle(bx + 84, by - 30, 26, Color(0.6, 1, 0.8, 0.16))
	_circle(bx + 84, by - 30, 8, Color("c8ffe6"))
	_line(bx + 84, by - 22, bx + 84, by + 4, Color("3a2a22"), 3.0)
	# Wandering souls.
	for i in 9:
		var sx := fposmod(_h(i + 2.0) * 1900.0 + _t * (8.0 + i) - _cam * 0.55, 1500.0) - 100.0
		var sy := 200.0 + _h(i + 7.0) * 230.0 + sin(_t * 1.3 + i) * 16.0
		_circle(sx, sy, 20, Color(0.7, 1, 0.9, 0.10))
		_circle(sx, sy, 11, Color(0.8, 1, 0.92, 0.5))
		_poly([-9, 4, 0, 40 + sin(_t * 3.0 + i) * 6.0, 9, 4], Color(0.8, 1, 0.92, 0.35), sx, sy)
		_circle(sx - 3, sy - 2, 2, Color("0c2a2a"))
		_circle(sx + 4, sy - 2, 2, Color("0c2a2a"))
	# Stalactites.
	for i in 14:
		var tx := _x(i * 170.0 + _h(i + 5.0) * 80.0, 0.8)
		var hgt := 90.0 + _h(i + 11.0) * 170.0
		_poly([-34, -4, 0, hgt, 34, -4], Color("161a22"), tx, 0, 3.0)
	_floor(Color("2a3038"), Color("0e1014"), Color("3c4852"), 170.0)
	for wx in [300.0, 860.0, 1500.0]:
		var px := _x(wx, 1.0)
		_circle(px, GROUND_TOP + 4, 15, INK)
		_circle(px, GROUND_TOP + 4, 12, Color("d8d4c4"))
		_circle(px - 4, GROUND_TOP + 2, 3, INK)
		_circle(px + 5, GROUND_TOP + 2, 3, INK)
		_line(px + 22, GROUND_TOP + 12, px + 60, GROUND_TOP + 4, Color("d8d4c4"), 5.0)
	for wx in [520.0, 1380.0]:
		_brazier(_x(wx, 1.0), GROUND_TOP + 6, wx, Color("d6fff0"), Color("2fd0a0"))


static func _labyrinth() -> void:
	_grad(Rect2(0, 0, 1280, 720), Color("1c1612"), Color("4a3a2a"))
	var stone := Color("8a7458")
	# Back wall with dark archways.
	_rect(0, 90, 1280, 510, stone.darkened(0.3))
	for row in 9:
		var y := 90.0 + row * 58.0
		_line(0, y, 1280, y, stone.darkened(0.5), 3.0)
		var ox := -fposmod(_cam * 0.6 + (70.0 if row % 2 == 0 else 0.0), 140.0)
		while ox < 1290.0:
			_line(ox, y, ox, y + 58, stone.darkened(0.5), 3.0)
			ox += 140.0
	var k := 0
	for wx in [200.0, 700.0, 1200.0, 1700.0]:
		var ax := _x(wx, 0.6)
		_poly([-120, 0, -120, -250, -80, -330, 0, -366, 80, -330, 120, -250, 120, 0], Color("0c0a0a"), ax, 600, 5.0)
		_poly([-150, 0, -150, -260, -100, -356, 0, -400, 100, -356, 150, -260, 150, 0, 120, 0, 120, -250, 80, -330, 0, -366, -80, -330, -120, -250, -120, 0],
			stone, ax, 600, 4.0)
		if k == 1:
			# Something is in there.
			var blink := 0.0 if fposmod(_t, 4.0) < 0.15 else 1.0
			_poly([-70, -250, -96, -310, -50, -282], Color("2a2220"), ax, 600)
			_poly([70, -250, 96, -310, 50, -282], Color("2a2220"), ax, 600)
			_circle(ax - 26, 372, 7 * blink, Color("ff4a2a"))
			_circle(ax + 26, 372, 7 * blink, Color("ff4a2a"))
			_circle(ax, 372, 60, Color(1, 0.3, 0.15, 0.06))
		k += 1
	for wx in [450.0, 950.0, 1450.0]:
		var tx := _x(wx, 0.6)
		_circle(tx, 300, 130, Color(1, 0.7, 0.3, 0.10))
		_flame(tx, 318, 0.7, wx)
		_poly([-8, 0, 8, 0, 5, 60, -5, 60], Color("4a3424"), tx, 318, 3.0)
	# Bull-horn frieze.
	_rect(0, 60, 1280, 36, stone, 4.0)
	var hx := -fposmod(_cam * 0.6, 180.0)
	while hx < 1300.0:
		_poly([-26, 0, -34, -30, -18, -12, 0, -8, 18, -12, 34, -30, 26, 0], Color("d8c8a0"), hx + 90, 92, 2.5)
		hx += 180.0
	_floor(Color("9a8468"), Color("3c3024"), Color("5e4e3a"), 130.0)
	# Ariadne's thread.
	var thread := PackedVector2Array()
	var x := -20.0
	while x <= 1300.0:
		thread.append(Vector2(x, 676.0 + sin((x + _cam) * 0.012) * 16.0 + sin((x + _cam) * 0.05) * 3.0))
		x += 30.0
	_ci.draw_polyline(thread, Color("c8201e"), 3.5, true)
	for wx in [120.0, 1780.0]:
		_column(_x(wx, 1.0), 110, GROUND_TOP + 4, 90, stone.lightened(0.1), 4.0)


static func _argo() -> void:
	_grad(Rect2(0, 0, 1280, 720), Color("2f7fd6"), Color("bfe6f5"))
	_circle(_x(980, 0.03), 120, 60, Color("fff6cf"))
	for i in 6:
		_cloud(fposmod(i * 330.0 + _t * 10.0 - _cam * 0.08, 1800.0) - 220.0, 100.0 + _h(i + 4.0) * 170.0, 1.2, Color(1, 1, 1, 0.9))
	_ridge(0.12, 420, 26, 0.004, Color("6fa0c8"), 2.0)
	# Sea.
	_grad(Rect2(0, 410, 1280, 200), Color("1f6fb0"), Color("0f3f78"))
	for row in 7:
		var y := 424.0 + row * 24.0
		var pts := PackedVector2Array()
		var x := -20.0
		while x <= 1300.0:
			pts.append(Vector2(x, y + sin((x + _cam * (0.2 + row * 0.08)) * 0.025 + _t * (1.2 + row * 0.2) + row) * (3.0 + row)))
			x += 36.0
		_ci.draw_polyline(pts, Color(1, 1, 1, 0.35), 3.0, true)
	for i in 3:
		var gx := fposmod(i * 500.0 + _t * 40.0, 1700.0) - 200.0
		var gy := 190.0 + i * 46.0 + sin(_t * 2.0 + i) * 10.0
		var flap := sin(_t * 9.0 + i) * 8.0
		_ci.draw_polyline(PackedVector2Array([Vector2(gx - 16, gy - flap), Vector2(gx, gy), Vector2(gx + 16, gy - flap)]), INK, 3.0, true)
	var bob := sin(_t * 1.1) * 5.0
	var wood := Color("a8743e")
	# Mast, sail and rigging.
	var mx := _x(950, 0.92)
	_line(mx, 20 + bob, mx - 420, GROUND_TOP - 30 + bob, Color("4a3424"), 3.0)
	_line(mx, 20 + bob, mx + 420, GROUND_TOP - 30 + bob, Color("4a3424"), 3.0)
	var billow := sin(_t * 1.7) * 10.0
	_poly([-250, 70, 250, 70, 236 + billow, 250, 250, 420, -250, 420, -236 + billow, 250], Color("f4ead0"), mx, bob, 4.0)
	_poly([-240 + billow * 0.5, 180, 240 + billow * 0.5, 180, 238 + billow, 240, -238 + billow, 240], Color("2f5fb8"), mx, bob)
	_circle(mx + billow, 330 + bob, 46, Color("e2b93b"))
	_circle(mx + billow, 330 + bob, 30, Color("f4ead0"))
	_rect(mx - 270, 58 + bob, 540, 14, wood.darkened(0.2), 3.0)
	_rect(mx - 13, 10 + bob, 26, GROUND_TOP - 10, wood.darkened(0.1), 4.0)
	# Rail with the crew's shields.
	_rect(0, GROUND_TOP - 62 + bob, 1280, 16, wood, 3.0)
	var rx := -fposmod(_cam, 120.0)
	var n := int(floorf(_cam / 120.0))
	while rx < 1300.0:
		_rect(rx + 52, GROUND_TOP - 48 + bob, 14, 52, wood.darkened(0.15), 3.0)
		var hue: Color = [Color("a8201e"), Color("2f5fb8"), Color("e2b93b"), Color("2f7a4f")][posmod(n, 4)]
		_circle(rx, GROUND_TOP - 30 + bob, 31, INK)
		_circle(rx, GROUND_TOP - 30 + bob, 27, Color("c9973a"))
		_circle(rx, GROUND_TOP - 30 + bob, 20, hue)
		_circle(rx, GROUND_TOP - 30 + bob, 6, Color("c9973a"))
		rx += 120.0
		n += 1
	# Prow.
	var px := _x(1840, 1.0)
	_poly([-60, 20, -30, -150, 10, -260, 60, -290, 96, -250, 60, -236, 40, -150, 40, 20], wood.darkened(0.1), px, GROUND_TOP + bob, 4.0)
	_circle(px + 58, GROUND_TOP - 262 + bob, 7, Color.WHITE)
	_circle(px + 60, GROUND_TOP - 262 + bob, 3.5, INK)
	_floor(Color("c08a4c"), Color("6a4424"), Color("7e5630"), 90.0)


static func _acropolis() -> void:
	_grad(Rect2(0, 0, 1280, 720), Color("3f93e0"), Color("d8efff"))
	_circle(_x(260, 0.03), 110, 56, Color("fffbe0"))
	for i in 5:
		_cloud(fposmod(i * 380.0 + _t * 5.0 - _cam * 0.08, 1800.0) - 200.0, 110.0 + _h(i + 6.0) * 120.0, 1.3, Color(1, 1, 1, 0.92))
	_ridge(0.12, 500, 50, 0.004, Color("9db8cf"), 3.0)
	_ridge(0.22, 540, 36, 0.007, Color("8aa67c"), 4.0)
	# The city below.
	for i in 26:
		var hx := _x(i * 96.0 + _h(i + 1.0) * 40.0, 0.3)
		var hh := 26.0 + _h(i + 8.0) * 34.0
		_rect(hx, 566 - hh, 60, hh + 30, Color("f1e4c8"))
		_poly([-6, 0, 30, -18, 66, 0], Color("c8643a"), hx, 566 - hh)
	_temple(760, 590, 8, 78, 230, Color("f6efe0"), 0.5)
	# Athena's statue.
	var sx := _x(1500, 0.7)
	var bronze := Color("7a9a7a")
	_rect(sx - 70, 500, 140, 90, Color("e8dfca"), 4.0)
	_poly([-40, 500, -30, 330, -44, 300, -20, 250, 20, 250, 44, 300, 30, 330, 40, 500], bronze, sx, 0, 4.0)
	_circle(sx, 226, 30, INK)
	_circle(sx, 226, 26, bronze)
	_poly([-30, 222, -6, 176, 30, 190, 34, 222], bronze.darkened(0.15), sx, 0, 3.0)
	_poly([-10, 180, 4, 130, 34, 150, 26, 188], Color("b8c8a8"), sx, 0, 3.0)
	_line(sx + 66, 500, sx + 66, 130, bronze.darkened(0.2), 6.0)
	_poly([58, 132, 66, 92, 74, 132], bronze, sx, 0, 3.0)
	_line(sx + 30, 320, sx + 66, 300, bronze, 12.0)
	_circle(sx - 52, 400, 50, INK)
	_circle(sx - 52, 400, 46, bronze.lightened(0.1))
	_circle(sx - 52, 400, 14, bronze.darkened(0.2))
	# Olive trees.
	for wx in [240.0, 1120.0, 1860.0]:
		var tx := _x(wx, 0.85)
		_poly([-12, 0, -8, -90, -30, -130, 0, -110, 26, -140, 10, -86, 14, 0], Color("6a5038"), tx, GROUND_TOP, 3.0)
		for c in [[-40, -150, 44], [16, -176, 50], [52, -136, 38], [-6, -128, 40]]:
			_circle(tx + c[0], GROUND_TOP + c[1], c[2] + 2, INK)
		for c in [[-40, -150, 44], [16, -176, 50], [52, -136, 38], [-6, -128, 40]]:
			_circle(tx + c[0], GROUND_TOP + c[1], c[2] - 1, Color("7a9a5a"))
		_circle(tx + 6, GROUND_TOP - 186, 26, Color("93b26e"))
	_floor(Color("f4ecda"), Color("b8aa8c"), Color("a0906e"))
	_rect(0, GROUND_TOP, 1280, 6, Color("3a6ad0"))


static func _delphi() -> void:
	_grad(Rect2(0, 0, 1280, 720), Color("2a1a4a"), Color("f08a4a"))
	_stars(40, 240, Color(1, 1, 1, 0.8))
	_circle(_x(900, 0.03), 380, 110, Color(1, 0.8, 0.5, 0.25))
	_circle(_x(900, 0.03), 380, 70, Color("ffd9a0"))
	_ridge(0.1, 470, 150, 0.0035, Color("5a3a6a"), 5.0)
	_ridge(0.2, 530, 100, 0.005, Color("3f2a52"), 6.0)
	_ridge(0.35, 580, 50, 0.008, Color("2a1e3a"), 7.0)
	# Cypresses.
	for i in 12:
		var cx := _x(i * 210.0 + _h(i + 3.0) * 90.0, 0.5)
		var ch := 150.0 + _h(i + 13.0) * 110.0
		_poly([-22, 0, -16, -ch * 0.6, 0, -ch, 16, -ch * 0.6, 22, 0], Color("1c2a26"), cx, 596)
	# The round temple: three columns still standing.
	var tx := _x(1150, 0.6)
	var marble := Color("e8d8c0")
	_poly([-230, 0, -210, -26, 210, -26, 230, 0], marble.darkened(0.1), tx, 596, 4.0)
	_poly([-200, -26, -186, -46, 186, -46, 200, -26], marble, tx, 596, 4.0)
	for k in [-130.0, -40.0, 60.0]:
		_column(tx + k, 250, 550, 44, marble)
	_poly([-176, 250, -176, 214, 100, 214, 112, 232, 96, 250], marble, tx, -14, 4.0)
	for k in [150.0, 200.0]:
		_rect(tx + k - 22, 500 - (k - 150.0) * 0.6, 44, 50 + (k - 150.0) * 0.6, marble.darkened(0.12), 3.0)
	# The oracle's tripod and its vapours.
	var ox := _x(640, 0.8)
	for i in 7:
		var u := fposmod(_t * 0.25 + i / 7.0, 1.0)
		_circle(ox + sin(u * 9.0 + i) * 30.0 * u, 470.0 - u * 300.0, 16.0 + u * 44.0, Color(0.85, 0.75, 1.0, 0.22 * (1.0 - u)))
	_poly([-46, 0, -34, -22, 34, -22, 46, 0], Color("c9973a"), ox, 470, 3.0)
	for k in [-34.0, 0.0, 34.0]:
		_line(ox + k * 0.8, 470, ox + k * 1.3, GROUND_TOP, Color("c9973a"), 6.0)
	_circle(ox, 462, 9, Color("d8b8ff"))
	for i in 14:
		var fx := fposmod(_h(i + 21.0) * 1500.0 + sin(_t * 0.7 + i) * 60.0 - _cam * 0.9, 1400.0) - 60.0
		var fy := 380.0 + _h(i + 31.0) * 190.0 + sin(_t * 1.3 + i * 2.0) * 14.0
		_circle(fx, fy, 3.0, Color(1, 0.95, 0.6, 0.5 + 0.5 * sin(_t * 3.0 + i)))
	_floor(Color("b89a86"), Color("4a3440"), Color("6c5258"), 160.0)
	for wx in [260.0, 1640.0]:
		_brazier(_x(wx, 1.0), GROUND_TOP + 6, wx, Color("f0e0ff"), Color("b86ae0"))


static func _cyclops() -> void:
	_grad(Rect2(0, 0, 1280, 720), Color("120c0a"), Color("4a2c1c"))
	# The cave mouth: night sea outside.
	var mx := _x(520, 0.3)
	_poly([-250, 600, -280, 380, -200, 220, -60, 150, 110, 170, 230, 280, 270, 440, 250, 600], Color("1a2f5c"), mx)
	_circle(mx + 60, 260, 40, Color("f6eed0"))
	_rect(mx - 270, 470, 540, 130, Color("143060"))
	for row in 3:
		_line(mx - 200, 490 + row * 26, mx + 200, 490 + row * 26, Color(1, 1, 1, 0.18), 3.0)
	_poly([-250, 600, -280, 380, -200, 220, -60, 150, 110, 170, 230, 280, 270, 440, 250, 600, 400, 600, 400, 60, -400, 60, -400, 600],
		Color("2a1a12"), mx)
	_rect(0, 0, 1280, 70, Color("2a1a12"))
	_rect(mx + 399, 60, 1400, 540, Color("2a1a12"))
	_rect(mx - 1800, 60, 1401, 540, Color("2a1a12"))
	# Polyphemus, minding his own business.
	var cx := _x(1420, 0.5)
	var hide := Color("3c2a22")
	_poly([-230, 600, -250, 420, -190, 300, -80, 250, 80, 250, 190, 300, 250, 420, 230, 600], hide, cx, 0, 5.0)
	_circle(cx, 220, 116, INK)
	_circle(cx, 220, 110, hide.lightened(0.06))
	var look := clampf((640.0 - cx) / 600.0, -1.0, 1.0)
	var blink := 0.12 if fposmod(_t, 5.0) < 0.18 else 1.0
	_ci.draw_set_transform_matrix(_xf * Transform2D(0.0, Vector2(1.0, blink), 0.0, Vector2(cx, 206)))
	_circle(0, 0, 52, INK)
	_circle(0, 0, 46, Color("fff2c0"))
	_circle(look * 18.0, 4, 24, Color("d8762a"))
	_circle(look * 20.0, 4, 11, INK)
	_ci.draw_set_transform_matrix(_xf)
	_circle(cx, 206, 120, Color(1, 0.8, 0.4, 0.05))
	_line(cx - 60, 150, cx + 60, 142, INK, 12.0)
	_poly([-50, 286, 0, 300, 50, 286, 30, 304, -30, 304], INK, cx, 0)
	for k in [-22.0, 22.0]:
		_poly([-8, 0, 0, -18, 8, 0], Color("f0e8d0"), cx + k, 304, 2.0)
	# The flock.
	for i in 5:
		var sx := _x(360.0 + i * 300.0 + sin(_t * 0.5 + i * 2.0) * 30.0, 0.8)
		var sy := 560.0 + _h(i + 2.0) * 16.0
		for lg in [-22.0, -8.0, 10.0, 24.0]:
			_line(sx + lg, sy + 10, sx + lg, sy + 38, INK, 6.0)
		for c in [[-26, 0, 22], [0, -10, 26], [26, 0, 22], [0, 10, 24], [-14, 8, 20], [14, 8, 20]]:
			_circle(sx + c[0], sy + c[1], c[2] + 3, INK)
		for c in [[-26, 0, 22], [0, -10, 26], [26, 0, 22], [0, 10, 24], [-14, 8, 20], [14, 8, 20]]:
			_circle(sx + c[0], sy + c[1], c[2], Color("f2ecdc"))
		var hd := 1.0 if i % 2 == 0 else -1.0
		_circle(sx + 44 * hd, sy - 6, 15, INK)
		_circle(sx + 44 * hd, sy - 6, 12, Color("3a2e2a"))
		_circle(sx + 48 * hd, sy - 9, 2.5, Color.WHITE)
	_floor(Color("6a4a32"), Color("241610"), Color("46301f"), 180.0)
	# Fire pit.
	var fx := _x(1040, 1.0)
	_circle(fx, GROUND_TOP - 30, 190, Color(1, 0.6, 0.2, 0.08))
	_flame(fx, GROUND_TOP + 8, 1.5, 3.0)
	for k in [-52.0, -26.0, 0.0, 26.0, 52.0]:
		_circle(fx + k, GROUND_TOP + 12, 17, INK)
		_circle(fx + k, GROUND_TOP + 12, 14, Color("5a5052"))
	for i in 10:
		var tx := _x(i * 230.0 + _h(i + 4.0) * 90.0, 1.0)
		_poly([-40, 0, 0, 60 + _h(i + 17.0) * 90.0, 40, 0], Color("1c120e"), tx, 0, 3.0)
