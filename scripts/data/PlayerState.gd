# (This code is indented with tabs)
# This class defines the data for a single player in a match.
class_name PlayerState
extends RefCounted

var faction_data: FactionData
var current_population: int
var current_treasury: int
var current_morale: float
var current_ap: int
var is_ai: bool
var player_index: int
var hand: Array = []
var status_effects: Array = []
# var is_patron_of_human: bool = false # We removed this from our last design change.

# The constructor function. There should only be ONE of these.
func _init(p_faction_data: FactionData, p_is_ai: bool, p_index: int):
	self.faction_data = p_faction_data
	self.is_ai = p_is_ai
	self.player_index = p_index
	
	self.current_population = p_faction_data.starting_population
	self.current_treasury = p_faction_data.starting_treasury
	self.current_morale = p_faction_data.starting_morale
	self.current_ap = 0
