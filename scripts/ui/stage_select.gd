class_name StageSelectScreen
extends Node2D

const COLS := 4
const TW := 270.0
const TH := 152.0
const GAP := 22.0

# A clipped, scaled-down live view of one stage.
class Thumb:
	extends Control
	var stage_id := ""
	var time := 0.0

	func _init() -> void:
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := size.x / UI.W
		StageArt.draw(self, stage_id, 310.0, time, Transform2D(0.0, Vector2(s, s), 0.0, Vector2.ZERO))
		draw_rect(Rect2(Vector2.ZERO, size), UI.INK, false, 5.0)


var game: Game
var sel := 0
var time := 0.0
var thumbs: Array[Thumb] = []


func _ready() -> void:
	Music.play("select")
	for i in StageArt.LIST.size():
		if StageArt.LIST[i]["id"] == game.session["stage"]:
			sel = i
		var t := Thumb.new()
		t.stage_id = StageArt.LIST[i]["id"]
		t.size = Vector2(TW, TH)
		t.position = _pos(i)
		add_child(t)
		thumbs.append(t)


func _pos(i: int) -> Vector2:
	var x0 := (UI.W - (COLS * TW + (COLS - 1) * GAP)) * 0.5
	return Vector2(x0 + (i % COLS) * (TW + GAP), 150.0 + (i / COLS) * (TH + 84.0))


func _physics_process(delta: float) -> void:
	time += delta
	var d := Controls.menu_dir()
	if d != Vector2i.ZERO:
		var rows := ceili(float(StageArt.LIST.size()) / COLS)
		var col := posmod(sel % COLS + d.x, COLS)
		var row := posmod(sel / COLS + d.y, rows)
		sel = mini(row * COLS + col, StageArt.LIST.size() - 1)
		Sfx.play("move")
	if Controls.confirm():
		game.session["stage"] = StageArt.LIST[sel]["id"]
		Sfx.play("ok")
		game.goto("fight")
		return
	if Controls.back():
		Sfx.play("back")
		game.goto("select")
		return
	# Only the highlighted arena animates, to keep this screen cheap.
	Music.prepare(StageArt.LIST[sel]["id"])
	thumbs[sel].time = time
	thumbs[sel].queue_redraw()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, UI.W, UI.H), Color("1c2340"))
	UI.halftone(self, Rect2(0, 0, UI.W, UI.H), Color(1, 1, 1, 0.05), 30.0)
	UI.centered(self, 90, "CHOOSE YOUR ARENA", 70, UI.GOLD)
	for i in StageArt.LIST.size():
		var p := _pos(i)
		var on := i == sel
		if on:
			var g := 7.0 + sin(time * 10.0) * 2.0
			draw_rect(Rect2(p - Vector2(g, g), Vector2(TW, TH) + Vector2(g, g) * 2.0), UI.GOLD, false, 7.0)
		UI.text(self, Vector2(p.x, p.y + TH + 34), StageArt.LIST[i]["name"].to_upper(), 30, UI.GOLD if on else UI.CREAM,
			HORIZONTAL_ALIGNMENT_CENTER, TW)
		UI.text(self, Vector2(p.x, p.y + TH + 58), StageArt.LIST[i]["sub"].to_upper(), 18, Color("9aa4c0"),
			HORIZONTAL_ALIGNMENT_CENTER, TW, 2)
	UI.centered(self, 704, "PUNCH = FIGHT!      KICK = BACK", 22, Color("9aa4c0"))
