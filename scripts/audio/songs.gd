class_name Songs
extends RefCounted

# The soundtrack, written as data and turned into sound by music.gd.
#
# The tunes lean on what we know of ancient Greek and later Mediterranean
# music: old modes instead of plain major/minor (the Greeks' own "Dorian" is
# today's Phrygian; the Hijaz scale gives the eastern-Mediterranean colour),
# limping dance metres in 7 and 5 beats, a plucked lyre, a reedy aulos (the
# Greek double pipe) and a frame drum. The voices are the classic 8-bit set:
# pulse waves, a triangle bass and noise percussion.
#
# A song:
#   spm     steps per minute (a step is the shortest note, usually an eighth)
#   bar     steps per bar (7 = 7/8 time, 5 = 5/8, 6 = 6/8, 8 = 4/4)
#   root    MIDI note of scale degree 1
#   scale   semitone offsets of the seven scale degrees
#   lead    lead instrument: "reed" (aulos), "square" (flute-like) or "lyre"
#   drum    one character per step: D = low drum, t = rim "tek", s = shaker, - = rest
#   bass    one character per step: 0 = chord root, 2 = fifth, 3 = octave,
#           _ = keep holding the last note, - = rest
#   arp     the lyre: one character per step, 0 1 2 = root / third / fifth of
#           the bar's chord, 3 4 = root / third an octave up, - = rest
#   parts   sections of the tune; "seq" (optional) is the order to play them in
#
# A part:
#   chords  one scale degree per bar; the chord is the triad built on it
#   lead    the melody, bars separated by "|". A note is a scale degree 1-7,
#           ' or , to go up or down an octave, then :length in steps
#           (default 1). "-" is a rest. Every bar must add up to `bar` steps.
#   copy    index of another part to reuse, with any fields overridden
#   Parts may also override drum, bass, arp, lead_inst and lead_oct.

const DORIAN := [0, 2, 3, 5, 7, 9, 10]
const PHRYGIAN := [0, 1, 3, 5, 7, 8, 10]
const HIJAZ := [0, 1, 4, 5, 7, 8, 10]
const MINOR := [0, 2, 3, 5, 7, 8, 10]
const MAJOR := [0, 2, 4, 5, 7, 9, 11]
const MIXOLYDIAN := [0, 2, 4, 5, 7, 9, 10]

# Which song plays where. Arenas use their own id.
const SCREENS := {"title": "title", "select": "select", "versus": "versus", "ending": "ending", "win": "victory"}

const ALL := {
	# Heroes' dance in 7/8 (3+2+2, the kalamatianos rhythm).
	"title": {
		"name": "Gods and Heroes", "spm": 300, "bar": 7, "root": 57, "scale": DORIAN, "lead": "reed",
		"drum": "DstD-t-", "bass": "0__0_2_", "arp": "0120212",
		"parts": [
			{"chords": "1 7 1 5 1 4 7 1",
				"lead": "1:3 3:2 5:2 | 7:3 6 5 4:2 | 5:3 3:2 4:2 | 5:3 5:2 -:2 | 1':3 7:2 5:2 | 6:3 5:2 4:2 | 4:3 2:2 7,:2 | 1:5 -:2"},
			{"chords": "3 7 1 1 3 7 5 1", "drum": "DstDstt",
				"lead": "5:2 5 7:2 5:2 | 4:2 4 7:2 4:2 | 3:2 3 5:2 1':2 | 7:3 5:4 | 5:2 5 7:2 1':2 | 2':3 1':2 7:2 | 5:3 6:2 7:2 | 1':5 -:2"},
		],
	},
	# A lyre picking over a slow drum while you choose.
	"select": {
		"name": "The Lyre Player", "spm": 216, "bar": 8, "root": 50, "scale": DORIAN, "lead": "lyre",
		"drum": "D-s-t-ss", "bass": "0___0_2_", "arp": "01231232",
		"parts": [
			{"chords": "1 7 1 4 1 7 5 1",
				"lead": "5:2 4 3 1:2 3:2 | 2:2 4 2 7,:2 2:2 | 3:2 5 3 1:2 5:2 | 6:3 5 4:4 | 5:2 4 3 1:2 3:2 | 2:2 4 2 7,:2 4:2 | 5:2 7 5 3:2 2:2 | 1:6 -:2"},
		],
	},
	# Before a fight: short, tense, eastern.
	"versus": {
		"name": "Face to Face", "spm": 280, "bar": 8, "root": 52, "scale": HIJAZ, "lead": "reed",
		"drum": "DstsDstt", "bass": "00-00-03", "arp": "0-1-2-1-",
		"parts": [
			{"chords": "1 1 2 1",
				"lead": "1:2 2 3 2:2 1:2 | 5:2 6 5 4:2 3:2 | 2:2 4 6 4:2 2:2 | 3:2 2 1 1:4"},
			{"copy": 0, "lead_oct": 2, "arp": "01230123"},
		],
	},
	# Mount Olympus: a bright fanfare.
	"olympus": {
		"name": "Hall of the Gods", "spm": 244, "bar": 8, "root": 50, "scale": MIXOLYDIAN, "lead": "square",
		"drum": "D-s-t-ss", "bass": "0-0-2-0-", "arp": "01232123",
		"parts": [
			{"chords": "1 1 7 4 1 1 7 1",
				"lead": "1:2 1 1 5:4 | 5:2 6 5 3:2 5:2 | 7:3 6 5:2 4:2 | 4:2 6 1' 6:4 | 1':2 1' 1' 5:4 | 5:2 6 5 3:2 1:2 | 2:2 4 2 7,:2 2:2 | 1:6 -:2"},
			{"chords": "4 4 1 1 7 7 5 1", "drum": "D-stD-st",
				"lead": "6:3 6 1':2 6:2 | 4:2 5 6 1':4 | 5:3 5 1':2 5:2 | 3:2 4 5 5:4 | 7:3 7 2':2 7:2 | 4:2 5 7 2':4 | 2':2 1' 7 5:2 7:2 | 1':6 -:2"},
		],
	},
	# The walls of Troy: a war march.
	"troy": {
		"name": "The Wrath", "spm": 256, "bar": 8, "root": 50, "scale": MINOR, "lead": "reed",
		"drum": "D-tDD-t-", "bass": "0-0-0-02", "arp": "0-120-12",
		"parts": [
			{"chords": "1 1 6 7 1 1 6 5",
				"lead": "1:3 1 3:2 5:2 | 5:3 4 3:2 1:2 | 6:3 6 5:2 3:2 | 4:3 4 2:2 7,:2 | 1:3 1 3:2 5:2 | 1':3 7 5:2 3:2 | 6:3 5 3:2 1:2 | 2:3 2 5:4"},
			{"chords": "4 4 1 1 6 7 1 1", "drum": "D-tDD-tt",
				"lead": "4:2 6 4 1':2 6:2 | 4:2 6 4 1':4 | 3:2 5 3 1':2 5:2 | 3:2 5 3 1':4 | 6:2 1' 6 3':2 1':2 | 7:2 2' 7 4':2 2':2 | 5':3 4' 3':2 1':2 | 1':6 -:2"},
		],
	},
	# The river Styx: slow, low, in the Greeks' own Dorian mode.
	"styx": {
		"name": "The Ferryman", "spm": 156, "bar": 6, "root": 52, "scale": PHRYGIAN, "lead": "square",
		"drum": "D--s--", "bass": "0_____", "arp": "012-1-",
		"parts": [
			{"chords": "1 2 1 7 1 2 3 1",
				"lead": "5:3 3:3 | 4:3 2:3 | 3:2 2 1:3 | 7,:3 2:3 | 5:3 3:3 | 6:3 4:3 | 5:2 4 3:3 | 1:6"},
			{"chords": "6 6 4 4 2 2 1 1", "drum": "D--t-s",
				"lead": "6:2 5 6:3 | 1':3 6:3 | 4:2 3 4:3 | 6:3 4:3 | 2:2 3 4:3 | 6:3 4:2 2 | 3:3 2:3 | 1:6"},
		],
	},
	# The Labyrinth: a winding tune in 5/8.
	"labyrinth": {
		"name": "The Thread", "spm": 270, "bar": 5, "root": 57, "scale": HIJAZ, "lead": "reed",
		"drum": "DstDt", "bass": "0__0_", "arp": "01202",
		"seq": [0, 1, 2, 1],
		"parts": [
			{"chords": "1 1 2 1 1 1 7 1",
				"lead": "1:3 2:2 | 3:3 2 1 | 2:3 4:2 | 3:2 2 1:2 | 5:3 6:2 | 5:2 4 3:2 | 4:3 2:2 | 1:5"},
			{"chords": "4 4 2 2 4 4 2 1", "drum": "DstDs",
				"lead": "4:2 6 1':2 | 1':3 6:2 | 2':2 1' 6:2 | 4:3 6:2 | 4:2 6 1':2 | 6:3 1':2 | 2':2 1' 7 6 | 5:2 3 1:2"},
			{"copy": 0, "lead_inst": "lyre", "arp": "0-2-1"},
		],
	},
	# The deck of the Argo: a rolling sea jig.
	"argo": {
		"name": "Row, Argonauts", "spm": 330, "bar": 6, "root": 55, "scale": MAJOR, "lead": "square",
		"drum": "D-st-s", "bass": "0__2__", "arp": "021021",
		"seq": [0, 1, 2, 1],
		"parts": [
			{"chords": "1 1 4 1 1 1 5 1",
				"lead": "1:2 1 3:2 5 | 5:2 6 5:2 3 | 4:2 4 6:2 1' | 5:3 3:3 | 1:2 1 3:2 5 | 1':2 7 6:2 5 | 2:2 3 4:2 2 | 1:4 -:2"},
			{"chords": "6 6 4 4 1 1 5 1", "drum": "D-sD-t",
				"lead": "6:2 5 3:2 5 | 6:2 1' 6:3 | 4:2 3 4:2 6 | 1':2 6 4:3 | 3:2 2 1:2 3 | 5:2 3 5:2 1' | 7:2 6 5:2 2 | 1:4 -:2"},
			{"copy": 0, "lead_inst": "reed"},
		],
	},
	# The Acropolis: stately, over a hand-drum pattern.
	"acropolis": {
		"name": "City of the Owl", "spm": 250, "bar": 8, "root": 52, "scale": DORIAN, "lead": "reed",
		"drum": "Dt-tD-t-", "bass": "0__0_02_", "arp": "01230123",
		"parts": [
			{"chords": "1 4 1 7 1 4 7 1",
				"lead": "1:2 3:2 5:3 4 | 6:2 5:2 4:4 | 5:2 7:2 5:3 3 | 2:2 4:2 2:4 | 1:2 3:2 5:3 7 | 1':2 6:2 4:4 | 4:2 2:2 7,:3 2 | 1:6 -:2"},
			{"chords": "3 3 4 4 7 7 5 1", "drum": "Dt-tD-tt",
				"lead": "3:3 5 7:2 5:2 | 7:3 5 3:4 | 4:3 6 1':2 6:2 | 1':3 6 4:4 | 7:3 2' 4':2 2':2 | 4':3 2' 7:4 | 5:2 7:2 2':2 7:2 | 1':6 -:2"},
		],
	},
	# The oracle at Delphi: a slow 7/8 through the incense.
	"delphi": {
		"name": "The Oracle Speaks", "spm": 214, "bar": 7, "root": 50, "scale": HIJAZ, "lead": "reed",
		"drum": "D--t-t-", "bass": "0__0_2_", "arp": "0120123",
		"parts": [
			{"chords": "1 1 2 1 1 7 2 1",
				"lead": "1:3 3:2 2:2 | 1:3 2 3 5:2 | 6:3 5:2 4:2 | 3:3 2:2 1:2 | 5:3 6:2 5:2 | 4:3 2:2 7,:2 | 2:3 4:2 2:2 | 1:5 -:2"},
			{"chords": "4 4 1 1 4 2 7 1", "drum": "D-st-ts",
				"lead": "4:3 6:2 1':2 | 1':3 7 6 4:2 | 3:3 5:2 1':2 | 5:3 3:4 | 4:3 6:2 1':2 | 2':3 1' 6 4:2 | 2:3 4:2 7:2 | 1':3 5:2 1:2"},
		],
	},
	# The Cyclops' cave: something very large is stamping about.
	"cyclops": {
		"name": "Nobody Home", "spm": 204, "bar": 8, "root": 48, "scale": PHRYGIAN, "lead": "reed",
		"drum": "D--DD-t-", "bass": "0--00-2-", "arp": "0-1-2-1-",
		"parts": [
			{"chords": "1 1 2 1 1 1 7 1",
				"lead": "1:4 1 2 1:2 | 5:4 3:2 1:2 | 2:4 2 4 2:2 | 3:4 1:4 | 1:4 1 2 1:2 | 5:4 7:2 5:2 | 4:4 2:2 7,:2 | 1:6 -:2"},
			{"chords": "6 6 4 4 2 2 1 1", "drum": "D-tDD-tD",
				"lead": "6:3 6 1':2 6:2 | 3:4 6:4 | 4:3 4 6:2 4:2 | 1:4 4:4 | 2:3 2 4:2 6:2 | 6:2 4:2 2:4 | 3:2 2 1 5,:4 | 1:6 -:2"},
		],
	},
	# The end of the journey: lyre alone.
	"ending": {
		"name": "Homecoming", "spm": 190, "bar": 8, "root": 55, "scale": MAJOR, "lead": "lyre",
		"drum": "--------", "bass": "0___2___", "arp": "01232123",
		"parts": [
			{"chords": "1 5 6 4 1 5 4 1",
				"lead": "3:2 5:2 1':3 7 | 2':2 7:2 5:4 | 6:2 1':2 3':3 2' | 1':2 6:2 4:4 | 3:2 5:2 1':3 2' | 2':2 7:2 2':4 | 1':2 6:2 4:2 6:2 | 3:2 2:2 1:4"},
		],
	},
	# Match won: a short fanfare that plays once.
	"victory": {
		"name": "Victory", "spm": 380, "bar": 8, "root": 50, "scale": MAJOR, "lead": "square", "loop": false,
		"drum": "D-ttD-tt", "bass": "0-0-0-0-", "arp": "01230123",
		"parts": [
			{"chords": "1 4 1", "lead": "1 1 1 3:2 1 3:2 | 4 4 4 6:2 4 6:2 | 5:2 5 5 1':4"},
			{"chords": "1 1", "drum": "D-------", "bass": "0_______", "arp": "0123----", "lead": "-:8 | -:8"},
		],
	},
}


# The parts of a song in playing order, with "copy" resolved.
static func parts(song: Dictionary) -> Array:
	var out: Array = []
	var list: Array = song["parts"]
	var order: Array = song.get("seq", range(list.size()))
	for idx in order:
		var p: Dictionary = list[idx]
		if p.has("copy"):
			var merged: Dictionary = list[p["copy"]].duplicate()
			merged.merge(p, true)
			p = merged
		out.append(p)
	return out


# Parses one bar of melody into [[degree, octave, steps], ...]; degree 0 is a rest.
static func parse_bar(text: String) -> Array:
	var out: Array = []
	for tok in text.strip_edges().split(" ", false):
		var bits := tok.split(":")
		var steps := int(bits[1]) if bits.size() > 1 else 1
		var head: String = bits[0]
		if head == "-":
			out.append([0, 0, steps])
			continue
		out.append([int(head.substr(0, 1)), head.count("'") - head.count(","), steps])
	return out


# Returns a list of problems with a song (empty when it is well-formed).
static func check(id: String) -> Array:
	var song: Dictionary = ALL[id]
	var bar: int = song["bar"]
	var problems: Array = []
	for key in ["drum", "bass", "arp"]:
		if song[key].length() != bar:
			problems.append("%s: %s pattern is not %d steps" % [id, key, bar])
	var k := 0
	for p in parts(song):
		for key in ["drum", "bass", "arp"]:
			if p.has(key) and p[key].length() != bar:
				problems.append("%s part %d: %s pattern is not %d steps" % [id, k, key, bar])
		var chords: PackedStringArray = p["chords"].split(" ", false)
		var bars: PackedStringArray = p["lead"].split("|")
		if chords.size() != bars.size():
			problems.append("%s part %d: %d chords but %d bars of melody" % [id, k, chords.size(), bars.size()])
		for b in bars.size():
			var total := 0
			for note in parse_bar(bars[b]):
				total += note[2]
				if note[0] < 0 or note[0] > 7:
					problems.append("%s part %d bar %d: bad degree" % [id, k, b + 1])
			if total != bar:
				problems.append("%s part %d bar %d: adds up to %d steps, not %d" % [id, k, b + 1, total, bar])
		k += 1
	return problems
