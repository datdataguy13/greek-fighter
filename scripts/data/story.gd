class_name Story
extends RefCounted

# Story mode: pick a fighter and beat ten opponents across the arenas.
# Fights 1-8 are drawn at random from the rest of the roster, fight 9 is the
# fighter's rival and fight 10 is their final battle. The CPU gets tougher as
# the journey goes on, and a little easier each time you use a continue.
#
# Per fighter:
#   home         the arenas they are fought in (first choice, second choice)
#   taunts       what they say before a fight when they are the opponent
#   tip          advice shown to the player who is about to face them
#   intro        the opening of their own journey
#   rival, boss  who they meet in fights 9 and 10, and what those two say
#   ending       how their journey ends

const FIGHTS := 10
# CPU level at the first and the last fight, for EASY / NORMAL / HARD.
const RAMP := [[-0.25, 0.35], [0.1, 0.8], [0.45, 1.0]]
const CONTINUE_EASE := 0.1

const DATA := {
	"zeus": {
		"home": ["olympus", "acropolis"],
		"taunts": ["You dare climb MY mountain? Bold. Wrong, but bold.",
			"I have a thunderbolt with your name on it. I carved it myself."],
		"tip": "Zeus throws thunder from across the arena. Jump the bolts and stay close.",
		"intro": ["A rumor has reached Olympus: the mortals think the king of the gods has gone soft.",
			"Zeus has cancelled his afternoon, polished his best thunderbolt and gone down the mountain.",
			"Ten challengers. One point to prove. Loudly."],
		"rival": "poseidon", "rival_line": "The sky was MY first choice, little brother. We drew lots. I want a recount.",
		"boss": "hades", "boss_line": "You got the sky. Poseidon got the sea. I got a basement. Let's talk about that.",
		"ending_title": "King of Everything (Terms Apply)",
		"ending": ["Ten challengers, ten thunderbolts. Nobody calls Zeus soft any more.",
			"He returned to Olympus in triumph, already rehearsing the story for the feast.",
			"Hera was waiting on the throne. She had heard about ALL of it.",
			"The king of the gods slept on a cloud that night. It was still a very nice cloud."],
	},
	"poseidon": {
		"home": ["argo", "cyclops"],
		"taunts": ["Hope you can swim. Actually, I hope you can't.",
			"The tide comes in. You go out."],
		"tip": "His trident reaches a long way. Block the rush, then hit back.",
		"intro": ["Athens once chose an olive tree over a perfectly good saltwater spring. Poseidon has not let it go.",
			"Now he is leaving the sea to remind the world who shakes the earth.",
			"Ten opponents stand between him and the top of Olympus."],
		"rival": "athena", "rival_line": "Still sulking about Athens, uncle? It was a salt spring. Nobody could drink it.",
		"boss": "zeus", "boss_line": "You want my throne? You'd only get it wet. Go home, brother.",
		"ending_title": "Lord of the Seas and, Briefly, the Sky",
		"ending": ["Poseidon sat on the throne of Olympus for one whole afternoon.",
			"It was dry. It was quiet. There was not a single dolphin.",
			"He gave the sky back, went home, and flooded Athens just a little on the way.",
			"The Athenians named a very small fountain after him. He counts it as a win."],
	},
	"hades": {
		"home": ["styx", "labyrinth"],
		"taunts": ["Welcome! Mind the dog. All three of him.",
			"Everyone ends up at my place eventually. You're just early."],
		"tip": "Hades vanishes and reappears behind you. Be ready to turn and block.",
		"intro": ["For the first time in three thousand years, Hades has taken a day off.",
			"He has a short list of people to visit and a very long memory.",
			"Ten fights, then home before anyone notices the paperwork piling up."],
		"rival": "heracles", "rival_line": "Is this about the dog? I brought him back! Mostly in one piece!",
		"boss": "zeus", "boss_line": "Brother! You never visit. ...Oh. It's THAT kind of visit.",
		"ending_title": "A Well-Earned Holiday",
		"ending": ["Hades stood on top of Olympus, victorious. It was bright, loud and smelled of ambrosia.",
			"He hated it.",
			"So he went home, where Persephone had run the underworld better than he ever had.",
			"He now takes one day off every year. Cerberus gets three treats."],
	},
	"athena": {
		"home": ["acropolis", "troy"],
		"taunts": ["I've already read how this ends. Spoiler: I win.",
			"Come along. I'll try to make this educational."],
		"tip": "Athena waits for you to make a mistake. Don't jump in carelessly. Throws beat her guard.",
		"intro": ["Athena has written a 400-page plan for a peaceful, well-organized Greece.",
			"Nobody has read it. So she is going to explain it in person.",
			"Ten opponents. Ten lessons. There will be a quiz."],
		"rival": "poseidon", "rival_line": "Niece. Your city still smells of olives. I'm here about the recount.",
		"boss": "ares", "boss_line": "You think. I smash. Let's find out which one works, sister.",
		"ending_title": "Class Dismissed",
		"ending": ["Ares was last seen face-down in the sand, finally quiet.",
			"With every god and hero out of arguments, Athena's plan passed without a single vote against.",
			"She opened a school on the Acropolis. Fighting is on the timetable, right after philosophy.",
			"Her owl grades the homework. The owl is a harsh marker."],
	},
	"ares": {
		"home": ["troy", "styx"],
		"taunts": ["FINALLY. Someone to hit!",
			"Don't block. Blocking is for cowards and Athena."],
		"tip": "Ares never stops attacking. Block patiently, then punish his big swings.",
		"intro": ["Greece is at peace. Ares is BORED.",
			"Somewhere out there are ten people who haven't been punched yet.",
			"He intends to fix that before lunch."],
		"rival": "athena", "rival_line": "Brother. I've drawn a diagram of how this fight goes. You're the one lying down.",
		"boss": "zeus", "boss_line": "Son, we've talked about this. Use your words. ...No? Fine. Thunder it is.",
		"ending_title": "The Last Fight",
		"ending": ["Ares won. Then he looked around for the next fight, and there wasn't one.",
			"He had beaten everybody. It was the worst day of his life.",
			"So he challenged his own reflection in a bronze shield. It was a draw.",
			"They have a rematch every Tuesday."],
	},
	"artemis": {
		"home": ["delphi", "olympus"],
		"taunts": ["You're standing in my forest. You have until the arrow lands to leave.",
			"I've tracked wild boars that were quieter than you."],
		"tip": "Arrows come from every angle. Get in close, where a bow is no use.",
		"intro": ["Someone has been tramping through Artemis's sacred forest. Loudly. With a club.",
			"The trail leads right across Greece.",
			"Ten trespassers are about to learn what the 'keep out' sign was for."],
		"rival": "atalanta", "rival_line": "You taught me everything, my lady. Let me show you I was listening.",
		"boss": "heracles", "boss_line": "The golden deer? I only borrowed it! It was a labor! I had a note from the king!",
		"ending_title": "Peace and Quiet",
		"ending": ["Heracles gave back the golden hind, with a written apology. The spelling was terrible.",
			"Artemis asked the gods for one prize: a forest where nobody is allowed to bother her.",
			"Zeus agreed at once. He had seen what happened to the others.",
			"The moon rose, the hounds ran, and the woods were silent at last."],
	},
	"hermes": {
		"home": ["olympus", "delphi"],
		"taunts": ["Try to keep up. No, really, try. It's funnier.",
			"I've got six more deliveries after this, so let's be quick."],
		"tip": "The fastest fighter of all, but fragile. One solid combo hurts him badly.",
		"intro": ["Hermes has ten urgent deliveries for ten very grumpy people.",
			"Every one of the packages is a punch.",
			"He plans to be done by noon. He has a reputation to keep."],
		"rival": "atalanta", "rival_line": "They call you the fastest alive. I've never lost a race. One of us is about to be wrong.",
		"boss": "zeus", "boss_line": "Hermes! About time. Where's my... what do you mean, 'this message is from you'?",
		"ending_title": "Signed, Sealed, Delivered",
		"ending": ["The last message was for Zeus himself. It read: 'I would like one day off. Please.'",
			"Zeus, flat on his back, was in no position to say no.",
			"Hermes spent his very first holiday doing the thing he loves most.",
			"He ran around the whole world. Twice. Just for fun."],
	},
	"achilles": {
		"home": ["troy", "styx"],
		"taunts": ["They'll sing songs about this fight. Short ones.",
			"Take your best shot. Anywhere but the heel."],
		"tip": "Strong everywhere, with one weak spot: low attacks hurt Achilles more.",
		"intro": ["Achilles was promised a choice: a long quiet life, or a short one full of glory.",
			"He has spotted a loophole. Win so much that the poets can't keep up.",
			"Ten fights should about do it."],
		"rival": "hippolyta", "rival_line": "The great Achilles. My Amazons have a bet on how long you'll last. I took 'not very'.",
		"boss": "ares", "boss_line": "A mortal who loves war as much as I do? I'm almost proud. Now show me that heel.",
		"ending_title": "A Long Life and the Glory Too",
		"ending": ["Achilles had beaten the god of war. The Fates tore up his prophecy and started again.",
			"Homer needed twenty-four extra books to fit it all in.",
			"And the heel? Hephaestus forged him one small bronze sandal-guard.",
			"It is the most famous piece of armor in Greece. He never takes it off."],
	},
	"odysseus": {
		"home": ["cyclops", "argo"],
		"taunts": ["I've outsmarted a cyclops, a witch and two sea monsters. What are you, exactly?",
			"I got you a present. It's a horse. Don't look inside."],
		"tip": "Watch for the wooden horse and his vanishing trick. Stay unpredictable.",
		"intro": ["Odysseus set sail for home ten years ago. He is, in fairness, quite close now.",
			"Just ten small detours stand between him and Ithaca.",
			"He has a plan. He always has a plan."],
		"rival": "achilles", "rival_line": "The horse was YOUR idea? Nine years I fought at those walls. We could have done the horse on day one!",
		"boss": "poseidon", "boss_line": "You blinded my son, bragged about it, and told him your ADDRESS. The sea remembers, 'Nobody'.",
		"ending_title": "Home at Last",
		"ending": ["The sea went calm. For the first time in twenty years, nothing was trying to eat him.",
			"Odysseus sailed into Ithaca at sunset. Penelope was waiting on the dock.",
			"'You're late,' she said. 'Where have you been?'",
			"'It's a long story,' said Odysseus. It was. It is twenty-four books long."],
	},
	"jason": {
		"home": ["argo", "delphi"],
		"taunts": ["Normally the crew would handle this. Today you get the captain.",
			"Mind the fleece. It's dry-clean only."],
		"tip": "A solid swordsman whose warriors spring up under your feet. Keep moving.",
		"intro": ["Jason has the Golden Fleece. What he doesn't have is anyone who believes he got it himself.",
			"So the captain of the Argo is setting out again, this time without the crew.",
			"Ten fights, all on his own. Probably."],
		"rival": "heracles", "rival_line": "Little captain! You sailed off without me at Mysia. I had to WALK home!",
		"boss": "medusa", "boss_line": "The dragon that guards the fleece has the day off. I'm covering. Look at me when I'm talking to you.",
		"ending_title": "Captain, My Captain",
		"ending": ["Jason won all ten fights himself, and he will be telling people about it for years.",
			"The Argonauts threw him a feast on the deck of the Argo.",
			"In his speech he thanked the crew, the ship, and one very brave sheep.",
			"The Golden Fleece is now a rug in his cabin. It really ties the boat together."],
	},
	"atalanta": {
		"home": ["delphi", "acropolis"],
		"taunts": ["Catch me and you can hit me. Nobody ever has.",
			"I'll race you to your own defeat."],
		"tip": "She rushes in fast and dives from the air. Block standing up, then answer.",
		"intro": ["Atalanta has outrun every suitor, hunter and hero in Greece.",
			"She has run out of mortals. So now she is racing gods.",
			"Ten opponents, and not one of them is getting a head start."],
		"rival": "hermes", "rival_line": "Fastest mortal, meet fastest god. I'd give you a head start, but I'm not that nice.",
		"boss": "artemis", "boss_line": "You were raised by my bears and taught by my hunters. One last lesson, little one. Catch me.",
		"ending_title": "Still Undefeated",
		"ending": ["Artemis smiled, bowed, and handed over her own silver bow. The lesson was over.",
			"Hermes asked for a rematch. Then another. He is still asking.",
			"Atalanta started the first great footrace in Greece, open to anyone brave enough.",
			"First prize is a golden apple. Nobody else has ever won one."],
	},
	"heracles": {
		"home": ["labyrinth", "cyclops"],
		"taunts": ["I wrestled a lion before breakfast. You're more of a snack.",
			"Don't worry, I'll be gentle. That's a lie. I don't know how."],
		"tip": "Don't stand next to Heracles. His grabs go straight through a block. Jump or back away.",
		"intro": ["Twelve labors finished, and Heracles still isn't allowed on Mount Olympus.",
			"Apparently there is a thirteenth: prove he belongs among the gods.",
			"Ten opponents. He has brought the big club."],
		"rival": "hippolyta", "rival_line": "You. The belt thief. I've been hoping you would come back for the matching sandals.",
		"boss": "zeus", "boss_line": "My boy! Twelve labors! I'm so proud. But a seat on Olympus isn't given, son. Come and take it.",
		"ending_title": "A Seat on Olympus",
		"ending": ["His travels over and his opponents conquered, Heracles climbed Olympus one last time.",
			"Zeus picked himself up, laughed like thunder, and pulled up a chair beside his own.",
			"The strongest man alive had earned his place among the gods.",
			"His first act as a god? He asked what was for dinner. Then he ate all of it."],
	},
	"hippolyta": {
		"home": ["troy", "acropolis"],
		"taunts": ["Kneel now and save us both the time.",
			"An Amazon trains from the day she can walk. What did YOU do today?"],
		"tip": "Her axe controls the middle of the arena. Get right in close, or stay far out.",
		"intro": ["The war-belt of the Amazons has been stolen once. Hippolyta got it back.",
			"Now she is making sure that nobody in Greece ever tries again.",
			"Ten warriors are about to receive a royal visit."],
		"rival": "heracles", "rival_line": "Your majesty! About the belt. It was a labor! Nothing personal! ...You look upset.",
		"boss": "ares", "boss_line": "I gave you that belt, daughter. Show me you still deserve to wear it.",
		"ending_title": "Long Live the Queen",
		"ending": ["Ares sat in the dust and laughed. 'Keep it,' he said. 'It was always yours.'",
			"Hippolyta rode home to a feast that lasted nine days.",
			"Heracles sent an apology and a replacement belt. He had made it himself. It was awful.",
			"The Amazons use it to tie up the horses."],
	},
	"medusa": {
		"home": ["cyclops", "labyrinth"],
		"taunts": ["Look into my eyes. Go on. Everyone does, once.",
			"Ooh, a visitor! I have just the spot for you in the garden."],
		"tip": "Her gaze turns you to stone if it lands. Block it or jump over it, then rush in.",
		"intro": ["Medusa only ever wanted a quiet cave and no visitors.",
			"Instead, heroes keep turning up with swords and very shiny shields.",
			"It is time she had a word with the gods who started all this."],
		"rival": "poseidon", "rival_line": "Ah. Medusa. This is awkward. Lovely snakes, though. Are they new?",
		"boss": "athena", "boss_line": "You've come to ask me to lift the curse. Earn it. And yes, I brought a mirror.",
		"ending_title": "Rock Solid",
		"ending": ["Athena, impressed, offered to take the curse away. Medusa thought about it.",
			"Then she said no. She likes the snakes. They all have names now.",
			"She opened a sculpture garden by the sea instead. The statues are incredibly lifelike.",
			"Visitors are welcome. Sunglasses are provided at the door."],
	},
}


# Starts a journey for session["ids"][0].
static func begin(session: Dictionary, rng: RandomNumberGenerator) -> void:
	var me: String = session["ids"][0]
	var d: Dictionary = DATA[me]
	var pool: Array = []
	for id: String in Looks.ORDER:
		if id != me and id != d["rival"] and id != d["boss"]:
			pool.append(id)
	# Fisher-Yates with our own rng, so a seed gives the same journey.
	for i in range(pool.size() - 1, 0, -1):
		var k := rng.randi_range(0, i)
		var tmp: String = pool[i]
		pool[i] = pool[k]
		pool[k] = tmp
	var opponents: Array = pool.slice(0, FIGHTS - 2)
	opponents.append(d["rival"])
	opponents.append(d["boss"])

	# Each opponent is met on home ground; when two of them share an arena the
	# later one moves to their second choice, so the journey tours the map.
	var used := {}
	var ladder: Array = []
	for i in opponents.size():
		var home: Array = DATA[opponents[i]]["home"]
		var stage: String = home[0]
		if i < FIGHTS - 1 and used.get(home[0], 0) > used.get(home[1], 0):
			stage = home[1]
		used[stage] = used.get(stage, 0) + 1
		ladder.append({"opp": opponents[i], "stage": stage,
			"kind": "boss" if i == FIGHTS - 1 else ("rival" if i == FIGHTS - 2 else "")})
	session["story"] = {"me": me, "ladder": ladder, "idx": 0, "continues": 0, "tries": 0}


static func fight(session: Dictionary) -> Dictionary:
	var st: Dictionary = session["story"]
	return st["ladder"][mini(st["idx"], FIGHTS - 1)]


# Points the session at the current fight: who, where and how hard.
static func setup_fight(session: Dictionary) -> void:
	var st: Dictionary = session["story"]
	var f := fight(session)
	session["ids"] = [st["me"], f["opp"]]
	session["stage"] = f["stage"]
	var ramp: Array = RAMP[session["level_idx"]]
	var level := lerpf(ramp[0], ramp[1], st["idx"] / float(FIGHTS - 1))
	session["level"] = maxf(-0.5, level - CONTINUE_EASE * st["tries"])


# What the opponent says before the current fight.
static func quote(session: Dictionary) -> String:
	var st: Dictionary = session["story"]
	var f := fight(session)
	var mine: Dictionary = DATA[st["me"]]
	match f["kind"]:
		"rival":
			return mine["rival_line"]
		"boss":
			return mine["boss_line"]
	var taunts: Array = DATA[f["opp"]]["taunts"]
	return taunts[st["idx"] % taunts.size()]


static func heading(session: Dictionary) -> String:
	var st: Dictionary = session["story"]
	match fight(session)["kind"]:
		"rival":
			return "FIGHT 9 OF 10  -  THE RIVAL"
		"boss":
			return "THE FINAL BATTLE"
	return "FIGHT %d OF %d" % [st["idx"] + 1, FIGHTS]


# The player won the current fight. Returns true when the journey is over.
static func advance(session: Dictionary) -> bool:
	var st: Dictionary = session["story"]
	st["idx"] += 1
	st["tries"] = 0
	return st["idx"] >= FIGHTS


static func use_continue(session: Dictionary) -> void:
	var st: Dictionary = session["story"]
	st["continues"] += 1
	st["tries"] += 1
