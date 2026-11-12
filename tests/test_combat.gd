extends SceneTree

# Run from the project folder:
#   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tests/test_combat.gd

var failures := 0


func _initialize() -> void:
	# Numpad conversion
	_expect(Combat.numpad(1, 0, 1) == 6, "right while facing right is forward (6)")
	_expect(Combat.numpad(-1, 0, 1) == 4, "left while facing right is back (4)")
	_expect(Combat.numpad(-1, 0, -1) == 6, "left while facing left is forward (6)")
	_expect(Combat.numpad(1, 1, 1) == 3, "down-forward is 3")
	_expect(Combat.numpad(-1, 1, 1) == 1, "down-back is 1")
	_expect(Combat.numpad(0, -1, 1) == 8, "up is 8")
	_expect(Combat.numpad(0, 0, 1) == 5, "neutral is 5")

	# Motion detection
	_expect(Combat.ends_with_motion([2, 3, 6], [2, 3, 6]), "clean quarter circle forward")
	_expect(Combat.ends_with_motion([5, 2, 2, 3, 5, 3, 6, 5], [2, 3, 6]),
			"held directions and neutral frames still match")
	_expect(not Combat.ends_with_motion([6, 3, 2], [2, 3, 6]), "reversed order does not match")
	_expect(not Combat.ends_with_motion([2, 8, 3, 6], [2, 3, 6]), "stray direction breaks the motion")
	_expect(not Combat.ends_with_motion([2, 3, 6, 8], [2, 3, 6]), "motion must be the latest input")
	_expect(Combat.ends_with_motion([2, 1, 4], [2, 1, 4]), "quarter circle back matches")
	_expect(not Combat.ends_with_motion([6], [2, 3, 6]), "too short to match")

	# Hitbox geometry
	_expect(Combat.flip_rect(Rect2(10, 0, 20, 5), 1) == Rect2(10, 0, 20, 5),
			"hitbox is unchanged when facing right")
	_expect(Combat.flip_rect(Rect2(10, 0, 20, 5), -1) == Rect2(-30, 0, 20, 5),
			"hitbox mirrors when facing left")
	var world := Combat.world_hitbox(Vector2(100, 600), Rect2(10, -80, 20, 10), -1)
	_expect(world.position == Vector2(70, 520), "world hitbox mirrors around the fighter's origin")

	print("")
	if failures == 0:
		print("All tests passed.")
	else:
		print("%d test(s) failed." % failures)
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("  ok    ", description)
	else:
		failures += 1
		printerr("  FAIL  ", description)
