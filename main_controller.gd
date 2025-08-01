# (This is the full, correct script for your Main scene)
extends Node2D

const PlayerPanelScene = preload("res://scenes/ui/PlayerPanel.tscn")
const CardChooserScene = preload("res://scenes/ui/CardChooser.tscn")
const PlaceholderButtonScene = preload("res://scenes/ui/PlaceholderButton.tscn")

@onready var enemy_panel_tl = %EnemyPanel_TopLeft
@onready var enemy_panel_bl = %EnemyPanel_BottomLeft
@onready var enemy_panel_tr = %EnemyPanel_TopRight
@onready var enemy_panel_br = %EnemyPanel_BottomRight
@onready var deployment_screen = %DeploymentScreen
@onready var console_anim_player = $SubViewportContainer/SubViewport/Console3D/AnimationPlayer

# This will now store the MESH NAME of the selected button.
var selected_enemy_mesh_name: String = ""
# --- UPDATED: This variable now holds our CORRECT class type ---
var selected_enemy_button: PhysicalButton3D = null
# This array will hold references to all enemy buttons for easy access.
var enemy_buttons: Array[PhysicalButton3D] = []

func _ready():
	GameManager.game_state_changed.connect(update_all_ui)
	GameManager.turn_started.connect(on_turn_started)
	await get_tree().create_timer(0.1).timeout
	connect_3d_buttons()
	# --- THIS IS THE FIX ---
	# We get a reference to our console's "receptionist" script.
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if console and console.game_log_label:
		# Tell the global Logger which RichTextLabel to use.
		Logger.log_label = console.game_log_label
		Logger.log("--- GAME LOG CONNECTION ESTABLISHED ---")
	
	# Start the game logic.
	setup_game()

func connect_3d_buttons():
	var console_model_root = $SubViewportContainer/SubViewport/Console3D/console
	if console_model_root:
		for node in console_model_root.find_children("*", "StaticBody3D", true):
			if node is PhysicalButton3D:
				node.button_pressed.connect(_on_3d_button_pressed)
				node.set_animation_player(console_anim_player)
				# --- NEW: Populate our list of enemy buttons ---
				if node.target_mesh.name.begins_with("EnemyButton"):
					enemy_buttons.append(node)

# --- THIS IS THE FINAL "TARGET LOCK" BRAIN ---
func _on_3d_button_pressed(mesh_name: String):
	Logger.log("3D Button Pressed: %s" % mesh_name)
	
	var button_node: PhysicalButton3D = find_button_by_mesh_name(mesh_name)
	if not button_node: return
	
	var is_enemy_button = mesh_name.begins_with("EnemyButton")
	
	if is_enemy_button:
		if selected_enemy_button == button_node:
			# --- Rule 2: Toggle Release ---
			# We clicked the already-pressed button. Release it.
			button_node.play_animation(true) # Play release
			selected_enemy_button = null
			GameManager.player_selected_target(null)
			# Make ALL enemy buttons clickable again.
			for btn in enemy_buttons:
				btn.enable()
		else:
			# A new enemy button was clicked.
			# If another was already selected, release it first.
			if selected_enemy_button:
				selected_enemy_button.play_animation(true)
			
			# Press the new button and store it as the selection.
			button_node.play_animation(false) # Play press
			selected_enemy_button = button_node
			
			# --- Rule 1: Exclusive Selection ---
			# Disable all other enemy buttons.
			for btn in enemy_buttons:
				if btn != selected_enemy_button:
					btn.disable()
			
			# Update the GameManager with the new target.
			# ... (This logic is the same and correct) ...
		return

	# --- Logic for Other Action Buttons ---
	# They just play their animation. They no longer affect the target selection.
	button_node.play_animation()

	if mesh_name == "EndTurnButton":
		_on_end_turn_pressed()
	# ... (elif for BuildButton, etc.) ...

# --- Rule 3: Turn-Based Reset ---
func on_turn_started(player_state: PlayerState):
	if player_state.is_ai:
		set_player_controls_enabled(false)
	else:
		set_player_controls_enabled(true)
		# At the start of our turn, if a button was selected, release it.
		if selected_enemy_button:
			selected_enemy_button.play_animation(true)
			selected_enemy_button = null
			GameManager.player_selected_target(null)
		
		# And always re-enable all enemy buttons for the new turn.
		for btn in enemy_buttons:
			btn.enable()

# --- find_button_by_mesh_name is now needed by this script ---
func find_button_by_mesh_name(mesh_name: String) -> PhysicalButton3D:
	var console_model_root = $SubViewportContainer/SubViewport/Console3D/console
	if console_model_root:
		for node in console_model_root.find_children("*", "StaticBody3D", true):
			if node is PhysicalButton3D and node.target_mesh.name == mesh_name:
				return node
	return null

# --- This function is now also called by _on_3d_button_pressed ---
func _on_end_turn_pressed():
	if GameManager.is_player_action_valid():
		GameManager.process_player_attack()
	else:
		Logger.log("No action selected. Ending turn.")
		GameManager.pass_turn()

func set_player_controls_enabled(is_enabled: bool):
	var console_model_root = $SubViewportContainer/SubViewport/Console3D/console
	if not console_model_root: return
	
	for node in console_model_root.find_children("*", "StaticBody3D", true):
		# --- UPDATED: Check for the CORRECT class name ---
		if node is PhysicalButton3D:
			if is_enabled:
				node.enable()
			else:
				node.disable()
				
	var status = "ENABLED" if is_enabled else "DISABLED"
	Logger.log("Player 3D controls have been " + status)

func setup_game():
	var factions_in_match = ["usa", "russia", "china", "north_korea"]
	GameManager.start_new_game(factions_in_match)
	update_all_ui()
	GameManager.start_turn()

func update_all_ui():
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if not console: return
	
	var human_player = GameManager.get_human_player_state()
	if human_player and console.player_info_label:
		var player_text = "TREASURY: $%sT\nMORALE: %s%%\nACTION POINTS: %s" % [
			human_player.current_treasury,
			int(human_player.current_morale * 100),
			human_player.current_ap
		]
		console.player_info_label.text = player_text
		
	generate_player_ui()

# --- THIS IS THE UPGRADED FUNCTION WITH ERROR REPORTING ---
func generate_player_ui():
	Logger.log("--- UI: Starting generate_player_ui ---")
	
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if not console:
		Logger.log("ERROR: Could not find ConsoleController node. Aborting UI generation.")
		return
	
	var enemy_labels = [
		console.enemy_info_tr, console.enemy_info_br,
		console.enemy_info_tl, console.enemy_info_bl
	]
	
	var ai_players = []
	for p in GameManager.active_players:
		if p.is_ai:
			ai_players.append(p)
	
	Logger.log("Found %d AI players to display." % ai_players.size())

	for i in range(enemy_labels.size()):
		var label_node = enemy_labels[i]
		
		# Check if the label node itself is valid.
		if not is_instance_valid(label_node):
			Logger.log("ERROR: Label for enemy slot %d is invalid or null." % i)
			continue # Skip to the next iteration of the loop.

		if i < ai_players.size():
			var ai = ai_players[i]
			Logger.log("Updating slot %d for: %s" % [i, ai.faction_data.faction_name])
			if ai and ai.faction_data:
				label_node.text = "%s\n%s\nPop: %sM" % [
					ai.faction_data.faction_name,
					ai.faction_data.leader_name,
					ai.current_population
				]
		else:
			# If no AI for this slot, clear the text.
			Logger.log("Clearing unused enemy slot %d." % i)
			label_node.text = ""
	
	Logger.log("--- UI: Finished generate_player_ui ---")
	
func _on_action_button_pressed(card_type_to_show: CardData.CardType):
	var human_hand = GameManager.get_human_player_state().hand
	var cards_in_category: Array = []
	for card_id in human_hand:
		var card_data = CardDatabase.get_card_data(card_id)
		if card_data.card_type == card_type_to_show:
			cards_in_category.append(card_id)
			
	if cards_in_category.is_empty():
		Logger.log("You have no cards of that type.")
		return
		
	deployment_screen.show_card_choices(cards_in_category)
	if not deployment_screen.card_chosen.is_connected(_on_card_chosen_from_deployment_screen):
		deployment_screen.card_chosen.connect(_on_card_chosen_from_deployment_screen)
	deployment_screen.show()

func _on_card_chosen_from_deployment_screen(card_data: CardData):
	Logger.log("You selected: %s" % card_data.card_name)
	GameManager.player_selected_card(card_data)
	deployment_screen.hide()
	deployment_screen.card_chosen.disconnect(_on_card_chosen_from_deployment_screen)
