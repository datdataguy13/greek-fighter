class_name Roster
extends RefCounted

# The playable fighters: stats, normals and special moves. Looks live in
# looks.gd; move fields are documented in sim/moves.gd.
#
# Every fighter has three specials and a super:
#   sn  Special            (or down, down-forward, forward + Punch)
#   sf  forward/back + Special  (or forward, down, down-forward + Punch)
#   sd  down + Special     (or down, down-back, back + Kick)
#   sa  Special in the air (only some fighters)
#   super  down, down + Special with a full meter
#
# Balance levers, roughly in order of impact: hp, walk speed, normal power,
# then each special's damage / startup / recovery. tools/balance.gd plays the
# CPU against itself across every matchup to spot outliers.

static var _all: Array = []
static var _by_id := {}


static func all() -> Array:
	if _all.is_empty():
		_build()
	return _all


static func get_def(id: String) -> Dictionary:
	if _all.is_empty():
		_build()
	return _by_id[id]


static func _add(d: Dictionary) -> void:
	var look: Dictionary = Looks.L[d["id"]]
	d["look"] = look
	d["size"] = look.get("scale", 1.0)
	if not d.has("traits"):
		d["traits"] = []
	_all.append(d)
	_by_id[d["id"]] = d


static func _build() -> void:
	_add({
		"id": "zeus", "name": "Zeus", "title": "King of Olympus", "style": "Power zoner",
		"tagline": "Rules the sky. Terrible at boundaries.",
		"quotes": ["I'd apologize, but I'm Zeus.", "You were warned. There was thunder and everything."],
		"hp": 1000, "walk": 3.3, "dash": 9.5, "jump": 21.0, "jump_x": 5.4,
		"normals": Moves.normals("swing", 1.04, 1),
		"specials": {
			"sn": Moves.projectile("Thunderbolt", {"startup": 15, "recovery": 31, "proj": {"kind": "bolt", "vx": 12.0, "dmg": 58, "w": 76.0, "h": 34.0}}),
			"sf": Moves.remote("Sky Father's Wrath", {"startup": 18, "recovery": 30, "proj": {"kind": "skybolt", "dmg": 62, "hitstun": 20}}),
			"sd": Moves.uppercut("Storm Rise", {"dmg": 100}),
		},
		"super": Moves.super_move(Moves.remote("Wrath of Olympus", {"startup": 10, "recovery": 40,
			"proj": {"kind": "megabolt", "delay": 10, "w": 170.0, "hits": 5, "gap": 4, "life": 26, "dmg": 58, "chip": 6}})),
	})
	_add({
		"id": "poseidon", "name": "Poseidon", "title": "Lord of the Seas", "style": "Long-reach heavy",
		"tagline": "Earth-shaker, wave-maker, grudge-holder.",
		"quotes": ["Consider yourself washed up.", "The sea always wins. I am the sea."],
		"hp": 1030, "walk": 3.4, "dash": 9.5, "jump": 20.5, "jump_x": 5.2,
		"normals": Moves.normals("thrust", 1.02, 1),
		"specials": {
			"sn": Moves.projectile("Tidal Wave", {"startup": 16, "recovery": 34,
				"proj": {"kind": "wave", "vx": 6.5, "w": 76.0, "h": 112.0, "anchor": "ground", "life": 150, "dmg": 54}}),
			"sf": Moves.lunge("Trident Rush", {"dmg": 92, "box": Rect2(40, -218, 200, 64)}),
			"sd": Moves.custom("Earthshaker", {"anim": "quake", "startup": 18, "active": 4, "recovery": 26, "dmg": 80, "chip": 10,
				"level": "low", "kd": true, "box": Rect2(30, -70, 290, 70), "hitstun": 20, "blockstun": 15, "stop": 10, "ai": "rush"}),
		},
		"super": Moves.super_move(Moves.projectile("Maelstrom", {"startup": 12, "recovery": 40,
			"proj": {"kind": "bigwave", "vx": 9.0, "w": 160.0, "h": 240.0, "anchor": "ground", "life": 160,
				"hits": 5, "gap": 5, "dmg": 56, "chip": 6, "pierce": true}})),
	})
	_add({
		"id": "hades", "name": "Hades", "title": "Lord of the Underworld", "style": "Trickster",
		"tagline": "Not evil. Just very, very busy.",
		"quotes": ["See you soon. Everyone does.", "I've added you to the list. It's a long list."],
		"hp": 990, "walk": 4.0, "dash": 10.5, "jump": 21.5, "jump_x": 6.0,
		"normals": Moves.normals("thrust", 1.0, 0),
		"specials": {
			"sn": Moves.projectile("Soul Fire", {"recovery": 24, "proj": {"kind": "soul", "vx": 5.5, "life": 200, "dmg": 60, "w": 54.0, "h": 54.0}}),
			"sf": Moves.teleport("Shadow Step"),
			"sd": Moves.remote("Grasp of the Dead", {"proj": {"kind": "hands", "delay": 20, "w": 96.0, "h": 150.0, "dmg": 70,
				"level": "low", "launch": Vector2(1.5, -13.0)}}),
		},
		"super": Moves.super_move(Moves.remote("Gates of Tartarus", {"startup": 10, "recovery": 40,
			"proj": {"kind": "pillar", "delay": 8, "w": 160.0, "hits": 6, "gap": 4, "life": 30, "dmg": 50, "chip": 5}})),
	})
	_add({
		"id": "athena", "name": "Athena", "title": "Goddess of Wisdom", "style": "Defensive all-rounder",
		"tagline": "Already read your strategy. Left notes in the margins.",
		"quotes": ["I planned this before you woke up.", "Wisdom is knowing you'd lose. Strategy is making sure."],
		"hp": 970, "walk": 4.2, "dash": 11.0, "jump": 21.5, "jump_x": 6.0,
		"normals": Moves.normals("thrust", 1.0, 0),
		"specials": {
			"sn": Moves.projectile("Javelin of Wisdom", {"startup": 14, "recovery": 30, "proj": {"kind": "spear", "vx": 12.5, "w": 96.0, "h": 22.0, "dmg": 50}}),
			"sf": Moves.lunge("Aegis Charge", {"anim": "tackle", "startup": 9, "dmg": 80, "pinv": [1, 22], "box": Rect2(30, -232, 112, 152)}),
			"sd": Moves.uppercut("Owl's Ascent", {"dmg": 90}),
		},
		"super": Moves.super_move(Moves.flurry("Aegis Storm", {"startup": 6, "active": 34, "hits": 8, "gap": 4, "dmg": 40, "chip": 4,
			"dash": [6, 40, 4.0], "recovery": 24, "box": Rect2(40, -240, 195, 112)})),
	})
	_add({
		"id": "ares", "name": "Ares", "title": "God of War", "style": "Rushdown bruiser",
		"tagline": "Has one hobby. You're looking at it.",
		"quotes": ["AGAIN!", "That wasn't a war. That was a warm-up."],
		"hp": 1050, "walk": 4.4, "dash": 11.5, "jump": 21.0, "jump_x": 6.0,
		"normals": Moves.normals("swing", 1.03, 0),
		"specials": {
			"sn": Moves.flurry("War Cry", {"dmg": 21}),
			"sf": Moves.lunge("Blood Rush", {"dmg": 88, "dash": [6, 18, 14.5]}),
			"sd": Moves.custom("Skull Splitter", {"anim": "slam", "startup": 20, "active": 4, "recovery": 22, "dmg": 105, "chip": 12,
				"level": "high", "kd": true, "box": Rect2(30, -290, 150, 290), "hitstun": 22, "blockstun": 17, "stop": 11, "ai": "close"}),
		},
		"super": Moves.super_move(Moves.flurry("God of War", {"startup": 6, "active": 42, "hits": 10, "gap": 4, "dmg": 34, "chip": 4,
			"dash": [6, 48, 4.5], "recovery": 24})),
	})
	_add({
		"id": "artemis", "name": "Artemis", "title": "Goddess of the Hunt", "style": "Agile zoner",
		"tagline": "Never misses. Don't make it weird.",
		"quotes": ["You ran well. For prey.", "The moon saw everything."],
		"hp": 980, "walk": 4.9, "dash": 12.0, "jump": 22.5, "jump_x": 6.6,
		"normals": Moves.normals("fist", 1.0, -1),
		"specials": {
			"sn": Moves.projectile("Moonshot", {"anim": "bow", "startup": 12, "recovery": 22,
				"proj": {"kind": "arrow", "vx": 18.0, "w": 70.0, "h": 16.0, "dmg": 54, "ox": 100.0, "oy": -205.0}}),
			"sf": Moves.uppercut("Crescent Kick", {"dmg": 88, "box": Rect2(15, -292, 112, 232)}),
			"sd": Moves.projectile("Arrow Volley", {"anim": "bow", "startup": 18, "recovery": 30,
				"proj": {"kind": "arrow", "spread": [[7.0, -15.0], [9.5, -15.0], [12.0, -15.0]], "g": 0.75, "dmg": 38,
					"w": 40.0, "h": 40.0, "oy": -230.0, "life": 120}}),
			"sa": Moves.projectile("Rain Arrow", {"anim": "airbow", "air": 1, "startup": 10, "recovery": 40, "land_rec": 8, "ai": "air",
				"proj": {"kind": "arrow", "vx": 13.0, "vy": 9.5, "w": 50.0, "h": 40.0, "dmg": 44, "oy": -150.0}}),
		},
		"super": Moves.super_move(Moves.projectile("Wild Hunt", {"anim": "bow", "startup": 10, "recovery": 36,
			"proj": {"kind": "moonbeam", "vx": 13.0, "w": 220.0, "h": 50.0, "hits": 6, "gap": 3, "dmg": 48, "chip": 5,
				"pierce": true, "oy": -205.0}})),
	})
	_add({
		"id": "hermes", "name": "Hermes", "title": "Messenger of the Gods", "style": "Speedster",
		"tagline": "Fastest god alive. Yes, he'll tell you.",
		"quotes": ["Message delivered.", "Sorry, were you still fighting? I finished."],
		"hp": 970, "walk": 5.6, "dash": 13.5, "jump": 22.5, "jump_x": 7.2,
		"normals": Moves.normals("swing", 0.96, -1),
		"specials": {
			"sn": Moves.projectile("Caduceus Toss", {"startup": 11, "recovery": 20,
				"proj": {"kind": "caduceus", "vx": 12.0, "dmg": 46, "w": 50.0, "h": 50.0, "hitstun": 15}}),
			"sf": Moves.flurry("Lightning Legs", {"anim": "legs", "hits": 6, "dmg": 19, "active": 24, "box": Rect2(40, -232, 142, 182)}),
			"sd": Moves.teleport("Wind Step", {"startup": 9, "recovery": 12, "inv": [4, 13],
				"teleport": {"frame": 9, "mode": "dx", "dist": 270.0}}),
			"sa": Moves.dive("Sky Dive", {"dmg": 56}),
		},
		"super": Moves.super_move(Moves.flurry("Speed of Thought", {"anim": "legs", "startup": 5, "active": 48, "hits": 12, "gap": 4,
			"dmg": 26, "chip": 3, "dash": [5, 52, 5.0], "recovery": 22, "box": Rect2(40, -240, 152, 200)})),
	})
	_add({
		"id": "achilles", "name": "Achilles", "title": "Hero of Troy", "style": "All-rounder",
		"tagline": "Nearly invincible. Don't ask about the heel.",
		"quotes": ["Sing of THAT, Muse.", "Mind the heel. Kidding - you never got close."],
		"hp": 980, "walk": 4.3, "dash": 11.0, "jump": 21.5, "jump_x": 6.2,
		"traits": ["heel"],  # low attacks hurt him a little more
		"normals": Moves.normals("thrust", 1.0, 0),
		"specials": {
			"sn": Moves.projectile("Spear of Peleus", {"startup": 15, "recovery": 30, "proj": {"kind": "spear", "vx": 12.5, "w": 96.0, "h": 22.0, "dmg": 56}}),
			"sf": Moves.uppercut("Rising Fury", {"dmg": 100}),
			"sd": Moves.lunge("Myrmidon Charge", {"dmg": 88}),
		},
		"super": Moves.super_move(Moves.flurry("Wrath of Achilles", {"startup": 6, "active": 36, "hits": 9, "gap": 4, "dmg": 37, "chip": 4,
			"dash": [6, 42, 4.2], "recovery": 24, "box": Rect2(40, -236, 200, 100)})),
	})
	_add({
		"id": "odysseus", "name": "Odysseus", "title": "King of Ithaca", "style": "Trickster",
		"tagline": "Ten-year commute. Still made it home.",
		"quotes": ["Who beat you? Nobody.", "I had a plan. I always have a plan."],
		"hp": 1040, "walk": 4.3, "dash": 11.0, "jump": 21.5, "jump_x": 6.2,
		"normals": Moves.normals("swing", 1.04, 0),
		"specials": {
			"sn": Moves.projectile("Great Bow", {"anim": "bow", "weapon": "bow", "startup": 14, "recovery": 22,
				"proj": {"kind": "arrow", "vx": 17.0, "w": 70.0, "h": 16.0, "dmg": 60, "ox": 100.0, "oy": -205.0}}),
			"sf": Moves.projectile("Trojan Gift", {"startup": 18, "recovery": 26,
				"proj": {"kind": "horse", "vx": 4.6, "w": 110.0, "h": 120.0, "anchor": "ground", "life": 170,
					"hits": 2, "gap": 14, "dmg": 46, "ox": 120.0}}),
			"sd": Moves.teleport("Nobody's Here", {"startup": 11, "recovery": 14, "inv": [4, 15],
				"teleport": {"frame": 11, "mode": "dx", "dist": 230.0}}),
		},
		"super": Moves.super_move(Moves.projectile("Arrow Through the Axes", {"anim": "bow", "weapon": "bow", "startup": 10, "recovery": 36,
			"proj": {"kind": "megarrow", "vx": 13.0, "w": 220.0, "h": 44.0, "hits": 6, "gap": 3, "dmg": 49, "chip": 5,
				"pierce": true, "oy": -205.0}})),
	})
	_add({
		"id": "jason", "name": "Jason", "title": "Captain of the Argo", "style": "Balanced swordsman",
		"tagline": "Great at quests. Outsources the hard parts.",
		"quotes": ["Fleece: golden. Victory: also golden.", "The Argonauts did most of it, honestly."],
		"hp": 980, "walk": 4.4, "dash": 11.0, "jump": 21.5, "jump_x": 6.2,
		"normals": Moves.normals("swing", 1.0, 0),
		"specials": {
			"sn": Moves.remote("Dragon's Teeth", {"anim": "cast",
				"proj": {"kind": "spartoi", "delay": 22, "w": 100.0, "h": 230.0, "dmg": 66, "min": 290.0, "max": 290.0}}),
			"sf": Moves.lunge("Argo Slash", {"dmg": 88}),
			"sd": Moves.uppercut("Golden Rise", {"dmg": 98}),
		},
		"super": Moves.super_move(Moves.projectile("Argonauts, Ahoy!", {"anim": "summon", "startup": 12, "recovery": 40,
			"proj": {"kind": "argo", "vx": 10.0, "w": 260.0, "h": 200.0, "anchor": "ground", "life": 150,
				"hits": 5, "gap": 5, "dmg": 57, "chip": 6, "pierce": true, "ox": -200.0}})),
	})
	_add({
		"id": "atalanta", "name": "Atalanta", "title": "The Swift Huntress", "style": "Rushdown",
		"tagline": "Outran every suitor. Only stops for apples.",
		"quotes": ["Too slow. They always are.", "Was that the whole race?"],
		"hp": 1000, "walk": 5.2, "dash": 13.0, "jump": 22.5, "jump_x": 7.0,
		"normals": Moves.normals("fist", 1.04, -1),
		"specials": {
			"sn": Moves.projectile("Golden Apple", {"startup": 11, "recovery": 22,
				"proj": {"kind": "apple", "vx": 9.0, "vy": -9.0, "g": 0.6, "dmg": 50, "w": 36.0, "h": 36.0, "oy": -200.0, "life": 120}}),
			"sf": Moves.lunge("Calydonian Rush", {"startup": 8, "dmg": 86, "dash": [5, 16, 14.0], "recovery": 19, "box": Rect2(40, -200, 150, 90)}),
			"sd": Moves.uppercut("Arcadian Wheel", {"dmg": 90}),
			"sa": Moves.dive("Falcon Dive"),
		},
		"super": Moves.super_move(Moves.flurry("Footrace Fury", {"anim": "legs", "startup": 5, "active": 44, "hits": 11, "gap": 4,
			"dmg": 29, "chip": 3, "dash": [5, 48, 5.0], "recovery": 22, "box": Rect2(40, -240, 152, 200)})),
	})
	_add({
		"id": "heracles", "name": "Heracles", "title": "Strongest Man Alive", "style": "Grappler",
		"tagline": "Twelve labors down. You're number thirteen.",
		"quotes": ["Easier than the hydra.", "Add it to the list of labors."],
		"hp": 1120, "walk": 3.3, "dash": 9.5, "jump": 20.0, "jump_x": 5.0,
		"normals": Moves.normals("swing", 1.16, 1),
		"specials": {
			"sn": Moves.projectile("Boulder Toss", {"startup": 20, "recovery": 28,
				"proj": {"kind": "boulder", "vx": 8.0, "vy": -11.0, "g": 0.6, "dmg": 84, "chip": 12, "w": 70.0, "h": 70.0,
					"oy": -230.0, "life": 120, "kd": true, "hitstun": 22}}),
			"sf": Moves.flurry("Labor Lariat", {"anim": "spin", "startup": 9, "active": 21, "hits": 3, "gap": 7, "dmg": 36, "chip": 5,
				"dash": [9, 30, 5.0], "box": Rect2(-120, -250, 240, 130), "recovery": 20, "push": 3.0, "stop": 6, "ai": "rush"}),
			"sd": Moves.command_grab("Lion Tamer", {"grab": {"range": 80.0, "dmg": 160}}),
		},
		"super": Moves.super_move(Moves.command_grab("The Thirteenth Labor", {"startup": 5, "recovery": 40,
			"grab": {"range": 110.0, "dmg": 360}})),
	})
	_add({
		"id": "hippolyta", "name": "Hippolyta", "title": "Queen of the Amazons", "style": "Aggressive mid-range",
		"tagline": "Wears the war-belt. Earned it twice.",
		"quotes": ["Bow to your queen.", "The Amazons send their regards."],
		"hp": 1000, "walk": 4.5, "dash": 11.5, "jump": 21.5, "jump_x": 6.3,
		"normals": Moves.normals("swing", 1.04, 0),
		"specials": {
			"sn": Moves.projectile("Labrys Throw", {"proj": {"kind": "axe", "vx": 10.5, "dmg": 60, "w": 64.0, "h": 64.0}}),
			"sf": Moves.lunge("War Queen's Charge", {"dmg": 90}),
			"sd": Moves.flurry("Amazon Cyclone", {"anim": "spin", "startup": 7, "active": 20, "hits": 4, "gap": 5, "dmg": 25,
				"box": Rect2(-125, -262, 250, 150), "dash": [7, 27, 3.0], "recovery": 20, "ai": "aa"}),
		},
		"super": Moves.super_move(Moves.flurry("Queen's Fury", {"anim": "spin", "startup": 6, "active": 40, "hits": 9, "gap": 4, "dmg": 37,
			"chip": 4, "dash": [6, 46, 5.5], "box": Rect2(-135, -270, 270, 170), "recovery": 24})),
	})
	_add({
		"id": "medusa", "name": "Medusa", "title": "The Gorgon", "style": "Zoner",
		"tagline": "Bad hair day, every day. Don't stare.",
		"quotes": ["Rock solid performance.", "You'd make a lovely statue."],
		"hp": 1040, "walk": 4.2, "dash": 10.5, "jump": 21.5, "jump_x": 6.0,
		"normals": Moves.normals("swing", 1.06, -1),
		"specials": {
			"sn": Moves.beam("Stone Gaze", {"startup": 12, "recovery": 22, "dmg": 60, "hitstun": 50}),
			"sf": Moves.lunge("Serpent Strike", {"anim": "sweep", "level": "low", "dmg": 80, "box": Rect2(40, -60, 150, 60), "dash": [5, 17, 12.0]}),
			"sd": Moves.projectile("Venom Spit", {"startup": 12, "recovery": 20,
				"proj": {"kind": "venom", "vx": 8.5, "vy": -8.0, "g": 0.55, "dmg": 58, "w": 44.0, "h": 44.0, "oy": -225.0, "life": 120}}),
		},
		"super": Moves.super_move(Moves.beam("Gorgon's Curse", {"startup": 10, "active": 24, "recovery": 34, "hits": 6, "gap": 4, "dmg": 47,
			"chip": 5, "hitstun": 20, "box": Rect2(40, -262, 900, 150)})),
	})
