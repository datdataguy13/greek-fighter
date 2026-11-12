class_name Sfx
extends Node

# Sound effects synthesised at start-up, so the project ships no audio files
# and sounds the same on desktop, web and a Raspberry Pi.

const RATE := 22050

static var inst: Sfx

var streams := {}
var players: Array[AudioStreamPlayer] = []
var next := 0
var rng := RandomNumberGenerator.new()


static func play(sound: String, volume_db: float = -8.0, pitch: float = 1.0) -> void:
	if inst != null:
		inst._play(sound, volume_db, pitch)


func _ready() -> void:
	inst = self
	rng.seed = 7
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	streams["hit_light"] = _thump(0.11, 190.0, 0.55, 0.7)
	streams["hit_heavy"] = _thump(0.22, 95.0, 0.9, 0.9)
	streams["block"] = _tone(0.07, [900.0, 1370.0], 0.35, true)
	streams["whoosh"] = _noise_sweep(0.13, 0.22)
	streams["jump"] = _sweep(0.09, 280.0, 560.0, 0.25)
	streams["land"] = _thump(0.08, 70.0, 0.15, 0.5)
	streams["proj"] = _sweep(0.2, 980.0, 260.0, 0.3)
	streams["zap"] = _sweep(0.28, 1500.0, 120.0, 0.4)
	streams["super"] = _sweep(0.55, 180.0, 1100.0, 0.4)
	streams["ko"] = _thump(0.7, 55.0, 0.8, 1.0)
	streams["move"] = _tone(0.04, [660.0], 0.25, false)
	streams["ok"] = _sweep(0.1, 660.0, 990.0, 0.3)
	streams["back"] = _sweep(0.1, 440.0, 300.0, 0.3)
	streams["gong"] = _tone(0.7, [196.0, 294.0, 392.0, 588.0], 0.4, false)


func _play(sound: String, volume_db: float, pitch: float) -> void:
	if not streams.has(sound):
		return
	var p := players[next]
	next = (next + 1) % players.size()
	p.stream = streams[sound]
	p.volume_db = volume_db
	p.pitch_scale = pitch * rng.randf_range(0.94, 1.06)
	p.play()


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	return wav


# A low sine that drops in pitch, plus a burst of filtered noise: punches.
func _thump(dur: float, freq: float, noise: float, gain: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	var phase := 0.0
	for i in n:
		var u := float(i) / n
		var env := pow(1.0 - u, 2.2)
		phase += TAU * freq * (1.0 - 0.5 * u) / RATE
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.35)
		out[i] = (sin(phase) * 0.8 + lp * noise * pow(1.0 - u, 4.0)) * env * gain
	return _wav(out)


func _tone(dur: float, freqs: Array, gain: float, square: bool) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var u := float(i) / n
		var s := 0.0
		for f in freqs:
			var v := sin(TAU * f * i / RATE)
			s += signf(v) * 0.6 if square else v
		out[i] = s / freqs.size() * pow(1.0 - u, 2.0) * gain
	return _wav(out)


func _sweep(dur: float, f0: float, f1: float, gain: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var u := float(i) / n
		phase += TAU * lerpf(f0, f1, u) / RATE
		out[i] = (sin(phase) + 0.3 * sin(phase * 2.0)) * sin(PI * minf(1.0, u * 6.0) * 0.5) * (1.0 - u) * gain
	return _wav(out)


func _noise_sweep(dur: float, gain: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var u := float(i) / n
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.08 + 0.3 * u)
		out[i] = lp * sin(PI * u) * gain
	return _wav(out)
