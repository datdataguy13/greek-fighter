class_name TitleScreen
extends Node2D

const ITEMS := [["STORY MODE", "story"], ["2 PLAYER VERSUS", "2p"], ["1 PLAYER VS CPU", "cpu"], ["WATCH CPU VS CPU", "watch"]]
const ROW_Y := 336.0
const ROW_H := 46.0

var game: Game
var sel := 0
var time := 0.0
var stage_id := "olympus"
var posers: Array = []
var items: Array = ITEMS.duplicate()


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	stage_id = StageArt.LIST[rng.randi() % StageArt.LIST.size()]["id"]
	var ids: Array = Looks.ORDER.duplicate()
	var a: String = ids.pop_at(rng.randi() % ids.size())
	posers = [a, ids[rng.randi() % ids.size()]]
	# A way out for gamepad-only setups like RetroPie (a browser tab has its own).
	if not OS.has_feature("web"):
		items.append(["QUIT", "quit"])
	for i in ITEMS.size():
		if ITEMS[i][1] == game.session["mode"]:
			sel = i
	Music.play("title")


func _physics_process(delta: float) -> void:
	time += delta
	var d := Controls.menu_dir()
	if d.y != 0:
		sel = posmod(sel + d.y, items.size() + 2)
		Sfx.play("move")
	if sel == ITEMS.size() and d.x != 0:
		var idx := posmod(game.session["level_idx"] + d.x, Game.LEVELS.size())
		game.session["level_idx"] = idx
		game.session["level"] = Game.LEVELS[idx][1]
		Sfx.play("move")
	if sel == ITEMS.size() + 1 and (d.x != 0 or Controls.confirm()):
		Music.set_enabled(not Music.enabled)
		Sfx.play("move")
	if Controls.confirm() and sel >= ITEMS.size() + 2:
		get_tree().quit()
		return
	if Controls.confirm() and sel < ITEMS.size():
		game.session["mode"] = ITEMS[sel][1]
		Sfx.play("ok")
		game.goto("select")
	queue_redraw()


func _draw() -> void:
	StageArt.draw(self, stage_id, 310.0 + sin(time * 0.25) * 250.0, time)
	draw_rect(Rect2(0, 0, UI.W, UI.H), Color(0.05, 0.03, 0.12, 0.55))
	UI.halftone(self, Rect2(0, 380, UI.W, 340), Color(0, 0, 0, 0.22))
	for i in 2:
		var look: Dictionary = Looks.L[posers[i]]
		var s: float = look.get("scale", 1.0) * 1.25
		var pos := Vector2(190.0 if i == 0 else UI.W - 190.0, 690.0)
		Rig.draw_shadow(self, pos, 0.0, s)
		Rig.draw(self, Transform2D(0.0, Vector2(s if i == 0 else -s, s), 0.0, pos), look, Poses.idle(time + i), {"time": time})

	var bob := sin(time * 2.0) * 4.0
	draw_set_transform(Vector2(UI.W * 0.5, 190 + bob), -0.035, Vector2.ONE)
	var w := UI.width("GREEK FIGHTER", 170)
	UI.text(self, Vector2(-w * 0.5 + 8, 10), "GREEK FIGHTER", 170, UI.RED, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	UI.text(self, Vector2(-w * 0.5, 0), "GREEK FIGHTER", 170, UI.GOLD, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	UI.centered(self, 262, "GODS & HEROES THROW DOWN", 44, UI.CREAM)

	for i in ITEMS.size():
		var on := i == sel
		UI.centered(self, ROW_Y + i * ROW_H, ("> %s <" % ITEMS[i][0]) if on else ITEMS[i][0], 46 if on else 38, UI.GOLD if on else UI.CREAM)
	var on2 := sel == ITEMS.size()
	var lvl: String = Game.LEVELS[game.session["level_idx"]][0]
	UI.centered(self, ROW_Y + ITEMS.size() * ROW_H + 6.0, "CPU LEVEL:  < %s >" % lvl, 34 if on2 else 30, UI.GOLD if on2 else Color("9aa4c0"))
	var on3 := sel == ITEMS.size() + 1
	UI.centered(self, ROW_Y + (ITEMS.size() + 1) * ROW_H, "MUSIC:  < %s >" % ("ON" if Music.enabled else "OFF"), 34 if on3 else 30, UI.GOLD if on3 else Color("9aa4c0"))
	if items.size() > ITEMS.size():
		var on4 := sel == ITEMS.size() + 2
		UI.centered(self, ROW_Y + (ITEMS.size() + 2) * ROW_H - 6.0, "> QUIT <" if on4 else "QUIT", 34 if on4 else 30, UI.GOLD if on4 else Color("9aa4c0"))

	UI.centered(self, 664, "P1:  W A S D  +  F  G  H  T          P2:  ARROWS  +  K  L  ;  O          GAMEPADS WORK TOO", 22, Color("c8d0e8"))
	UI.centered(self, 696, "PUNCH / ENTER = SELECT        KICK = BACK        ESC = PAUSE", 22, Color("9aa4c0"))
