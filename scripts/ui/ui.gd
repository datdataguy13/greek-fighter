class_name UI
extends RefCounted

# Shared comic-book text and panel drawing.

const INK := Color("17121c")
const GOLD := Color("f5c542")
const CREAM := Color("fff3d6")
const RED := Color("e23b2e")
const BLUE := Color("3b7be2")
const P_COL := [Color("e23b2e"), Color("3b7be2")]
const W := 1280.0
const H := 720.0

static var _font: Font


static func font() -> Font:
	if _font == null:
		_font = load("res://assets/fonts/Bangers-Regular.ttf")
	return _font


static func width(s: String, size: int) -> float:
	return font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


# Outlined text with a drop shadow. `pos` is the baseline; with a width the
# text is aligned inside [pos.x, pos.x + width].
static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color = CREAM,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, w: float = -1.0, outline: int = -1) -> void:
	var o := outline if outline >= 0 else maxi(3, size / 6)
	var fnt := font()
	var a := col.a
	if o > 0:
		ci.draw_string_outline(fnt, pos + Vector2(o * 0.35, o * 0.5), s, align, w, size, o, Color(INK, 0.55 * a))
		ci.draw_string_outline(fnt, pos, s, align, w, size, o, Color(INK, a))
	ci.draw_string(fnt, pos, s, align, w, size, col)


static func centered(ci: CanvasItem, y: float, s: String, size: int, col: Color = CREAM) -> void:
	text(ci, Vector2(0, y), s, size, col, HORIZONTAL_ALIGNMENT_CENTER, W)


static func panel(ci: CanvasItem, r: Rect2, fill: Color, border: Color = INK, bw: float = 4.0) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(r, fill)
	ci.draw_rect(r, border, false, bw)


# Halftone dots, the comic-print texture used behind menus.
static func halftone(ci: CanvasItem, r: Rect2, col: Color, step: float = 26.0) -> void:
	var row := 0
	var y := r.position.y
	while y < r.end.y:
		var x := r.position.x + (step * 0.5 if row % 2 == 1 else 0.0)
		var k := (y - r.position.y) / r.size.y
		while x < r.end.x:
			ci.draw_circle(Vector2(x, y), 1.5 + k * 7.0, col)
			x += step
		y += step * 0.82
		row += 1


# Breaks text into lines no wider than `w` at the given font size.
static func wrap(s: String, size: int, w: float) -> PackedStringArray:
	var lines := PackedStringArray()
	var line := ""
	for word in s.split(" ", false):
		var trial := word if line == "" else line + " " + word
		if line != "" and width(trial, size) > w:
			lines.append(line)
			line = word
		else:
			line = trial
	if line != "":
		lines.append(line)
	return lines


# A comic speech bubble holding `lines`, with a tail pointing at `tail`.
# `shown` is how many characters to reveal (for a typewriter effect).
static func bubble(ci: CanvasItem, r: Rect2, tail: Vector2, lines: PackedStringArray, size: int, shown: int = 99999) -> void:
	var base := Vector2(clampf(tail.x, r.position.x + 60.0, r.end.x - 60.0), r.end.y if tail.y > r.end.y else r.position.y)
	var tri := PackedVector2Array([base + Vector2(-22, 0), tail, base + Vector2(22, 0)])
	ci.draw_rect(Rect2(r.position + Vector2(6, 7), r.size), Color(0, 0, 0, 0.35))
	ci.draw_colored_polygon(tri, CREAM)
	ci.draw_polyline(tri, INK, 5.0, true)
	ci.draw_rect(r, CREAM)
	ci.draw_rect(r, INK, false, 5.0)
	ci.draw_line(base + Vector2(-19, 0), base + Vector2(19, 0), CREAM, 7.0)
	var lh := size * 1.18
	var y := r.position.y + (r.size.y - lh * lines.size()) * 0.5 + size * 0.92
	for line in lines:
		var part := line.substr(0, maxi(0, shown))
		shown -= line.length()
		var lw := width(line, size)
		ci.draw_string(font(), Vector2(r.position.x + (r.size.x - lw) * 0.5, y), part, HORIZONTAL_ALIGNMENT_LEFT, -1, size, INK)
		y += lh
