extends SceneTree

# Balance check: the CPU plays itself across every matchup and this prints
# each fighter's overall win rate plus their most lopsided matchups.
#   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/balance.gd
# Env: BALANCE_N = matches per matchup (default 10), BALANCE_LEVEL = CPU level 0..1 (default 1).

func _initialize() -> void:
	var n := int(OS.get_environment("BALANCE_N")) if OS.has_environment("BALANCE_N") else 10
	var level := float(OS.get_environment("BALANCE_LEVEL")) if OS.has_environment("BALANCE_LEVEL") else 1.0
	var defs := Roster.all()
	var wins := {}
	var games := {}
	var pair := {}
	var ticks := 0
	var timeouts := 0
	var dealt := {}  # "fighter: move" -> total damage, to see what each kit leans on
	var rounds := 0
	for d in defs:
		wins[d["id"]] = 0.0
		games[d["id"]] = 0
	var t0 := Time.get_ticks_msec()
	for a in defs.size():
		for b in range(a + 1, defs.size()):
			var score := 0.0
			for g in n:
				# Swap sides every other game so starting side can't matter.
				var left: Dictionary = defs[a] if g % 2 == 0 else defs[b]
				var right: Dictionary = defs[b] if g % 2 == 0 else defs[a]
				var sim := FightSim.new(left, right)
				var cpus := [Cpu.new(a * 1000 + b * 10 + g + 1, level), Cpu.new(b * 1000 + a * 10 + g + 7, level)]
				var last_round := 1
				while sim.phase != FightSim.Phase.OVER and sim.tick < 60 * 60 * 8:
					sim.step(cpus[0].think(sim, 0), cpus[1].think(sim, 1))
					for e in sim.events:
						if e["t"] == "hit":
							var src: String = (right if e["who"] == 0 else left)["id"] + ": " + e["move"]
							dealt[src] = dealt.get(src, 0) + e["dmg"]
						if e["t"] == "ko":
							rounds += 1
							if e["how"] == "time":
								timeouts += 1
				ticks += sim.tick
				var w := sim.match_winner
				var a_won := 0.5 if w < 0 else (1.0 if (w == 0) == (g % 2 == 0) else 0.0)
				score += a_won
				sim.dispose()
			var ida: String = defs[a]["id"]
			var idb: String = defs[b]["id"]
			wins[ida] += score
			wins[idb] += n - score
			games[ida] += n
			games[idb] += n
			pair["%s vs %s" % [ida, idb]] = score / n
	var rows := []
	for d in defs:
		rows.append([wins[d["id"]] / games[d["id"]], d["id"]])
	rows.sort()
	rows.reverse()
	print("\nOverall win rate (%d games per matchup, CPU level %.1f)" % [n, level])
	for r in rows:
		print("  %-10s %5.1f%%  %s" % [r[1], r[0] * 100.0, "#".repeat(int(r[0] * 40.0))])
	var lop := []
	for k in pair:
		lop.append([absf(pair[k] - 0.5), k, pair[k]])
	lop.sort()
	lop.reverse()
	print("\nMost lopsided matchups (first fighter's win rate)")
	for i in mini(10, lop.size()):
		print("  %-24s %5.1f%%" % [lop[i][1], lop[i][2] * 100.0])
	if OS.has_environment("BALANCE_DETAIL"):
		print("\nDamage share by move")
		for d in defs:
			var total := 0.0
			var mine := []
			for k in dealt:
				if k.begins_with(d["id"] + ": "):
					total += dealt[k]
					mine.append([dealt[k], k.get_slice(": ", 1)])
			mine.sort()
			mine.reverse()
			var line := "  %-10s" % d["id"]
			for m in mine.slice(0, 7):
				line += "  %s %d%%" % [m[1], int(100.0 * m[0] / maxf(1.0, total))]
			print(line)
	print("\n%d rounds, %.0f%% ended by time-out, avg round %.1fs, sim speed %.0fx real time" % [
		rounds, 100.0 * timeouts / maxf(1.0, rounds), ticks / 60.0 / maxf(1.0, rounds),
		(ticks / 60.0) / maxf(0.001, (Time.get_ticks_msec() - t0) / 1000.0)])
	quit()
