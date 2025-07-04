class_name PlayerPanel
extends Control

# This version uses the full path to each node. It's less flexible
# if you change the structure, but it's guaranteed to work if the
# paths and names are correct.
@onready var avatar_rect: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/Avatar
@onready var faction_name_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/FactionNameLabel
@onready var leader_name_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/LeaderNameLabel
@onready var population_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/PopulationLabel

# The rest of the script stays exactly the same...
func update_display(player_state: GameManager.PlayerState):
	# Set the text of the labels from the player's data.
	faction_name_label.text = player_state.faction_data.faction_name
	leader_name_label.text = player_state.faction_data.leader_name
	population_label.text = "Population: %sM" % player_state.current_population
	
	if player_state.faction_data.avatar != null:
		avatar_rect.texture = player_state.faction_data.avatar
	else:
		avatar_rect.texture = null
	
	avatar_rect.custom_minimum_size = Vector2(150, 150)
