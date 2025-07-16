class_name PlayerPanel
extends Control

signal panel_selected(player_panel_node)

# --- BULLETPROOF NODE REFERENCES ---
# We use the full, explicit path from the root of THIS scene.
@onready var avatar_texture: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/Avatar
@onready var leader_name_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/LeaderNameLabel
@onready var faction_name_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/FactionNameLabel
# FIX: Corrected the typo from @onrobot to @onready
@onready var population_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/PopulationLabel
@onready var panel_container: PanelContainer = $PanelContainer

var player_state: PlayerState

func _gui_input(event: InputEvent):
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()):
		return
		
	if player_state and player_state.is_ai:
		panel_selected.emit(self)

func select():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.1, 0.1, 0.2)
	style.border_width_bottom = 4
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_color = Color.RED
	panel_container.add_theme_stylebox_override("panel", style)

func deselect():
	panel_container.remove_theme_stylebox_override("panel")

func update_display(p_player_state: PlayerState):
	self.player_state = p_player_state
	
	leader_name_label.text = player_state.faction_data.leader_name
	faction_name_label.text = player_state.faction_data.faction_name
	population_label.text = "Pop: %s Million" % player_state.current_population

	if player_state.faction_data.avatar:
		avatar_texture.texture = player_state.faction_data.avatar
	else:
		avatar_texture.texture = null
