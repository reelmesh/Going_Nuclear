# (This code is indented with tabs)
@tool
class_name CardData
extends Resource

# --- 1. The Preset Selector ---
# This enum will become our dropdown menu in the Inspector.
enum CardPreset {
	NONE,
	# Delivery
	ICBM, SLBM, STRATEGIC_BOMBER, HYPERSONIC_MISSILE,
	# Payload
	TACTICAL_WARHEAD, STRATEGIC_WARHEAD, MULTI_MEGATON_WARHEAD, EMP_WARHEAD, DIRTY_BOMB, NEUTRON_BOMB,
	# InfoWar
	VIRAL_DISINFORMATION, DEEPFAKE_SCANDAL, SUPPLY_CHAIN_HACK, GPS_SPOOFING,
	# Utility
	INTELLIGENCE_AGENCY, SABOTAGE, DIPLOMATIC_SUMMIT, ASSASSINATE_SCIENTIST, COUP_DETAT,
	# Defense
	ABM_SILOS, COUNTER_PROPAGANDA, HARDENED_BUNKERS, MILITARY_GRADE_FIREWALL, COUNTER_INTELLIGENCE_NETWORK, PALACE_GUARD
}

# --- 2. The Central Database (The GDD, in code form) ---
# This is a true const using integer keys for reliability in the editor.
const PRESET_DATA = {
	# Delivery
	1:  { "name": "ICBM", "type": 0, "desc": "Reliable silo-launched missile.", "chance": 0.95 },
	2:  { "name": "SLBM", "type": 0, "desc": "Undetectable submarine-launched missile.", "chance": 0.90 },
	3:  { "name": "Strategic Bomber", "type": 0, "desc": "Vulnerable but versatile aircraft.", "chance": 0.75 },
	4:  { "name": "Hypersonic Missile", "type": 0, "desc": "Advanced missile that ignores standard ABM defenses.", "chance": 0.85 },
	# Payload
	5:  { "name": "Tactical Warhead", "type": 1, "desc": "A small, 1-10 Megaton payload for precise strikes.", "damage": 10 },
	6:  { "name": "Strategic Warhead", "type": 1, "desc": "A standard 20-50 Megaton thermonuclear payload.", "damage": 50 },
	7:  { "name": "Multi-Megaton Warhead", "type": 1, "desc": "A massive 100+ Megaton city-killer. Use has severe consequences.", "damage": 100 },
	8:  { "name": "EMP Warhead", "type": 1, "desc": "Deals no population damage. Target loses 2 AP and discards 1 card.", "damage": 0 },
	9:  { "name": "Dirty Bomb", "type": 1, "desc": "Deals 10 damage and applies 'Fallout' for 3 turns (loses pop/treasury).", "damage": 10 },
	10: { "name": "Neutron Bomb", "type": 1, "desc": "Deals 75 damage and massively reduces Morale.", "damage": 75 },
	# InfoWar
	11: { "name": "Viral Disinformation", "type": 2, "desc": "Deals 15 damage via civil unrest and reduces Morale.", "damage": 15 },
	12: { "name": "Deepfake Scandal", "type": 2, "desc": "Target's Morale plummets. Diplomatic relations with all others are damaged." },
	13: { "name": "Supply Chain Hack", "type": 2, "desc": "Target loses Treasury. 'Build' action cost is doubled next turn." },
	14: { "name": "GPS Spoofing", "type": 2, "desc": "For the next turn, the target's DELIVERY cards have their success_chance massively reduced." },
	# Utility
	15: { "name": "Intelligence Agency", "type": 3, "desc": "View a target's hand and expose one card to all players." },
	16: { "name": "Sabotage", "type": 3, "desc": "Force a target to discard one random DELIVERY or DEFENSE card." },
	17: { "name": "Diplomatic Summit", "type": 3, "desc": "Spend Treasury to significantly improve relations with a target." },
	18: { "name": "Assassinate Scientist", "type": 3, "desc": "Permanently remove an opponent's most dangerous technological advantage." },
	19: { "name": "Coup d'état", "type": 3, "desc": "The ultimate soft power weapon. Target loses their next turn and suffers a massive Morale penalty." },
	# Defense
	20: { "name": "ABM Silos", "type": 4, "desc": "Grants 'Missile Shield' for one round, stopping one ICBM or SLBM." },
	21: { "name": "Counter-Propaganda", "type": 4, "desc": "Grants 'Firewall' for one round, stopping one InfoWar attack." },
	22: { "name": "Hardened Bunkers", "type": 4, "desc": "Passive: Halves population damage from the next successful nuclear attack." },
	23: { "name": "Military-Grade Firewall", "type": 4, "desc": "Negates one incoming Supply Chain Hack or GPS Spoofing attack." },
	24: { "name": "Counter-Intelligence Network", "type": 4, "desc": "Negates one incoming Sabotage or Assassinate Scientist action." },
	25: { "name": "Palace Guard", "type": 4, "desc": "The only defense that can foil a Coup d'état attempt." }
}

# --- 3. The "Trigger" Variable ---
@export var card_preset: CardPreset = CardPreset.NONE:
	set(value):
		card_preset = value
		if Engine.is_editor_hint() and card_preset != CardPreset.NONE:
			call_deferred("_populate_from_preset", value)

# --- 4. The Data Fields ---
# These are the properties that will be saved in your .tres files.
@export_group("Card Identity")
@export var card_name: String = ""
@export var card_art: Texture2D
@export_multiline var description: String = ""

@export_group("Card Logic")
@export var card_type: CardData.CardType # This uses the CardType enum defined below
@export var damage: int = 0
@export var success_chance: float = 1.0

# This is the enum that card_type uses. It must be defined in the script.
enum CardType { DELIVERY, PAYLOAD, INFO_WAR, UTILITY, DEFENSE }

# --- 5. The Magic Function ---
func _populate_from_preset(preset_value):
	if not PRESET_DATA.has(preset_value): return
	var data = PRESET_DATA[preset_value]
	
	self.card_name = data.get("name", "")
	self.card_type = data.get("type", 0)
	self.description = data.get("desc", "")
	self.damage = data.get("damage", 0)
	self.success_chance = data.get("chance", 1.0)
	
	emit_changed()
	print("Card data populated from preset: ", self.card_name)
