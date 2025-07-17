class_name PlayerPanel
extends Control

@onready var faction_name_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/FactionNameLabel
@onready var leader_name_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/LeaderNameLabel
@onready var population_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/PopulationLabel

var player_state: PlayerState

func update_display(p_player_state: PlayerState):
	self.player_state = p_player_state
	# --- THE FIX ---
	faction_name_label.text = player_state.faction_data.faction_name
	leader_name_label.text = player_state.faction_data.leader_name
	population_label.text = "Pop: %s Million" % player_state.current_population
