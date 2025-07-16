# This script doesn't attach to a node. It defines a custom data type.
class_name FactionData
extends Resource

# --- Faction Identity ---
@export var faction_name: String = ""
@export var leader_name: String = ""
@export_multiline var description: String = "" # A place for flavor text
@export var avatar: Texture2D # You will drag and drop your art here!

# --- Gameplay Stats ---
@export var ability_name: String = ""
@export_multiline var ability_description: String = ""
@export_group("Starting Stats")
@export var starting_population: int = 100
@export var starting_treasury: int = 100
@export var starting_morale: float = 0.75 # From 0.0 to 1.0
@export var base_action_points: int = 3

# --- Personality & Relationships ---
# We use an Array of Enums for traits for better type safety.
enum Traits { AGGRESSIVE, DEALMAKER, DEFENSIVE, PATIENT, UNPREDICTABLE, OPPORTUNIST, STRATEGIC, DIPLOMATIC, TREACHEROUS, RUTHLESS, PROUD, CHARISMATIC, EXPANSIONIST, ISOLATIONIST }
@export var personality_traits: Array[Traits]

# A dictionary to hold initial relationship scores. Key = faction_id, Value = score.
@export var relationships: Dictionary = {
	"usa": 0,
	"russia": 0,
	"china": 0,
	"north_korea": 0, # Add all 10 factions here as you create them
	"iran": 0,
	# etc...
}
