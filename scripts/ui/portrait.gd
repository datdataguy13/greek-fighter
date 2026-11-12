class_name Portrait
extends Control

# A clipped head-and-shoulders view of a fighter, drawn with the same Rig as
# the in-game character so it stays crisp at any size.

var look := {}
var bg := Color("2a3350")
var flip := false
var zoom := 2.2
var mouth := 0
var dim := false
var border := Color("17121c")
var border_w := 4.0


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_look(p_look: Dictionary) -> void:
	look = p_look
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), bg)
	UI.halftone(self, Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.10), 16.0)
	if not look.is_empty():
		var pose: Dictionary = Poses.pose("stand").duplicate()
		pose["mouth"] = mouth
		var s: float = zoom * look.get("scale", 1.0)
		var sign := -1.0 if flip else 1.0
		var head := Vector2(16.0 * sign, -258.0) * s
		var anchor := Vector2(size.x * 0.5, size.y * 0.5) - head
		var opts := {"time": 0.5}
		if dim:
			opts["flash"] = 0.6
			opts["flash_col"] = Color("30303a")
		Rig.draw(self, Transform2D(0.0, Vector2(s * sign, s), 0.0, anchor), look, pose, opts)
	draw_rect(Rect2(Vector2.ZERO, size), border, false, border_w)
