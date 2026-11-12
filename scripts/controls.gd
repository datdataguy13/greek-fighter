class_name Controls
extends RefCounted

# Input actions for both players (keyboard + gamepad), registered in code so
# the project works the same on desktop, web and a Raspberry Pi.
# Gamepad 0 drives player 1 and gamepad 1 drives player 2.

const KEYS := [
	{"left": KEY_A, "right": KEY_D, "up": KEY_W, "down": KEY_S,
		"p": KEY_F, "k": KEY_G, "h": KEY_H, "s": KEY_T, "start": KEY_ENTER},
	{"left": KEY_LEFT, "right": KEY_RIGHT, "up": KEY_UP, "down": KEY_DOWN,
		"p": KEY_K, "k": KEY_L, "h": KEY_SEMICOLON, "s": KEY_O, "start": KEY_BACKSLASH},
]
const PAD_BUTTONS := {
	"left": [JOY_BUTTON_DPAD_LEFT], "right": [JOY_BUTTON_DPAD_RIGHT],
	"up": [JOY_BUTTON_DPAD_UP], "down": [JOY_BUTTON_DPAD_DOWN],
	"p": [JOY_BUTTON_X], "k": [JOY_BUTTON_A], "h": [JOY_BUTTON_B],
	"s": [JOY_BUTTON_Y, JOY_BUTTON_RIGHT_SHOULDER], "start": [JOY_BUTTON_START],
}
const PAD_AXES := {
	"left": [JOY_AXIS_LEFT_X, -1.0], "right": [JOY_AXIS_LEFT_X, 1.0],
	"up": [JOY_AXIS_LEFT_Y, -1.0], "down": [JOY_AXIS_LEFT_Y, 1.0],
}
const BITS := {"left": Inp.LEFT, "right": Inp.RIGHT, "up": Inp.UP, "down": Inp.DOWN,
	"p": Inp.P, "k": Inp.K, "h": Inp.H, "s": Inp.S}
const KEY_LABELS := [
	{"move": "W A S D", "p": "F", "k": "G", "h": "H", "s": "T"},
	{"move": "ARROWS", "p": "K", "k": "L", "h": ";", "s": "O"},
]

static var _ready := false


static func setup() -> void:
	if _ready:
		return
	_ready = true
	for i in 2:
		for name in KEYS[i]:
			var action := "p%d_%s" % [i + 1, name]
			InputMap.add_action(action, 0.5)
			var key := InputEventKey.new()
			key.physical_keycode = KEYS[i][name]
			InputMap.action_add_event(action, key)
			for button in PAD_BUTTONS.get(name, []):
				var jb := InputEventJoypadButton.new()
				jb.device = i
				jb.button_index = button
				InputMap.action_add_event(action, jb)
			if PAD_AXES.has(name):
				var jm := InputEventJoypadMotion.new()
				jm.device = i
				jm.axis = PAD_AXES[name][0]
				jm.axis_value = PAD_AXES[name][1]
				InputMap.action_add_event(action, jm)
	InputMap.add_action("pause")
	for code in [KEY_ESCAPE, KEY_P]:
		var ev := InputEventKey.new()
		ev.physical_keycode = code
		InputMap.action_add_event("pause", ev)
	for device in 2:
		var sb := InputEventJoypadButton.new()
		sb.device = device
		sb.button_index = JOY_BUTTON_START
		InputMap.action_add_event("pause", sb)


# The player's held inputs this frame as an Inp bitmask.
static func read(player: int) -> int:
	var bits := 0
	for name in BITS:
		if Input.is_action_pressed("p%d_%s" % [player + 1, name]):
			bits |= BITS[name]
	return bits


static func just(player: int, name: String) -> bool:
	return Input.is_action_just_pressed("p%d_%s" % [player + 1, name])


# Menu helpers: either player can drive menus unless a player is given.
static func menu_dir(player: int = -1) -> Vector2i:
	var d := Vector2i.ZERO
	for i in ([player] if player >= 0 else [0, 1]):
		d.x += int(just(i, "right")) - int(just(i, "left"))
		d.y += int(just(i, "down")) - int(just(i, "up"))
	return Vector2i(clampi(d.x, -1, 1), clampi(d.y, -1, 1))


static func confirm(player: int = -1) -> bool:
	for i in ([player] if player >= 0 else [0, 1]):
		if just(i, "p") or just(i, "start"):
			return true
	return false


static func back(player: int = -1) -> bool:
	for i in ([player] if player >= 0 else [0, 1]):
		if just(i, "k"):
			return true
	return false
