# (This code is indented with tabs)
extends Node2D

const PlayerPanelScene = preload("res://scenes/ui/PlayerPanel.tscn")
const CardChooserScene = preload("res://scenes/ui/CardChooser.tscn")
const PlaceholderButtonScene = preload("res://scenes/ui/PlaceholderButton.tscn")

@onready var enemy_panel_tl = %EnemyPanel_TopLeft
@onready var enemy_panel_bl = %EnemyPanel_BottomLeft
@onready var enemy_panel_tr = %EnemyPanel_TopRight
@onready var enemy_panel_br = %EnemyPanel_BottomRight
@onready var action_buttons_container = %ActionButtons
@onready var game_log_label = %GameLog
@onready var end_turn_button = %EndTurn_Button
@onready var player_treasury_label = %PlayerTreasuryLabel
@onready var player_morale_label = %PlayerMoraleLabel
@onready var player_ap_label = %PlayerAPLabel
@onready var deployment_screen = %DeploymentScreen # Get the screen instance

func _ready():
	Logger.log_label = game_log_label
	GameManager.game_state_changed.connect(update_all_ui)
	GameManager.turn_started.connect(on_turn_started)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	setup_game()
	await get_tree().create_timer(0.1).timeout
	var interaction_controller = $SubViewportContainer/SubViewport/Console3D.get_node("Camera3D")
	if interaction_controller:
		interaction_controller.object_clicked.connect(_on_3d_object_clicked)

# (This function goes in scripts/main_controller.gd)

func _on_3d_object_clicked(object_node):
	# The object_node is the StaticBody3D. Its parent is the mesh.
	var mesh_name = object_node.get_parent().name# --- THIS IS OUR NEW, MORE POWERFUL DEBUG PRINT ---
	# The '|' characters will clearly show if there are any leading/trailing spaces.
	Logger.log("--- 3D Click Diagnostic ---")
	Logger.log("Detected mesh name: |" + mesh_name + "|")
	
	# Now, we compare this name to our expected names.
	if mesh_name == "Box_003_build_button":
		Logger.log("Match found! Calling Build Action.")
		GameManager.process_build_action()
	else:
		Logger.log("No match found for the detected name.")
	if mesh_name == "EndTurnButton":
		_on_end_turn_pressed()
		
	elif mesh_name == "BuildButton":
		GameManager.process_build_action()
		
	elif mesh_name == "DeliveryButton":
		_on_action_button_pressed(CardData.CardType.DELIVERY)
		
	elif mesh_name == "PayloadButton":
		_on_action_button_pressed(CardData.CardType.PAYLOAD)
		
	elif mesh_name == "InfoWarButton":
		_on_action_button_pressed(CardData.CardType.INFO_WAR)
		
	elif mesh_name == "UtilityButton":
		_on_action_button_pressed(CardData.CardType.UTILITY)
		
	elif mesh_name == "DefenseButton":
		_on_action_button_pressed(CardData.CardType.DEFENSE)
	
	# We will add logic for the avatar/target buttons later.

func _on_end_turn_pressed():
	if GameManager.is_player_action_valid():
		GameManager.process_player_attack()
	else:
		Logger.log("No action selected. Ending turn.")
		GameManager.pass_turn()

func setup_game():
	var factions_in_match = ["usa", "russia", "china", "north_korea"]
	GameManager.start_new_game(factions_in_match)
	update_all_ui()
	GameManager.start_turn()

func update_all_ui():
	var human_player = GameManager.get_human_player_state()
	if human_player:
		player_treasury_label.text = "Treasury: $%sT" % human_player.current_treasury
		player_morale_label.text = "Morale: %s%%" % int(human_player.current_morale * 100)
		player_ap_label.text = "Action Points: %s" % human_player.current_ap
		
	# Update the UI panels for the AI.
	generate_player_ui()


func set_player_controls_enabled(is_enabled: bool):
	for button in action_buttons_container.get_children():
		button.disabled = not is_enabled
	end_turn_button.disabled = not is_enabled

func on_turn_started(player_state: PlayerState):
	if player_state.is_ai:
		set_player_controls_enabled(false)
	else:
		set_player_controls_enabled(true)

func generate_action_buttons():
	for child in action_buttons_container.get_children():
		child.queue_free()
	var build_button = PlaceholderButtonScene.instantiate()
	build_button.text = "Build (1 AP)"
	action_buttons_container.add_child(build_button)
	build_button.pressed.connect(GameManager.process_build_action)
	var card_categories = {
		"Delivery": CardData.CardType.DELIVERY,
		"Payload": CardData.CardType.PAYLOAD,
		"InfoWar": CardData.CardType.INFO_WAR,
	}
	for category_name in card_categories:
		var button = PlaceholderButtonScene.instantiate()
		button.text = category_name
		action_buttons_container.add_child(button)
		button.pressed.connect(_on_action_button_pressed.bind(card_categories[category_name]))

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
		
	# --- THIS IS THE FIX ---
	# We no longer instantiate the chooser. We use the one in our scene.
	# It's now called deployment_screen.
	deployment_screen.show_card_choices(cards_in_category)
	
	# Connect to its signal.
	if not deployment_screen.card_chosen.is_connected(_on_card_chosen_from_deployment_screen):
		deployment_screen.card_chosen.connect(_on_card_chosen_from_deployment_screen)
	
	# Instead of an animation, we just make it visible for now.
	deployment_screen.visible = true

# We also need to hide it after a choice is made.
func _on_card_chosen_from_deployment_screen(card_data: CardData):
	Logger.log("You selected: %s" % card_data.card_name)
	GameManager.player_selected_card(card_data)
	
	# Hide the screen after a selection is made.
	deployment_screen.visible = false

func generate_player_ui():
	# Define our UI containers from the scene tree.
	var ui_panel_containers = [enemy_panel_tr, enemy_panel_br, enemy_panel_tl, enemy_panel_bl]
	
	# Clear out any old info panels from the UI containers.
	for container in ui_panel_containers:
		for child in container.get_children():
			child.queue_free()

	var panel_index = 0
	# Loop through all players known by the GameManager.
	for player_state in GameManager.active_players:
		# We only create UI for the AI enemies.
		if player_state.is_ai:
			# Check if we have a slot available for this AI.
			if panel_index >= ui_panel_containers.size():
				break

			# Get the specific UI container for this AI.
			var target_ui_container = ui_panel_containers[panel_index]
			
			# Create and populate the info panel.
			var new_ui_panel = PlayerPanelScene.instantiate()
			target_ui_container.add_child(new_ui_panel)
			new_ui_panel.update_display(player_state)
			
			# We no longer handle any button logic here. That will be done in 3D.
			
			panel_index += 1
