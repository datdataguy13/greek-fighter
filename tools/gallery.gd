extends Node2D

# Art-check sheet: draws fighters in chosen poses on a flat background.
# GALLERY env var: "roster" (everyone idle), "poses:<id>:<a,b,c>" (named poses),
# or "heads" (big portraits).

var mode := "roster"


func _ready() -> void:
	mode = OS.get_environment("GALLERY") if OS.has_environment("GALLERY") else "roster"
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("6f86a8"))
	var parts := mode.split(":")
	match parts[0]:
		"roster":
			var i := 0
			for id in Looks.ORDER:
				var x := 95.0 + (i % 7) * 182.0
				var y := 330.0 + (i / 7) * 350.0
				_figure(id, Poses.pose("stand"), Vector2(x, y), 1.0, 1)
				i += 1
		"poses":
			var names := parts[2].split(",")
			var n := names.size()
			var cols := mini(n, 6)
			for k in n:
				var x2 := 110.0 + (k % cols) * (1100.0 / maxf(1.0, cols - 1)) * (1.0 if cols > 1 else 0.0)
				var y2 := 330.0 + (k / cols) * 350.0
				_figure(parts[1], Poses.pose(names[k]), Vector2(x2, y2), 1.0, 1)
				draw_string(ThemeDB.fallback_font, Vector2(x2 - 50, y2 + 24), names[k])
		"heads":
			var i2 := 0
			for id in Looks.ORDER:
				var x3 := 100.0 + (i2 % 7) * 180.0
				var y3 := 560.0 + (i2 / 7) * 340.0
				var look: Dictionary = Looks.L[id]
				var xf := Transform2D(0.0, Vector2(2.3, 2.3), 0.0, Vector2(x3 - 20, y3 + 250))
				Rig.draw(self, xf, look, Poses.pose("stand"), {"time": 0.4})
				i2 += 1


func _figure(id: String, pose: Dictionary, pos: Vector2, scale_mul: float, facing: int) -> void:
	var look: Dictionary = Looks.L[id]
	var s: float = look.get("scale", 1.0) * scale_mul
	draw_line(pos + Vector2(-70, 0), pos + Vector2(70, 0), Color(0, 0, 0, 0.3), 1.0)
	Rig.draw_shadow(self, pos, 0.0, s)
	Rig.draw(self, Transform2D(0.0, Vector2(s * facing, s), 0.0, pos), look, pose, {"time": 0.4})
