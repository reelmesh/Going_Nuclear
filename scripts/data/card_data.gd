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
	STANDARD_WARHEAD, EMP_WARHEAD, DIRTY_BOMB, NEUTRON_BOMB,
	# InfoWar
	VIRAL_DISINFORMATION, DEEPFAKE_SCANDAL, SUPPLY_CHAIN_HACK,
	# Utility
	INTELLIGENCE_AGENCY, SABOTAGE, DIPLOMATIC_SUMMIT,
	# Defense
	ABM_SILOS, COUNTER_PROPAGANDA, HARDENED_BUNKERS
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
	5:  { "name": "Standard Warhead", "type": 1, "desc": "50 Megaton thermonuclear payload.", "damage": 50 },
	6:  { "name": "EMP Warhead", "type": 1, "desc": "Deals no population damage. Target loses 2 AP and discards 1 card.", "damage": 0 },
	7:  { "name": "Dirty Bomb", "type": 1, "desc": "Deals 10 damage and applies 'Fallout' for 3 turns (loses pop/treasury).", "damage": 10 },
	8:  { "name": "Neutron Bomb", "type": 1, "desc": "Deals 75 damage and massively reduces Morale.", "damage": 75 },
	# InfoWar
	9:  { "name": "Viral Disinformation", "type": 2, "desc": "Deals 15 damage via civil unrest and reduces Morale.", "damage": 15 },
	10: { "name": "Deepfake Scandal", "type": 2, "desc": "Target's Morale plummets. Diplomatic relations with all others are damaged." },
	11: { "name": "Supply Chain Hack", "type": 2, "desc": "Target loses Treasury. 'Build' action cost is doubled next turn." },
	# Utility
	12: { "name": "Intelligence Agency", "type": 3, "desc": "View a target's hand and expose one card to all players." },
	13: { "name": "Sabotage", "type": 3, "desc": "Force a target to discard one random DELIVERY or DEFENSE card." },
	14: { "name": "Diplomatic Summit", "type": 3, "desc": "Spend Treasury to significantly improve relations with a target." },
	# Defense
	15: { "name": "ABM Silos", "type": 4, "desc": "Grants 'Missile Shield' for one round, stopping one ICBM or SLBM." },
	16: { "name": "Counter-Propaganda", "type": 4, "desc": "Grants 'Firewall' for one round, stopping one InfoWar attack." },
	17: { "name": "Hardened Bunkers", "type": 4, "desc": "Passive: Halves population damage from the next successful nuclear attack." }
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
