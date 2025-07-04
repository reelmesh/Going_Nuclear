# This script doesn't attach to a node. It defines a custom data type.
class_name FactionData
extends Resource

# --- Faction Identity ---
@export var faction_name: String = ""
@export var leader_name: String = ""
@export_multiline var description: String = "" # A place for flavor text
@export var avatar: Texture2D # You will drag and drop your art here!

# --- Gameplay Stats ---
@export var starting_population: int = 100
@export var ability_name: String = ""
@export_multiline var ability_description: String = ""

# --- Personality & Relationships ---
# We use an Array of Enums for traits for better type safety.
enum Traits { AGGRESSIVE, DEALMAKER, DEFENSIVE, PATIENT, UNPREDICTABLE, OPPORTUNIST, STRATEGIC, DIPLOMATIC, TREACHEROUS, RUTHLESS, PROUD, CHARISMATIC, EXPANSIONIST, ISOLATIONIST }
@export var personality_traits: Array[Traits]

# A dictionary to hold initial relationship scores. Key = faction_id, Value = score.
@export var relationships: Dictionary = {}
