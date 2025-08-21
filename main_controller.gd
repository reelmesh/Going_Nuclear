# (This is the full, final script that listens to the EventBus)
extends Node2D

@onready var console_anim_player = $SubViewportContainer/SubViewport/Console3D/console/Physical3DButtons/AnimationPlayer
@onready var interaction_controller: InteractionController = $SubViewportContainer/SubViewport/Console3D/Camera3D
@onready var deployment_screen: Control = $SubViewportContainer/SubViewport/Console3D/console/MainScreen3D/console/MainScreen/SubViewport/DeploymentScreen
# --- MODIFICATION ---
# Added a reference to the Input Shield's CollisionShape3D.
# Adjust the path if the actual node structure differs.
@onready var input_shield_collision_shape: CollisionShape3D = $SubViewportContainer/SubViewport/Console3D/console/MainScreen3D/console/MainScreen/InputShield_StaticBody/InputShield_CollisionShape

const CardChooserScene = preload("res://scenes/ui/CardChooser.tscn")

var selected_enemy_button: PhysicalButton3D = null
var enemy_buttons: Array = []

# --- MODIFICATION ---
# Added a flag to control verbose shield state logging in _process
var _log_shield_state_verbose = false

func _ready():
	await get_tree().create_timer(0.1).timeout
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	deployment_screen = console.get_node("console/MainScreen3D/console/MainScreen/SubViewport/DeploymentScreen")
	
	GameManager.game_state_changed.connect(update_all_ui)
	GameManager.turn_started.connect(on_turn_started)
	
	EventBus.deployment_choice_made.connect(_on_deployment_choice_made)
	
	connect_3d_buttons()
	
	if console and console.game_log_label:
		Logger.log_label = console.game_log_label
		Logger.log("--- GAME LOG CONNECTION ESTABLISHED ---")
	
	# --- MODIFICATION ---
	# Definitive check for Input Shield Collision Shape reference
	if input_shield_collision_shape:
		Logger.log("--- INPUT SHIELD COLLISION SHAPE SUCCESSFULLY ACQUIRED ---")
		Logger.log("--- PATH: %s ---" % input_shield_collision_shape.get_path())
		# Connect directly to the StaticBody3D parent, which should have the input_event signal
		var shield_static_body = input_shield_collision_shape.get_parent()
		if shield_static_body:
			Logger.log("--- SHIELD STATIC BODY FOUND: %s ---" % shield_static_body.name)
			# Attempt connection and check result
			var connection_result = shield_static_body.input_event.connect(_on_input_shield_clicked)
			if connection_result == OK:
				Logger.log("--- INPUT SHIELD SIGNAL CONNECTED SUCCESSFULLY ---")
			else:
				Logger.logerr("ERROR: Failed to connect input shield signal. Error code: %d" % connection_result)
		else:
			Logger.logerr("ERROR: Shield Static Body NOT found!")
		# Initially disable the shield's collision shape
		input_shield_collision_shape.disabled = true
		Logger.log("--- INPUT SHIELD INITIALLY DISABLED (State: %s) ---" % input_shield_collision_shape.disabled)
	else:
		Logger.logerr("ERROR: Input Shield Collision Shape NOT found! Check the node path in the script.")
		Logger.logerr("--- ATTEMPTED PATH WAS: $SubViewportContainer/SubViewport/Console3D/console/MainScreen3D/console/MainScreen/InputShield_StaticBody/InputShield_CollisionShape ---")
	
	setup_game()


# --- MODIFICATION ---
# Added _process to log shield state if _log_shield_state_verbose is true
func _process(_delta):
	if _log_shield_state_verbose and input_shield_collision_shape:
		if not input_shield_collision_shape.disabled:
			Logger.log("--- SHIELD STATE (VERBOSE): ENABLED ---")

func _unhandled_input(event: InputEvent):
	if interaction_controller:
		interaction_controller.check_for_click(event)

func connect_3d_buttons():
	var console_model_root = $SubViewportContainer/SubViewport/Console3D/console
	if console_model_root:
		for node in console_model_root.find_children("*", "StaticBody3D", true):
			if node is PhysicalButton3D:
				node.button_pressed.connect(_on_3d_button_pressed)
				node.set_animation_player(console_anim_player)
				if node.target_mesh.name.begins_with("EnemyButton"):
					enemy_buttons.append(node)

func _on_3d_button_pressed(mesh_name: String):
	Logger.log("--- 3D Button Pressed: %s ---" % mesh_name)
	var button_node: PhysicalButton3D = find_button_by_mesh_name(mesh_name)
	if not button_node:
		Logger.log("ERROR: PhysicalButton3D node not found for mesh: %s" % mesh_name)
		return
	
	var is_enemy_button = mesh_name.begins_with("EnemyButton")
	
	if is_enemy_button:
		if selected_enemy_button == button_node:
			button_node.play_animation(true)
			selected_enemy_button = null
			GameManager.player_selected_target(null)
			for btn in enemy_buttons:
				btn.enable()
		else:
			if selected_enemy_button:
				selected_enemy_button.play_animation(true)
			button_node.play_animation(false)
			selected_enemy_button = button_node
			for btn in enemy_buttons:
				if btn != selected_enemy_button:
					btn.disable()
			var player_map = { "EnemyButtonTopRight": 0, "EnemyButtonBottomRight": 1, "EnemyButtonTopLeft": 2, "EnemyButtonBottomLeft": 3 }
			var ai_players = []
			for p in GameManager.active_players:
				if p.is_ai: ai_players.append(p)
			if player_map.has(mesh_name) and player_map[mesh_name] < ai_players.size():
				var target_player = ai_players[player_map[mesh_name]]
				GameManager.player_selected_target(target_player)
			return

	button_node.play_animation()
	
	if not deployment_screen:
		Logger.log("ERROR: DeploymentScreen node reference is not set.")
		return

	# --- MODIFICATION ---
	# According to the design principles:
	# 1. 3D buttons should ALWAYS remain active/interactable.
	# 2. The DeploymentScreen should not block general 3D input.
	# Therefore, we DO NOT disable `interaction_controller.process_input` here.
	# The responsibility for closing the menu (and potentially managing specific states)
	# now lies with the DeploymentScreen itself or a dedicated "click-off" shield.

	if mesh_name == "EndTurnButton":
		deployment_screen.hide_screen() # Close the menu if it's open
		# --- MODIFICATION ---
		# Do not re-enable `process_input` here as it's no longer managed for this flow.
		_on_end_turn_pressed()
	elif mesh_name == "BuildButton":
		Logger.log("--- BUILD BUTTON PRESSED ---")
		deployment_screen.show_choices("Invest in a Sector:", GameManager.INVESTMENT_SECTORS, "INVESTMENT")
		# --- MODIFICATION ---
		# Enable the input shield's collision shape after showing choices
		if input_shield_collision_shape:
			input_shield_collision_shape.disabled = false
			Logger.log("--- INPUT SHIELD ENABLED for BuildButton (New State: %s) ---" % input_shield_collision_shape.disabled)
		else:
			Logger.logerr("ERROR: Cannot enable input shield, reference is null!")
	elif mesh_name == "DeliveryButton":
		Logger.log("--- DELIVERY BUTTON PRESSED ---")
		show_cards_on_deployment_screen(CardData.CardType.DELIVERY)
		# --- MODIFICATION ---
		# Enable the input shield's collision shape after showing choices
		if input_shield_collision_shape:
			input_shield_collision_shape.disabled = false
			Logger.log("--- INPUT SHIELD ENABLED for DeliveryButton (New State: %s) ---" % input_shield_collision_shape.disabled)
		else:
			Logger.logerr("ERROR: Cannot enable input shield, reference is null!")
	elif mesh_name == "PayloadButton":
		Logger.log("--- PAYLOAD BUTTON PRESSED ---")
		show_cards_on_deployment_screen(CardData.CardType.PAYLOAD)
		# --- MODIFICATION ---
		# Enable the input shield's collision shape after showing choices
		if input_shield_collision_shape:
			input_shield_collision_shape.disabled = false
			Logger.log("--- INPUT SHIELD ENABLED for PayloadButton (New State: %s) ---" % input_shield_collision_shape.disabled)
		else:
			Logger.logerr("ERROR: Cannot enable input shield, reference is null!")
	elif mesh_name == "InfoWarButton":
		Logger.log("--- INFOWAR BUTTON PRESSED ---")
		show_cards_on_deployment_screen(CardData.CardType.INFO_WAR)
		# --- MODIFICATION ---
		# Enable the input shield's collision shape after showing choices
		if input_shield_collision_shape:
			input_shield_collision_shape.disabled = false
			Logger.log("--- INPUT SHIELD ENABLED for InfoWarButton (New State: %s) ---" % input_shield_collision_shape.disabled)
		else:
			Logger.logerr("ERROR: Cannot enable input shield, reference is null!")
	elif mesh_name == "UtilityButton":
		Logger.log("--- UTILITY BUTTON PRESSED ---")
		show_cards_on_deployment_screen(CardData.CardType.UTILITY)
		# --- MODIFICATION ---
		# Enable the input shield's collision shape after showing choices
		if input_shield_collision_shape:
			input_shield_collision_shape.disabled = false
			Logger.log("--- INPUT SHIELD ENABLED for UtilityButton (New State: %s) ---" % input_shield_collision_shape.disabled)
		else:
			Logger.logerr("ERROR: Cannot enable input shield, reference is null!")
	elif mesh_name == "DefenseButton":
		Logger.log("--- DEFENSE BUTTON PRESSED ---")
		show_cards_on_deployment_screen(CardData.CardType.DEFENSE)
		# --- MODIFICATION ---
		# Enable the input shield's collision shape after showing choices
		if input_shield_collision_shape:
			input_shield_collision_shape.disabled = false
			Logger.log("--- INPUT SHIELD ENABLED for DefenseButton (New State: %s) ---" % input_shield_collision_shape.disabled)
		else:
			Logger.logerr("ERROR: Cannot enable input shield, reference is null!")

func show_cards_on_deployment_screen(card_type: int):
	Logger.log("Attempting to show deployment screen for card type: %s" % CardData.CardType.keys()[card_type])
	if not deployment_screen:
		Logger.log("ERROR: DeploymentScreen node reference is not set.")
		return

	var title = CardData.CardType.keys()[card_type].capitalize()
	var human_hand = GameManager.get_human_player_state().hand
	Logger.log("Player hand contains: %s" % str(human_hand))
	
	var card_ids_of_type = []
	for card_id in human_hand:
		var card_data = CardDatabase.get_card_data(card_id)
		if card_data and card_data.card_type == card_type:
			card_ids_of_type.append(card_id)

	Logger.log("Found %d cards of type %s in hand." % [card_ids_of_type.size(), title])

	if card_ids_of_type.is_empty():
		Logger.log("Result: You have no cards of type: %s" % title)
		return

	var card_objects = []
	for id in card_ids_of_type:
		card_objects.append(CardDatabase.get_card_data(id))

	Logger.log("Instructing DeploymentScreen to show %d choices." % card_objects.size())
	deployment_screen.show_choices("Select a %s Card:" % title, card_objects, "CARD")

func _on_deployment_choice_made(choice_data):
	Logger.log("--- Deployment Choice Received by Main Controller ---")
	if not deployment_screen:
		Logger.log("ERROR: DeploymentScreen node reference is not set in _on_deployment_choice_made.")
		return
	
	if choice_data is int:
		Logger.log("Choice is an INVESTMENT (ID: %d). Processing build action." % choice_data)
		GameManager.process_build_action(choice_data)
	elif choice_data is CardData:
		Logger.log("Choice is a CARD ('%s'). Processing card selection." % choice_data.card_name)
		GameManager.player_selected_card(choice_data)
	else:
		Logger.log("ERROR: Received unknown choice data type: %s" % typeof(choice_data))
	
	# Hide the deployment screen after a choice is made
	deployment_screen.hide_screen()
	
	# --- MODIFICATION ---
	# According to the design principles, `interaction_controller.process_input`
	# is no longer managed by this function for the Deployment Screen flow.
	# It remains true to keep 3D buttons active.
	# If specific temporary disabling were needed for other reasons (e.g., animations),
	# it would be handled locally or by the shield mechanism.
	
	# --- MODIFICATION ---
	# Disable the input shield's collision shape when a choice is made
	if input_shield_collision_shape:
		input_shield_collision_shape.disabled = true
		# --- DEBUG ---
		Logger.log("--- INPUT SHIELD DISABLED after choice made ---")
	else:
		Logger.logerr("ERROR: Cannot disable input shield, reference is null!")
	
func _on_end_turn_pressed():
	# --- MODIFICATION ---
	# According to the design principles, `interaction_controller.process_input`
	# is no longer managed by this function for the Deployment Screen flow.
	# It should remain true to keep 3D buttons active.
	# If specific temporary disabling were needed for other reasons (e.g., animations),
	# it would be handled locally or by the shield mechanism.
	
	# --- MODIFICATION ---
	# Disable the input shield's collision shape when the turn ends
	if input_shield_collision_shape:
		input_shield_collision_shape.disabled = true
		# --- DEBUG ---
		Logger.log("--- INPUT SHIELD DISABLED at end of turn ---")
	else:
		Logger.logerr("ERROR: Cannot disable input shield, reference is null!")
		
	if GameManager.is_player_action_valid():
		GameManager.process_player_attack()
	else:
		Logger.log("No action selected. Ending turn.")
		GameManager.pass_turn()


# --- MODIFICATION ---
# Added a new function to handle clicks on the input shield.
# This function will hide the deployment screen and disable the shield's collision shape.
func _on_input_shield_clicked(_camera: Camera3D, event: InputEvent, _click_position: Vector3, _click_normal: Vector3, _shape_idx: int):
	# --- DEBUG ---
	Logger.log("--- _on_input_shield_clicked SIGNAL RECEIVED ---")
	# Check if the event is a mouse button press
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# --- DEBUG ---
		Logger.log("--- _on_input_shield_clicked MOUSE EVENT PROCESSED ---")
		Logger.log("--- Input Shield Clicked ---")
		
		# Hide the deployment screen
		if deployment_screen:
			deployment_screen.hide_screen()
			Logger.log("--- DEPLOYMENT SCREEN HIDDEN ---")
		else:
			Logger.logerr("ERROR: Deployment screen reference is null in _on_input_shield_clicked!")
		
		# Disable the input shield's collision shape
		if input_shield_collision_shape:
			input_shield_collision_shape.disabled = true
			# --- DEBUG ---
			Logger.log("--- INPUT SHIELD DISABLED after click (New State: %s) ---" % input_shield_collision_shape.disabled)
		else:
			Logger.logerr("ERROR: Cannot disable input shield in _on_input_shield_clicked, reference is null!")

func find_button_by_mesh_name(mesh_name: String) -> PhysicalButton3D:
	var console_model_root = $SubViewportContainer/SubViewport/Console3D/console
	if console_model_root:
		for node in console_model_root.find_children("*", "StaticBody3D", true):
			if node is PhysicalButton3D and node.target_mesh.name == mesh_name:
				return node
	return null

func on_turn_started(player_state: PlayerState):
	if player_state.is_ai:
		set_player_controls_enabled(false)
	else:
		set_player_controls_enabled(true)
		if selected_enemy_button:
			selected_enemy_button.play_animation(true)
			selected_enemy_button = null
			GameManager.player_selected_target(null)
		for btn in enemy_buttons:
			btn.enable()

func set_player_controls_enabled(is_enabled: bool):
	var console_model_root = $SubViewportContainer/SubViewport/Console3D/console
	if not console_model_root: return
	
	for node in console_model_root.find_children("*", "StaticBody3D", true):
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
		var player_text = "TREASURY: $%sT\nMORALE: %s%%\nAP: %s" % [
			human_player.current_treasury,
			int(human_player.current_morale * 100),
			human_player.current_ap
		]
		console.player_info_label.text = player_text
		
	generate_player_ui()

func generate_player_ui():
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if not console: return
	
	var enemy_labels = [
		console.enemy_info_tr, console.enemy_info_br,
		console.enemy_info_tl, console.enemy_info_bl]
	
	var avatar_images = [
		console.avatar_image_tr, console.avatar_image_br,
		console.avatar_image_tl, console.avatar_image_bl]
	var ai_players = []
	for p in GameManager.active_players:
		if p.is_ai: ai_players.append(p)

	for i in range(enemy_labels.size()):
		if i < ai_players.size():
			var ai = ai_players[i]
			if enemy_labels[i]:
				enemy_labels[i].text = "%s\n%s\nPop: %sM" % [ai.faction_data.faction_name, ai.faction_data.leader_name, ai.current_population]
			if avatar_images[i]:
				avatar_images[i].texture = ai.faction_data.avatar
		else:
			if enemy_labels[i]:
				enemy_labels[i].text = ""
			if avatar_images[i]:
				avatar_images[i].texture = null
