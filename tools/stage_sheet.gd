extends Node2D

# Art-check: STAGE=<id> draws one stage full size (CAM=<x> optional);
# without it, all stages are drawn as a contact sheet.

func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0 + 3.0
	if OS.has_environment("STAGE"):
		var cam := float(OS.get_environment("CAM")) if OS.has_environment("CAM") else 310.0
		StageArt.draw(self, OS.get_environment("STAGE"), cam, t)
		return
	var i := 0
	for st in StageArt.LIST:
		var cell := Vector2((i % 3) * 427.0, (i / 3) * 240.0)
		StageArt.draw(self, st["id"], 310.0, t, Transform2D(0.0, Vector2(0.333, 0.333), 0.0, cell))
		i += 1
