class_name Music
extends Node

# Chiptune soundtrack, synthesised from the note data in songs.gd, so the
# project still ships no audio files.
#
# Rendering a song takes a moment in GDScript, so it is done a few
# milliseconds per frame: the song that is wanted right now first, then the
# rest in the background. Each finished song is a looping AudioStreamWAV.

const RATE := 22050
const VOLUME_DB := -7.0
const MASTER := 0.72
const SETTINGS := "user://settings.cfg"
const GAIN := {"reed": 0.17, "square": 0.15, "lyre": 0.3, "arp": 0.13, "bass": 0.3, "D": 0.55, "t": 0.2, "s": 0.09}

static var inst: Music
static var enabled := true

var player: AudioStreamPlayer
var streams := {}   # song id -> AudioStreamWAV
var current := ""   # the song that should be playing
var playing := ""   # the song the player is holding
var vol := 0.0
var queue: Array = []
var rng := RandomNumberGenerator.new()

# The render in progress.
var _waves := {}
var _job := ""
var _events: Array = []
var _next := 0
var _dry := PackedFloat32Array()
var _wet := PackedFloat32Array()
var _data := PackedByteArray()
var _n := 0
var _pos := 0
var _loop := true
var _delay := 0
var _lp := 0.0


static func play(id: String) -> void:
	if inst != null:
		inst.current = id


static func stop() -> void:
	play("")


# Ask for a song to be rendered next, before it is needed.
static func prepare(id: String) -> void:
	if inst != null and not inst.streams.has(id):
		inst.queue.erase(id)
		inst.queue.push_front(id)


static func set_enabled(on: bool) -> void:
	enabled = on
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", on)
	cfg.save(SETTINGS)


func _ready() -> void:
	inst = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		enabled = cfg.get_value("audio", "music", true)
	player = AudioStreamPlayer.new()
	add_child(player)
	queue = Songs.ALL.keys()


func _process(delta: float) -> void:
	if _job == "":
		if enabled and current != "" and not streams.has(current):
			_begin(current)
		elif enabled and not queue.is_empty():
			var id: String = queue.pop_front()
			if not streams.has(id):
				_begin(id)
	if _job != "":
		_work(9000 if _job == current else 2500)

	var want := current if enabled else ""
	if want == playing:
		vol = minf(1.0, vol + delta * 4.0)
	else:
		vol = maxf(0.0, vol - delta * 5.0)
		if vol <= 0.0 and (want == "" or streams.has(want)):
			playing = want
			player.stop()
			if want != "":
				player.stream = streams[want]
				player.play()
	player.volume_db = VOLUME_DB + linear_to_db(maxf(vol, 0.001))


# Renders a whole song in one go (tools and tests).
func render(id: String) -> AudioStreamWAV:
	if not streams.has(id):
		if _job != "" and _job != id:
			_work(1 << 40)
		if _job == "":
			_begin(id)
		_work(1 << 40)
	return streams[id]


# --- planning: song data -> a list of notes --------------------------------

static func _pitch(song: Dictionary, index: int) -> int:
	var scale: Array = song["scale"]
	return song["root"] + scale[posmod(index, 7)] + 12 * floori(index / 7.0)


func _begin(id: String) -> void:
	var song: Dictionary = Songs.ALL[id]
	var bar: int = song["bar"]
	var step: float = RATE * 60.0 / song["spm"]
	var scale: Array = song["scale"]
	_events = []
	var at := 0  # in steps
	for p: Dictionary in Songs.parts(song):
		var drum: String = p.get("drum", song["drum"])
		var bass: String = p.get("bass", song["bass"])
		var arp: String = p.get("arp", song["arp"])
		var lead: String = p.get("lead_inst", song["lead"])
		var lead_oct: int = p.get("lead_oct", song.get("lead_oct", 1))
		var chords: PackedStringArray = p["chords"].split(" ", false)
		var bars: PackedStringArray = p["lead"].split("|")
		for b in chords.size():
			var deg := int(chords[b]) - 1
			# Keep the bass line low: chords high in the scale drop an octave.
			var low := -12 if scale[deg] < 7 else -24
			for i in bar:
				var start := int((at + i) * step)
				var d := drum[i]
				if d != "-":
					_events.append([start, d, 0, 0, GAIN[d], 0])
				var a := arp[i]
				if a != "-":
					var tone: int = [0, 2, 4, 7, 9][int(a)]
					_events.append([start, "lyre", _pitch(song, deg + tone), int(step * 2.0), GAIN["arp"], 0])
				var c := bass[i]
				if c != "-" and c != "_":
					var hold := 1
					while i + hold < bar and bass[i + hold] == "_":
						hold += 1
					var bt: int = {"0": 0, "2": 4, "3": 7}[c]
					_events.append([start, "bass", _pitch(song, deg + bt) + low, int(step * hold), GAIN["bass"], 0])
			var s := at
			for note in Songs.parse_bar(bars[b]):
				if note[0] > 0:
					var midi: int = _pitch(song, note[0] - 1) + 12 * (lead_oct + note[1])
					_events.append([int(s * step), lead, midi, int(step * note[2]), GAIN[lead], 1])
				s += note[2]
			at += bar
	_job = id
	_next = 0
	_n = int(at * step)
	_pos = 0
	_lp = 0.0
	_loop = song.get("loop", true)
	_delay = int(step * song.get("echo", 1.5))
	_dry = PackedFloat32Array()
	_dry.resize(_n)
	_wet = PackedFloat32Array()
	_wet.resize(_n)
	_data = PackedByteArray()
	_data.resize(_n * 2)


# --- rendering -------------------------------------------------------------

func _work(budget_usec: int) -> void:
	var t0 := Time.get_ticks_usec()
	while _job != "" and Time.get_ticks_usec() - t0 < budget_usec:
		if _next < _events.size():
			_mix(_events[_next])
			_next += 1
		elif _pos < _n:
			_finish(4096)
		else:
			var wav := AudioStreamWAV.new()
			wav.format = AudioStreamWAV.FORMAT_16_BITS
			wav.mix_rate = RATE
			wav.data = _data
			if _loop:
				wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
				wav.loop_end = _n
			streams[_job] = wav
			_job = ""
			_events = []
			_waves = {}
			_dry = PackedFloat32Array()
			_wet = PackedFloat32Array()


# Adds one note to the mix. Notes that ring past the end of a looping song
# wrap round to its start, so the loop has no seam.
func _mix(e: Array) -> void:
	var w := _wave(e[1], e[2], e[3])
	var g: float = e[4]
	var start: int = e[0]
	var count := w.size()
	var first := mini(count, _n - start)
	if e[5] == 1:
		for k in first:
			_wet[start + k] += w[k] * g
		if _loop:
			for k in range(first, count):
				_wet[k - first] += w[k] * g
	else:
		for k in first:
			_dry[start + k] += w[k] * g
		if _loop:
			for k in range(first, count):
				_dry[k - first] += w[k] * g


# Echo on the melody, a touch of low-pass to take the edge off, then 16-bit.
func _finish(count: int) -> void:
	var end := mini(_n, _pos + count)
	for i in range(_pos, end):
		var v := _dry[i] + _wet[i]
		var j := i - _delay
		if j < 0 and _loop:
			j += _n
		if j >= 0:
			v += _wet[j] * 0.28
		_lp += (v - _lp) * 0.72
		_data.encode_s16(i * 2, int(clampf(_lp * MASTER, -1.0, 1.0) * 30000.0))
	_pos = end


func _wave(kind: String, midi: int, length: int) -> PackedFloat32Array:
	var key := "%s %d %d" % [kind, midi, length]
	if not _waves.has(key):
		_waves[key] = _synth(kind, midi, length)
	return _waves[key]


func _synth(kind: String, midi: int, length: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var freq := 440.0 * pow(2.0, (midi - 69) / 12.0)
	var inc := freq / RATE
	var ph := 0.0
	match kind:
		"lyre":
			# A plucked string: bright at the start, dying away on its own.
			var n := clampi(length + RATE / 4, RATE * 3 / 10, RATE)
			out.resize(n)
			var fall := -5.5 / RATE
			for i in n:
				ph = fposmod(ph + inc, 1.0)
				var tri := 4.0 * absf(ph - 0.5) - 1.0
				var pulse := 1.0 if ph < 0.25 else -0.33
				var bright := exp(i * fall * 3.0)
				out[i] = (tri * 0.75 + pulse * 0.6 * bright) * exp(i * fall) * minf(1.0, i / 30.0) * minf(1.0, (n - i) / 200.0)
		"reed", "square":
			# Aulos (thin 25% pulse) or a rounder flute-like square, with vibrato on held notes.
			var n := maxi(200, length - RATE / 90)
			out.resize(n)
			var duty := 0.25 if kind == "reed" else 0.5
			var lo := -duty / (1.0 - duty)
			var vib_from := RATE * 0.16
			for i in n:
				var bend := 1.0
				if i > vib_from:
					bend += 0.006 * sin((i - vib_from) * TAU * 5.6 / RATE) * minf(1.0, (i - vib_from) / (RATE * 0.2))
				ph = fposmod(ph + inc * bend, 1.0)
				var env := minf(1.0, i / 180.0) * (0.72 + 0.28 * exp(-i * 9.0 / RATE)) * minf(1.0, (n - i) / 500.0)
				out[i] = (1.0 if ph < duty else lo) * env
		"bass":
			var n := maxi(200, length - RATE / 60)
			out.resize(n)
			for i in n:
				ph = fposmod(ph + inc, 1.0)
				var env := minf(1.0, i / 60.0) * (0.6 + 0.4 * exp(-i * 6.0 / RATE)) * minf(1.0, (n - i) / 400.0)
				out[i] = (4.0 * absf(ph - 0.5) - 1.0) * env
		"D":
			# Frame drum: a low thud that drops in pitch.
			var n := int(RATE * 0.2)
			out.resize(n)
			rng.seed = 11
			for i in n:
				var u := float(i) / n
				ph += (125.0 - 80.0 * u) / RATE
				out[i] = (sin(ph * TAU) + rng.randf_range(-0.25, 0.25) * pow(1.0 - u, 6.0)) * pow(1.0 - u, 2.0)
		"t", "s":
			# Rim hit and shaker: short bursts of thinned-out noise.
			var n := int(RATE * (0.07 if kind == "t" else 0.035))
			out.resize(n)
			rng.seed = 23 if kind == "t" else 37
			var last := 0.0
			for i in n:
				var u := float(i) / n
				var r := rng.randf_range(-1.0, 1.0)
				out[i] = (r - last * 0.7) * pow(1.0 - u, 3.0) + (sin(i * TAU * 900.0 / RATE) * 0.5 * pow(1.0 - u, 4.0) if kind == "t" else 0.0)
				last = r
	return out
