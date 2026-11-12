extends Node2D

# Draws the app icon (Heracles in his lion hood) in the top-left 512x512 of the
# window. tools/make_icon.sh renders it and crops it to icon.png.

func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("17121c"))
	draw_rect(Rect2(16, 16, 480, 480), UI.RED)
	UI.halftone(self, Rect2(16, 16, 480, 480), Color(0, 0, 0, 0.18), 30.0)
	var look: Dictionary = Looks.L["heracles"]
	var pose: Dictionary = Poses.pose("stand").duplicate()
	pose["mouth"] = 3
	var s := 3.4
	Rig.draw(self, Transform2D(0.0, Vector2(s, s), 0.0, Vector2(256, 256) - Vector2(16.0, -258.0) * s + Vector2(-10, -40)), look, pose, {"time": 0.5})
	draw_rect(Rect2(16, 16, 480, 480), UI.INK, false, 14.0)
	var w := UI.width("GF", 120)
	UI.text(self, Vector2(470 - w, 470), "GF", 120, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
