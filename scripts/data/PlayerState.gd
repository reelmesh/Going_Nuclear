# (This code is indented with tabs)
# This class is now in its own file, making it a first-class citizen in our project.
class_name PlayerState
extends RefCounted # A simple base object for data containers.

var faction_data: FactionData
var current_population: int
var current_treasury: int
var current_morale: float
var current_ap: int
var is_ai: bool
var player_index: int
var hand: Array = []
var status_effects: Array = []

# The constructor function, now in its own file, will work correctly.
func _init(p_faction_data: FactionData, p_is_ai: bool, p_index: int):
	self.faction_data = p_faction_data
	self.is_ai = p_is_ai
	self.player_index = p_index
	self.current_population = p_faction_data.starting_population
	self.current_treasury = p_faction_data.starting_treasury
	self.current_morale = p_faction_data.starting_morale
	self.current_ap = 0
