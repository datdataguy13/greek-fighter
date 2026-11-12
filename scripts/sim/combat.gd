class_name Combat
extends RefCounted

# Pure helpers with no scene dependencies, so they can be unit tested.
# Directions use numpad notation, relative to facing:
# 6 = forward, 4 = back, 2 = down, 5 = neutral.


static func numpad(x: int, y: int, facing: int) -> int:
	# x: +1 right, -1 left on screen. y: +1 down, -1 up.
	return 5 + x * facing - 3 * y


# Drops neutral frames and repeated directions held across several frames.
static func compress(history: Array) -> Array:
	var out: Array = []
	for direction in history:
		if direction == 5:
			continue
		if out.is_empty() or out.back() != direction:
			out.append(direction)
	return out


# True if the motion is the most recent input sequence in the history.
static func ends_with_motion(history: Array, motion: Array) -> bool:
	var seq := compress(history)
	if seq.size() < motion.size():
		return false
	return seq.slice(seq.size() - motion.size()) == motion


static func flip_rect(rect: Rect2, facing: int) -> Rect2:
	if facing > 0:
		return rect
	return Rect2(-(rect.position.x + rect.size.x), rect.position.y, rect.size.x, rect.size.y)


static func world_hitbox(origin: Vector2, local: Rect2, facing: int) -> Rect2:
	var flipped := flip_rect(local, facing)
	return Rect2(origin + flipped.position, flipped.size)
