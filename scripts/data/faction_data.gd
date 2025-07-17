# (This code is indented with tabs)
@tool
class_name FactionData
extends Resource

# --- The Preset Selector ---
enum FactionPreset {
	NONE,
	USA, RUSSIA, CHINA, UK, NORTH_KOREA, IRAN, INDIA, PAKISTAN, ISRAEL,
	FRANCE, GERMANY, ITALY, TURKEY, UKRAINE, JAPAN
}

# --- The Database ---
const PRESET_DATA = {
	1: { # USA
		"faction_name": "Freedom Inc.", "leader_name": "President Don T. Rump",
		"population": 100, "treasury": 200, "morale": 0.75, "ap": 3
	},
	2: { # RUSSIA
		"faction_name": "The Mother-lode", "leader_name": "President-for-Life Vlad 'The Impaler' Puttin",
		"population": 120, "treasury": 100, "morale": 0.85, "ap": 3
	},
	3: { # CHINA
		"faction_name": "The People's Social Harmony Co.", "leader_name": "Eternal Chairman Xi",
		"population": 150, "treasury": 175, "morale": 0.80, "ap": 4
	},
	4: { # UK
		"faction_name": "The Once-and-Future Empire", "leader_name": "Prime Minister 'Bojo' Jumbling",
		"population": 80, "treasury": 120, "morale": 0.85, "ap": 3
	},
	5: { # NORTH_KOREA
		"faction_name": "The Democratic People's Rocket Club", "leader_name": "Supreme Leader Kim Jong Fun",
		"population": 40, "treasury": 20, "morale": 0.90, "ap": 2
	},
	6: { # IRAN
		"faction_name": "The Divine Mandate", "leader_name": "Supreme Theocrat Ali Khameanie",
		"population": 70, "treasury": 60, "morale": 0.80, "ap": 3
	},
	7: { # INDIA
		"faction_name": "Bharat Unlimited", "leader_name": "Prime Minister Narinder 'The Tiger' Moody",
		"population": 160, "treasury": 120, "morale": 0.70, "ap": 3
	},
	8: { # PAKISTAN
		"faction_name": "The State of Pak-istan", "leader_name": "Generalissimo Al-Pocalypse",
		"population": 60, "treasury": 70, "morale": 0.75, "ap": 3
	},
	9: { # ISRAEL
		"faction_name": "The Iron Dome Corporation", "leader_name": "Prime Minister 'Bibi' Not-on-your-yahoo",
		"population": 30, "treasury": 150, "morale": 0.90, "ap": 4
	},
	# --- NEW FACTIONS ADDED BELOW ---
	10: { # FRANCE
		"faction_name": "La République Chic", "leader_name": "Président Emmanuel 'Le Grand' Macaron",
		"population": 85, "treasury": 140, "morale": 0.90, "ap": 4
	},
	11: { # GERMANY
		"faction_name": "The Euro-Zone Industrial Complex", "leader_name": "Chancellor Klaus von Efficiency",
		"population": 90, "treasury": 220, "morale": 0.80, "ap": 2
	},
	12: { # ITALY
		"faction_name": "The Gesticulating Republic", "leader_name": "Prime Minister Silvio 'Bunga Bunga' Bellissimo",
		"population": 75, "treasury": 110, "morale": 0.85, "ap": 3
	},
	13: { # TURKEY
		"faction_name": "The Neo-Ottoman Confederacy", "leader_name": "Sultan Recep 'The Magnificent' Tayyipalooza",
		"population": 80, "treasury": 90, "morale": 0.80, "ap": 3
	},
	14: { # UKRAINE
		"faction_name": "The Unbreakable Nation", "leader_name": "President Volodomyr 'The Unyielding' Zelenko",
		"population": 60, "treasury": 40, "morale": 0.95, "ap": 4
	},
	15: { # JAPAN
		"faction_name": "The Anime & Robotics Shogunate", "leader_name": "Prime Minister Fumio 'Salaryman' Kishida",
		"population": 95, "treasury": 180, "morale": 0.80, "ap": 2
	}
}

# --- The "Trigger" ---
@export var faction_preset: FactionPreset = FactionPreset.NONE:
	set(value):
		faction_preset = value
		if Engine.is_editor_hint() and faction_preset != FactionPreset.NONE:
			# --- THE FINAL FIX ---
			# We call the function DEFERRED to avoid a race condition in the editor.
			call_deferred("_populate_from_preset", value)

# --- The Data Fields ---
@export_group("Faction Identity")
@export var faction_name: String = ""
@export var leader_name: String = ""
@export var avatar: Texture2D

@export_group("Starting Stats")
@export var starting_population: int = 100
@export var starting_treasury: int = 100
@export var starting_morale: float = 0.75
@export var base_action_points: int = 3

@export_group("AI & Diplomacy")
@export var personality_traits: Array[FactionData.Traits]
@export var relationships: Dictionary = {}

enum Traits {
	AGGRESSIVE, DEFENSIVE, PATIENT, UNPREDICTABLE, OPPORTUNIST, STRATEGIC,
	DIPLOMATIC, TREACHEROUS, RUTHLESS, PROUD, CHARISMATIC, EXPANSIONIST, ISOLATIONIST
}

# --- The "Magic" Function ---
func _populate_from_preset(preset_value):
	if not PRESET_DATA.has(preset_value):
		return
	
	var data = PRESET_DATA[preset_value]
	
	self.faction_name = data.get("faction_name", "")
	self.leader_name = data.get("leader_name", "")
	self.starting_population = data.get("population", 100)
	self.starting_treasury = data.get("treasury", 100)
	self.starting_morale = data.get("morale", 0.75)
	self.base_action_points = data.get("ap", 3)
	
	# This function tells the editor that the resource has changed and needs a refresh.
	emit_changed()
	
	print("Faction data populated from preset: ", self.faction_name)
