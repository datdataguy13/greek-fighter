class_name FighterView
extends RefCounted

# Turns a FighterSim's state into a pose and draws it with the Rig. Keeps the
# little bits of presentation state the sim doesn't care about (pose
# smoothing, hit flash).

const St := FighterSim.St

var shown := {}
var flash := 0.0
var last_st := -1
var _alt_looks := {}


func hit_flash() -> void:
	flash = 1.0


# Call once per sim tick.
func update(f: FighterSim, sim: FightSim, time: float) -> void:
	var target := pose_for(f, sim, time)
	var snap: bool = shown.is_empty() or (f.st != last_st and f.st in [St.HITSTUN, St.LAUNCH, St.BLOCKSTUN, St.GRABBED])
	if snap:
		shown = target
	else:
		shown = Poses.blend(shown, target, 0.75 if f.st == St.ATTACK else 0.55)
	last_st = f.st
	flash = maxf(0.0, flash - 0.14)


func pose_for(f: FighterSim, sim: FightSim, time: float) -> Dictionary:
	match f.st:
		St.IDLE:
			if sim.phase == FightSim.Phase.KO and sim.end_how == "time" and sim.round_winner == 1 - f.idx:
				return Poses.pose("lose")
			if f.crouch:
				return Poses.pose("crouch")
			if absf(f.vx) > 0.1:
				return Poses.walk(f.walk_phase)
			return Poses.idle(time + f.idx * 0.4)
		St.PREJUMP:
			return Poses.pose("prejump")
		St.JUMP:
			return Poses.jump(f.vy)
		St.LAND:
			return Poses.blend(Poses.pose("prejump"), Poses.pose("stand"), float(f.t) / maxf(1.0, f.land_frames))
		St.DASH:
			return Poses.pose("dash_f")
		St.BACKDASH:
			return Poses.pose("dash_b")
		St.ATTACK:
			var m := f.move
			var base: Dictionary
			if f.y < 0.0 or m["air"] == 1:
				base = Poses.jump(f.vy)
			elif f.move_key.begins_with("2"):
				base = Poses.pose("crouch")
			else:
				base = Poses.pose("stand")
			return Poses.attack(m["anim"], f.t, m["startup"], m["active"], m["recovery"], base)
		St.HITSTUN:
			var reel := Poses.pose("hit_crouch" if f.crouch else ("hit_low" if f.hit_low else "hit_high"))
			var left := f.stun - f.t
			if left < 5:
				return Poses.blend(Poses.pose("crouch" if f.crouch else "stand"), reel, left / 5.0)
			return reel
		St.BLOCKSTUN:
			return Poses.pose("block_crouch" if f.crouch else "block")
		St.LAUNCH:
			var p: Dictionary = Poses.pose("air_hit").duplicate()
			p["rot"] = -20.0 if f.soft else clampf(-25.0 - f.t * 5.0, -95.0, 0.0)
			return p
		St.DOWN, St.KO:
			return Poses.pose("down")
		St.GETUP:
			return Poses.blend(Poses.pose("down"), Poses.pose("crouch"), float(f.t) / FighterSim.GETUP_FRAMES)
		St.GRAB:
			if f.t < FighterSim.GRAB_RELEASE:
				return Poses.blend(Poses.pose("grab_h"), Poses.pose("throw_lift"), float(f.t) / FighterSim.GRAB_RELEASE)
			return Poses.pose("throw_toss")
		St.GRABBED:
			var g: Dictionary = Poses.pose("grabbed").duplicate()
			g["rot"] = -25.0
			return g
		St.WIN:
			# A fist pump (or weapon pump) for the winner.
			var win: Dictionary = Poses.pose("win").duplicate()
			win["hf"] = win["hf"] + Vector2(0, sin(time * 7.0) * 9.0)
			return win
	return Poses.pose("stand")


func draw(ci: CanvasItem, f: FighterSim, feet: Vector2, floor_y: float, time: float) -> void:
	if shown.is_empty():
		return
	var look: Dictionary = f.def["look"]
	var facing := f.facing
	var opts := {"time": time, "vel": Vector2(f.vx * f.facing, f.vy)}
	if f.st == St.ATTACK:
		var m := f.move
		if m.has("weapon"):
			look = _alt_look(look, m["weapon"])
		if m["anim"] == "spin" and f.t > m["startup"] and f.t <= m["startup"] + m["active"] and (f.t / 4) % 2 == 1:
			facing = -facing
		if m.has("teleport"):
			opts["alpha"] = clampf(absf(f.t - m["teleport"]["frame"]) / 6.0, 0.08, 1.0)
		if m["super"]:
			opts["flash"] = 0.25 + 0.2 * sin(time * 30.0)
			opts["flash_col"] = Color("ffe27a")
	if f.petrified:
		opts["flash"] = 0.7
		opts["flash_col"] = Color("9a9a9a")
	if flash > 0.0:
		opts["flash"] = flash
		opts["flash_col"] = Color.WHITE
	Rig.draw_shadow(ci, Vector2(feet.x, floor_y), -f.y, f.sz)
	Rig.draw(ci, Transform2D(0.0, Vector2(f.sz * facing, f.sz), 0.0, feet), look, shown, opts)


func _alt_look(look: Dictionary, weapon: String) -> Dictionary:
	if not _alt_looks.has(weapon):
		var alt := look.duplicate()
		alt["weapon"] = weapon
		_alt_looks[weapon] = alt
	return _alt_looks[weapon]
