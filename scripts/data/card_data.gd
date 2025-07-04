class_name CardData
extends Resource

# Enum to define what kind of card this is. This makes logic much easier later.
enum CardType {
	DELIVERY,      # How you send the payload (ICBM, Bomber)
	PAYLOAD,       # What you send (Warhead, Bio-agent)
	INFO_WAR,      # Direct attack that isn't a missile (Disinformation, Scandal)
	DEFENSE,       # A card to block an attack (Bunkers, Firewall)
	UTILITY        # Special actions (Alliances, Espionage)
}

# --- Visual Information (Your Art & Text) ---
@export var card_name: String = ""
# FIX: The old "@export_enum(CardType)" is removed.
# Godot 4 automatically creates a dropdown for any exported enum variable.
@export var card_type: CardType
@export_multiline var description: String = ""
@export var card_art: Texture2D

# --- Gameplay Values ---
# Not all cards will use all these values.
@export_group("Attack Values")
@export var damage: int = 0
@export var success_chance: float = 1.0 # 1.0 = 100%

@export_group("Special Effects")
# We can add more specific variables for complex cards later.
@export var targets_to_affect: int = 1
