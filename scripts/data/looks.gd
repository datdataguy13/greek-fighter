class_name Looks
extends RefCounted

# What each fighter looks like. Pure art data, read by Rig; gameplay lives in
# roster.gd. See rig.gd for what each key does.

const L := {
	"zeus": {
		"skin": Color("e8b085"), "hair": Color("f2f2f2"), "hair_style": "curly", "beard": "curly",
		"headgear": "laurel", "gear_col": Color("e8c14a"),
		"outfit": "bare", "skirt_col": Color("f4f1e6"), "trim": Color("e2b93b"), "sash": Color("f4f1e6"),
		"weapon": "bolt", "arms": "bracer", "metal": Color("e8c14a"), "legs": "sandals",
		"bulk": 1.2, "scale": 1.08,
	},
	"poseidon": {
		"skin": Color("c98a5e"), "hair": Color("1f6f7a"), "hair_style": "long", "beard": "curly", "beard_col": Color("2a8a94"),
		"headgear": "crown", "gear_col": Color("e8c14a"), "crest": Color("4fd0e0"),
		"outfit": "bare", "skirt_col": Color("1f7f8a"), "trim": Color("7fe0d0"),
		"weapon": "trident", "weapon_col": Color("e8c14a"), "arms": "bracer", "metal": Color("e8c14a"), "legs": "sandals",
		"bulk": 1.22, "scale": 1.1,
	},
	"hades": {
		"skin": Color("cfc8dc"), "hair": Color("1c1820"), "hair_style": "long", "beard": "short",
		"headgear": "crown", "gear_col": Color("4a4458"), "crest": Color("b04adf"), "eye_col": Color("7fe8ff"),
		"outfit": "chiton", "cloth": Color("2c2140"), "trim": Color("8a5ad0"),
		"cape": Color("1c1528"), "cape_trim": Color("8a5ad0"),
		"weapon": "bident", "weapon_col": Color("8a8a9a"), "legs": "boots", "leg_col": Color("2a2030"),
		"bulk": 1.02, "scale": 1.05,
	},
	"athena": {
		"female": true, "skin": Color("e9b98d"), "hair": Color("6a4426"), "hair_style": "long",
		"headgear": "helm", "gear_col": Color("e8c14a"), "crest": Color("3a6ad0"),
		"outfit": "armor", "metal": Color("e8c14a"), "skirt_col": Color("f4f1e6"), "trim": Color("3a6ad0"), "skirt": 0.8,
		"weapon": "spear", "shield": "gorgon", "shield_col": Color("3a6ad0"),
		"legs": "greaves", "arms": "bracer", "bulk": 0.98, "scale": 1.0,
	},
	"ares": {
		"skin": Color("b9764f"), "headgear": "corinthian", "gear_col": Color("5a4a42"), "crest": Color("c8201e"),
		"eye_col": Color("ff4a2a"),
		"outfit": "armor", "metal": Color("4a3c3c"), "skirt_col": Color("8a1a1a"), "trim": Color("c8201e"),
		"cape": Color("8a1a1a"), "weapon": "kopis", "weapon_col": Color("c8ccd6"),
		"legs": "greaves", "leg_col": Color("4a3c3c"), "arms": "bracer", "arm_col": Color("4a3c3c"),
		"pauldron": true, "bulk": 1.25, "scale": 1.08,
	},
	"artemis": {
		"female": true, "skin": Color("e5ad80"), "hair": Color("a8502a"), "hair_style": "ponytail",
		"headgear": "diadem", "gear_col": Color("d8dde8"),
		"outfit": "chiton", "cloth": Color("2f7a4f"), "trim": Color("d8dde8"), "one_shoulder": true, "skirt": 0.5,
		"weapon": "bow", "quiver": true, "legs": "boots", "leg_col": Color("6a4a2a"),
		"arms": "wrap", "arm_col": Color("6a4a2a"), "bulk": 0.86, "scale": 0.95,
	},
	"hermes": {
		"skin": Color("ebb58a"), "hair": Color("d8b04a"), "hair_style": "short",
		"headgear": "wingcap", "gear_col": Color("e8c14a"),
		"outfit": "chiton", "cloth": Color("eef4ff"), "trim": Color("4a9ae0"), "one_shoulder": true, "skirt": 0.45,
		"cape": Color("4a9ae0"), "cape_len": 74.0,
		"weapon": "caduceus", "legs": "wings", "leg_col": Color("e8c14a"), "bulk": 0.86, "scale": 0.97,
	},
	"achilles": {
		"skin": Color("e3a878"), "hair": Color("e0b84a"), "hair_style": "long",
		"headgear": "helm", "gear_col": Color("c9973a"), "crest": Color("c8201e"),
		"outfit": "armor", "metal": Color("c9973a"), "skirt_col": Color("a8201e"), "trim": Color("e8d8a0"),
		"cape": Color("a8201e"), "cape_len": 92.0,
		"weapon": "spear", "shield": "sun", "shield_col": Color("2a2a34"),
		"legs": "greaves", "arms": "bracer", "bulk": 1.1, "scale": 1.03,
	},
	"odysseus": {
		"skin": Color("d9a071"), "hair": Color("4a3222"), "hair_style": "short", "beard": "short",
		"headgear": "pilos", "gear_col": Color("b8a888"),
		"outfit": "chiton", "cloth": Color("7a6a3a"), "trim": Color("3a6a9a"), "one_shoulder": true,
		"weapon": "sword", "quiver": true, "arms": "wrap", "arm_col": Color("5a4630"), "legs": "sandals",
		"bulk": 1.02, "scale": 1.0,
	},
	"jason": {
		"skin": Color("e6b080"), "hair": Color("5a3a22"), "hair_style": "curly",
		"outfit": "armor", "metal": Color("e8e4d8"), "skirt_col": Color("3a6ad0"), "trim": Color("3a6ad0"),
		"cape": Color("e8b830"), "fleece": true, "cape_len": 112.0,
		"weapon": "sword", "legs": "greaves", "leg_col": Color("c9973a"), "arms": "bracer", "arm_col": Color("c9973a"),
		"bulk": 1.0, "scale": 1.0,
	},
	"atalanta": {
		"female": true, "skin": Color("d99a6c"), "hair": Color("8a2a1a"), "hair_style": "ponytail",
		"headgear": "headband", "crest": Color("f0e8d8"),
		"outfit": "chiton", "cloth": Color("e07a2a"), "trim": Color("f0e8d8"), "one_shoulder": true, "skirt": 0.42,
		"weapon": "none", "arms": "wrap", "arm_col": Color("f0e8d8"), "legs": "sandals",
		"bulk": 0.9, "scale": 0.97,
	},
	"heracles": {
		"skin": Color("c98d62"), "hair": Color("3a2616"), "beard": "short",
		"headgear": "lion", "gear_col": Color("d0a050"),
		"outfit": "bare", "skirt_col": Color("c09048"), "trim": Color("7a4a2a"),
		"cape": Color("c09048"), "cape_len": 104.0,
		"weapon": "club", "arms": "wrap", "arm_col": Color("7a4a2a"), "legs": "sandals",
		"bulk": 1.42, "scale": 1.14,
	},
	"hippolyta": {
		"female": true, "skin": Color("c68a5f"), "hair": Color("1c1418"), "hair_style": "braid",
		"headgear": "diadem", "gear_col": Color("e8c14a"),
		"outfit": "armor", "metal": Color("b8823a"), "skirt_col": Color("6a2a8a"), "trim": Color("e8c14a"), "belt": Color("e8c14a"),
		"weapon": "axe", "legs": "greaves", "arms": "bracer", "pauldron": true, "bulk": 1.02, "scale": 1.03,
	},
	"medusa": {
		"female": true, "skin": Color("9fc7a0"), "hair": Color("3f8a4f"), "headgear": "snakes",
		"eye_col": Color("ffe14a"),
		"outfit": "chiton", "cloth": Color("2a5a5a"), "trim": Color("d8b84a"), "skirt": 0.85,
		"weapon": "none", "arms": "bracer", "arm_col": Color("d8b84a"), "legs": "sandals", "leg_col": Color("d8b84a"),
		"bulk": 0.92, "scale": 1.0,
	},
}

const ORDER := ["zeus", "poseidon", "hades", "athena", "ares", "artemis", "hermes",
	"achilles", "odysseus", "jason", "atalanta", "heracles", "hippolyta", "medusa"]
