extends Node2D

# Art-check: every projectile kind and effect on one sheet.

const KINDS := ["bolt", "spear", "arrow", "moonbeam", "megarrow", "soul", "caduceus", "axe", "apple", "boulder",
	"venom", "wave", "bigwave", "horse", "argo", "skybolt", "megabolt", "pillar", "hands", "spartoi", "orb"]


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("3a4468"))
	var t := 1.37
	for i in KINDS.size():
		var pos := Vector2(100.0 + (i % 7) * 175.0, 190.0 + (i / 7) * 215.0)
		var h := 240.0 if KINDS[i] == "bigwave" else 112.0
		var p := {"kind": KINDS[i], "dir": 1, "age": 12, "delay": 0, "vx": 10.0, "vy": 3.0, "w": 110.0, "h": h}
		Fx.projectile(self, p, pos, 190.0, t)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-40, 20), KINDS[i])
	var kinds := ["spark", "block", "dust", "ring", "word"]
	for i in kinds.size():
		Fx.effect(self, {"kind": kinds[i], "x": 760.0 + i * 110.0, "y": 640.0, "t": 5, "life": 14, "rot": 0.2,
			"col": Color("ff9a2e"), "size": 1.0, "word": "POW!"})
