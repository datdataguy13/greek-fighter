extends SceneTree

# Rules tests for the fight simulation. Run from the project folder:
#   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tests/test_sim.gd

const St := FighterSim.St
const L := Inp.LEFT
const R := Inp.RIGHT
const U := Inp.UP
const D := Inp.DOWN

var failures := 0


func _initialize() -> void:
	_movement()
	_hits_and_blocks()
	_combos()
	_specials_and_motions()
	_throws()
	_projectiles()
	_rounds()
	_roster_sanity()
	print("")
	print("All sim tests passed." if failures == 0 else "%d sim test(s) failed." % failures)
	quit(1 if failures > 0 else 0)


# --- helpers ---------------------------------------------------------------

func _sim(a := "achilles", b := "jason", gap := 380.0) -> FightSim:
	var s := FightSim.new(Roster.get_def(a), Roster.get_def(b))
	for i in FightSim.INTRO_FRAMES:
		s.step(0, 0)
	s.f[0].x = 900.0
	s.f[1].x = 900.0 + gap
	return s


func _run(s: FightSim, frames: int, in0 := 0, in1 := 0) -> void:
	for i in frames:
		s.step(in0, in1)


# Plays a list of [input, frames] for player 1 (player 2 holds `in1`).
func _play(s: FightSim, script: Array, in1 := 0) -> void:
	for part in script:
		_run(s, part[1], part[0], in1)


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("  ok    ", description)
	else:
		failures += 1
		printerr("  FAIL  ", description)


# --- tests -----------------------------------------------------------------

func _movement() -> void:
	var s := _sim()
	_expect(s.phase == FightSim.Phase.FIGHT, "fight starts after the intro")
	var x0 := s.f[0].x
	_run(s, 30, R)
	_expect(is_equal_approx(s.f[0].x, x0 + 30 * 4.3), "holding forward walks at walk speed")
	_run(s, 30, L)
	_expect(s.f[0].x < x0 + 30 * 4.3 and s.f[0].x > x0, "walking back is slower than walking forward")

	s = _sim()
	_run(s, 8, U)
	_expect(s.f[0].y < 0.0 and s.f[0].st == St.JUMP, "holding up jumps")
	_run(s, 60)
	_expect(s.f[0].y == 0.0 and s.f[0].st == St.IDLE, "jump lands back in idle")

	s = _sim()
	_play(s, [[R, 3], [0, 3], [R, 2]])
	_expect(s.f[0].st == St.DASH, "double-tap forward dashes")
	s = _sim()
	_play(s, [[L, 3], [0, 3], [L, 2]])
	_expect(s.f[0].st == St.BACKDASH, "double-tap back backdashes")

	s = _sim("achilles", "jason", 40.0)
	_run(s, 5)
	_expect(absf(s.f[1].x - s.f[0].x) >= 34.0 * (s.f[0].sz + s.f[1].sz) - 0.5, "overlapping bodies are pushed apart")

	s = _sim()
	_run(s, 400, L)
	_expect(s.f[0].x >= FightSim.WALL, "fighters stop at the stage wall")
	_expect(absf(s.f[1].x - s.f[0].x) <= FightSim.MAX_SEP + 0.5, "fighters cannot leave the shared screen")


func _hits_and_blocks() -> void:
	var s := _sim("achilles", "jason", 120.0)
	_play(s, [[Inp.P, 1], [0, 8]])
	_expect(s.f[1].hp == s.f[1].max_hp - 28, "a jab in range does its damage")
	_expect(s.f[1].st == St.HITSTUN, "the target is put in hitstun")

	s = _sim("achilles", "jason", 400.0)
	_play(s, [[Inp.P, 1], [0, 12]])
	_expect(s.f[1].hp == s.f[1].max_hp, "a jab out of range whiffs")

	# Player 2 faces left, so "back" for them is RIGHT.
	s = _sim("achilles", "jason", 120.0)
	_play(s, [[Inp.P, 1], [0, 6]], R)
	_expect(s.f[1].hp == s.f[1].max_hp and s.f[1].st == St.BLOCKSTUN, "holding back blocks a jab")

	s = _sim("achilles", "jason", 120.0)
	_play(s, [[D | Inp.K, 1], [D, 9]], R)
	_expect(s.f[1].hp < s.f[1].max_hp, "a low kick beats a standing block")
	s = _sim("achilles", "jason", 120.0)
	_play(s, [[D | Inp.K, 1], [D, 9]], R | D)
	_expect(s.f[1].hp == s.f[1].max_hp, "a low kick is stopped by a crouching block")

	s = _sim("achilles", "jason", 120.0)
	s.f[0].st = St.JUMP
	s.f[0].y = -150.0
	s.f[0].vy = 4.0
	_play(s, [[Inp.K, 1], [0, 12]], R | D)
	_expect(s.f[1].hp < s.f[1].max_hp, "a jump attack beats a crouching block")
	s = _sim("achilles", "jason", 120.0)
	s.f[0].st = St.JUMP
	s.f[0].y = -150.0
	s.f[0].vy = 4.0
	_play(s, [[Inp.K, 1], [0, 12]], R)
	_expect(s.f[1].hp == s.f[1].max_hp, "a jump attack is stopped by a standing block")

	s = _sim("jason", "achilles", 120.0)
	_play(s, [[D | Inp.K, 1], [D, 9]])
	_expect(s.f[1].max_hp - s.f[1].hp == int(round(44 * 1.15)), "low attacks hurt Achilles more (the heel)")

	s = _sim("achilles", "jason", 120.0)
	s.f[1].x = FightSim.STAGE_W - FightSim.WALL
	s.f[0].x = s.f[1].x - 120.0
	var before := s.f[0].x
	_play(s, [[Inp.P, 1], [0, 14]])
	_expect(s.f[0].x < before, "hitting a cornered opponent pushes the attacker back")

	s = _sim()
	s.f[1].st = St.LAUNCH
	s.f[1].y = -100.0
	s.f[1].juggle = FighterSim.MAX_JUGGLE
	_expect(not s.f[1].hittable(false), "a juggled fighter can only be hit so many times")
	s.f[1].st = St.DOWN
	_expect(not s.f[1].hittable(false), "a knocked-down fighter cannot be hit")


func _combos() -> void:
	var s := _sim("achilles", "jason", 112.0)
	var best := 0
	for part in [[Inp.P, 1], [0, 4], [Inp.K, 1], [0, 12], [Inp.H, 1], [0, 30]]:
		for i in part[1]:
			s.step(part[0], 0)
			best = maxi(best, s.f[1].combo)
	_expect(best == 3, "punch, kick, heavy chains into a 3-hit combo (got %d)" % best)
	_expect(s.f[1].max_hp - s.f[1].hp == 28 + 52 + int(round(78 * 0.85)), "the third hit of a combo is scaled down")

	s = _sim("achilles", "jason", 112.0)
	_play(s, [[Inp.K, 1], [0, 3], [Inp.P, 1], [0, 30]])
	_expect(s.f[1].max_hp - s.f[1].hp == 52, "a kick cannot chain back down into a punch")

	s = _sim("achilles", "jason", 112.0)
	var hits := 0
	for part in [[Inp.K, 1], [0, 6], [Inp.S, 1], [0, 60]]:
		for i in part[1]:
			s.step(part[0], 0)
			hits = maxi(hits, s.f[1].combo)
	_expect(hits == 2, "a kick cancels into a special for a 2-hit combo (got %d)" % hits)


func _specials_and_motions() -> void:
	var s := _sim()
	_play(s, [[Inp.S, 1], [0, 2]])
	_expect(s.f[0].move_key == "sn", "Special alone does the neutral special")
	s = _sim()
	_play(s, [[R | Inp.S, 1], [R, 2]])
	_expect(s.f[0].move_key == "sf", "forward + Special does the forward special")
	s = _sim()
	_play(s, [[D | Inp.S, 1], [D, 2]])
	_expect(s.f[0].move_key == "sd", "down + Special does the down special")

	s = _sim()
	_play(s, [[D, 3], [D | R, 3], [R, 2], [R | Inp.P, 1], [R, 1]])
	_expect(s.f[0].move_key == "sn", "quarter-circle forward + Punch does the neutral special")
	s = _sim()
	_play(s, [[R, 3], [D, 3], [D | R, 2], [D | R | Inp.P, 1], [0, 1]])
	_expect(s.f[0].move_key == "sf", "forward, down, down-forward + Punch does the forward special")
	s = _sim()
	_play(s, [[D, 3], [D | L, 3], [L, 2], [L | Inp.K, 1], [0, 1]])
	_expect(s.f[0].move_key == "sd", "quarter-circle back + Kick does the down special")
	s = _sim()
	_play(s, [[R, 10], [R | Inp.P, 1], [0, 1]])
	_expect(s.f[0].move_key == "5P", "walking forward and punching is just a punch")

	s = _sim()
	_play(s, [[D, 3], [0, 3], [D, 2], [D | Inp.S, 1], [D, 1]])
	_expect(s.f[0].move_key == "sd", "down, down + Special without meter is the down special")
	s = _sim()
	s.f[0].meter = 100.0
	_play(s, [[D, 3], [0, 3], [D, 2], [D | Inp.S, 1], [D, 1]])
	_expect(s.f[0].move_key == "super" and s.f[0].meter == 0.0, "down, down + Special with full meter does the super")
	_expect(s.superfreeze > 0, "a super freezes the action")

	s = _sim("achilles", "jason", 120.0)
	_play(s, [[R | Inp.S, 1], [0, 3]], 0)
	_run(s, 1, 0, Inp.P)
	_run(s, 20)
	_expect(s.f[0].hp == s.f[0].max_hp and s.f[1].hp < s.f[1].max_hp, "an uppercut's invulnerable startup beats a jab")

	s = _sim("hades", "jason", 300.0)
	_play(s, [[R | Inp.S, 1], [0, 30]])
	_expect(s.f[0].x > s.f[1].x and s.f[0].facing == -1, "Hades teleports behind the opponent and turns around")

	s = _sim("hermes", "jason", 300.0)
	s.f[0].st = St.JUMP
	s.f[0].y = -200.0
	_play(s, [[Inp.S, 1], [0, 8]])
	_expect(s.f[0].move_key == "sa" and s.f[0].vy > 0.0, "Hermes dives with Special in the air")


func _throws() -> void:
	var s := _sim("achilles", "jason", 80.0)
	_play(s, [[R | Inp.H, 1], [R, 2]])
	_expect(s.f[0].st == St.GRAB and s.f[1].st == St.GRABBED, "forward + Heavy up close throws")
	_run(s, 40)
	_expect(s.f[1].hp == s.f[1].max_hp - FighterSim.THROW_DMG, "a throw does its damage")
	_run(s, 120)
	_expect(s.f[1].st == St.IDLE, "the thrown fighter gets back up")

	s = _sim("achilles", "jason", 80.0)
	_play(s, [[R | Inp.H, 1], [R, 2]], R)
	_expect(s.f[1].st == St.GRABBED, "throws beat blocking")

	s = _sim("achilles", "jason", 300.0)
	_play(s, [[R | Inp.H, 1], [R, 2]])
	_expect(s.f[0].st == St.ATTACK and s.f[0].move_key == "5H", "forward + Heavy out of range is a normal heavy")

	s = _sim("heracles", "jason", 150.0)
	_play(s, [[D | Inp.S, 1], [D, 10]])
	_expect(s.f[1].st == St.GRABBED, "Heracles' command grab reaches further than a throw")


func _projectiles() -> void:
	var s := _sim("achilles", "jason", 500.0)
	_play(s, [[Inp.S, 1], [0, 15]])
	_expect(s.projs.size() == 1, "a projectile special spawns a projectile")
	_run(s, 1, Inp.S)
	_run(s, 30)
	_expect(s.projs.size() <= 1, "only one projectile per fighter at a time")
	_run(s, 60)
	_expect(s.f[1].hp == s.f[1].max_hp - 56, "the projectile hits for its damage")

	s = _sim("achilles", "jason", 500.0)
	_play(s, [[Inp.S, 1], [0, 80]], R)
	_expect(s.f[1].hp == s.f[1].max_hp - 8, "a blocked projectile does chip damage")

	s = _sim("achilles", "athena", 600.0)
	_run(s, 1, Inp.S, Inp.S)
	_run(s, 100)
	_expect(s.projs.is_empty() and s.f[0].hp == s.f[0].max_hp and s.f[1].hp == s.f[1].max_hp, "opposing projectiles cancel out")

	s = _sim("zeus", "jason", 500.0)
	_play(s, [[R | Inp.S, 1], [0, 50]])
	_expect(s.f[1].hp < s.f[1].max_hp, "Zeus' sky bolt strikes where the opponent stands")
	s = _sim("zeus", "jason", 500.0)
	_play(s, [[R | Inp.S, 1], [0, 50]], R)
	_expect(s.f[1].hp >= s.f[1].max_hp - 8, "walking away (or blocking) avoids the sky bolt")


func _rounds() -> void:
	var s := _sim("achilles", "jason", 120.0)
	s.f[1].hp = 10
	_play(s, [[Inp.P, 1], [0, 10]])
	_expect(s.phase == FightSim.Phase.KO and s.round_winner == 0 and s.f[0].wins == 1, "reducing hp to zero wins the round")
	_run(s, FightSim.KO_FRAMES + 5)
	_expect(s.round_no == 2 and s.f[1].hp == s.f[1].max_hp and s.phase == FightSim.Phase.INTRO, "a new round resets both fighters")
	_run(s, FightSim.INTRO_FRAMES)
	s.f[0].x = 900.0
	s.f[1].x = 1020.0
	s.f[1].hp = 10
	_play(s, [[Inp.P, 1], [0, 10]])
	_run(s, FightSim.KO_FRAMES + 5)
	_expect(s.phase == FightSim.Phase.OVER and s.match_winner == 0, "two round wins take the match")

	s = _sim()
	s.f[0].hp = 500
	s.timer = 2
	_run(s, 5)
	_expect(s.phase == FightSim.Phase.KO and s.round_winner == 1 and s.end_how == "time", "on time-out the healthier fighter wins")

	s = _sim()
	s.timer = 2
	_run(s, 5)
	_expect(s.round_winner == -1 and s.f[0].wins == 1 and s.f[1].wins == 1, "an even time-out is a draw")


# Every fighter's every move should run start to finish without errors.
func _roster_sanity() -> void:
	_expect(Roster.all().size() >= 12, "at least 12 fighters on the roster (%d)" % Roster.all().size())
	var bad := []
	for def in Roster.all():
		var keys: Array = ["sn", "sf", "sd"]
		for key in keys:
			if not def["specials"].has(key):
				bad.append("%s lacks %s" % [def["id"], key])
		var moves: Array = def["normals"].values() + def["specials"].values() + [def["super"]]
		for m in moves:
			if not Poses.ANIMS.has(m["anim"]):
				bad.append("%s: unknown anim %s" % [def["id"], m["anim"]])
			for gap in [130.0, 420.0]:
				var s := _sim(def["id"], "jason", gap)
				if m["air"] == 1:
					s.f[0].st = St.JUMP
					s.f[0].y = -220.0
				s.f[0].start(m, "test")
				_run(s, 260)
				if s.f[0].st != St.IDLE or s.f[0].y != 0.0:
					bad.append("%s: %s never returned to idle" % [def["id"], m["name"]])
	_expect(bad.is_empty(), "every move of every fighter plays out cleanly %s" % str(bad))
	var supers_ok := true
	for def in Roster.all():
		var s := _sim(def["id"], "jason", 150.0)
		s.f[0].start(def["super"], "super")
		_run(s, 300)
		if s.f[1].hp >= s.f[1].max_hp:
			supers_ok = false
			printerr("        super missed at close range: ", def["id"])
	_expect(supers_ok, "every super connects at close range")
