extends Node

# Screenshot helper: boots the real game (see the GF_* variables in game.gd).
#   GF_FAST=<n>      run the simulation n times faster (to reach the end of a match)
#   GF_PAUSE_AT=<n>  open the pause menu after n frames

var frames := 0


func _ready() -> void:
	if OS.has_environment("GF_FAST"):
		Engine.physics_ticks_per_second = 60 * int(OS.get_environment("GF_FAST"))
		Engine.max_physics_steps_per_frame = 64
	add_child((load("res://scripts/game.gd") as GDScript).new())


func _process(_delta: float) -> void:
	frames += 1
	if OS.has_environment("GF_PAUSE_AT") and frames == int(OS.get_environment("GF_PAUSE_AT")):
		var fight: Node = get_child(0).get("screen")
		fight.set("paused", true)
