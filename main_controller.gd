# (This is the full, final script that listens to the EventBus)
extends Node2D

@onready var console_anim_player = $SubViewportContainer/SubViewport/Console3D/console/Physical3DButtons/AnimationPlayer
@onready var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
@onready var interaction_controller: InteractionController = $SubViewportContainer/SubViewport/Console3D/Camera3D
@onready var light_anim_player: AnimationPlayer = $SubViewportContainer/SubViewport/Console3D/LightAnimationPlayer
@onready var overhead_light: SpotLight3D = $SubViewportContainer/SubViewport/Console3D/Overhead_Light
@onready var ambient_light: OmniLight3D = $SubViewportContainer/SubViewport/Console3D/Ambient_Light
@onready var left_fill_light: OmniLight3D = $SubViewportContainer/SubViewport/Console3D/LeftFill_Light
@onready var right_fill_light: OmniLight3D = $SubViewportContainer/SubViewport/Console3D/RightFill_Light
@onready var deployment_screen: Control = $SubViewportContainer/SubViewport/Console3D/console/MainScreen3D/console/MainScreen/SubViewport/DeploymentScreen
# --- MODIFICATION ---
# Added a reference to the Input Shield's CollisionShape3D.
# Adjust the path if the actual node structure differs.
@onready var input_shield_collision_shape: CollisionShape3D = $SubViewportContainer/SubViewport/Console3D/console/MainScreen3D/console/MainScreen/InputShield_StaticBody/InputShield_CollisionShape

const CardChooserScene = preload("res://scenes/ui/CardChooser.tscn")

var selected_enemy_button: PhysicalButton3D = null
var enemy_buttons: Array = []
var all_buttons: Array = []
var enemy_button_map: Dictionary = {}
var end_turn_button: PhysicalButton3D = null
var _enemy_to_release: PhysicalButton3D = null

# --- MODIFICATION ---
# Added a flag to control verbose shield state logging in _process
var _log_shield_state_verbose = false

func _ready():
	await get_tree().create_timer(0.1).timeout
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
				Logger.log("ERROR: Failed to connect input shield signal. Error code: %d" % connection_result)
		else:
			Logger.log("ERROR: Shield Static Body NOT found!")
		# Initially disable the shield's collision shape
	input_shield_collision_shape.disabled = true
	Logger.log("--- INPUT SHIELD INITIALLY DISABLED (State: %s) ---" % input_shield_collision_shape.disabled)
	
	setup_game()
	_set_default_lighting()


# --- MODIFICATION ---
# Added _process to log shield state if _log_shield_state_verbose is true
func _process(_delta):
	if _log_shield_state_verbose and input_shield_collision_shape:
		if not input_shield_collision_shape.disabled:
			Logger.log("--- SHIELD STATE (VERBOSE): ENABLED ---")

func _unhandled_input(event: InputEvent):
	if interaction_controller:
		interaction_controller.check_for_click(event)

func update_all_ui():
	var ai_players = []
	for p in GameManager.active_players:
		if p.is_ai:
			ai_players.append(p)
	
	if console:
		console.update_avatar_display(ai_players)
		console.update_info_screens(GameManager.get_human_player_state(), ai_players)
		
		enemy_button_map.clear()
		var player_map_visual = { 0: "EnemyButtonTopRight", 1: "EnemyButtonBottomRight", 2: "EnemyButtonTopLeft", 3: "EnemyButtonBottomLeft" }
		for i in range(ai_players.size()):
			if player_map_visual.has(i):
				var button_name = player_map_visual[i]
				enemy_button_map[button_name] = ai_players[i]

func on_turn_started(player_state):
	if player_state.is_ai:
		if light_anim_player and not light_anim_player.is_playing():
			light_anim_player.play("Alarm_AI_TurnLoop")
	else:
		if light_anim_player:
			light_anim_player.play("Alarm_AI_TurnEnd")
			await light_anim_player.animation_finished
		
		# First, handle the EndTurnButton and wait for it to finish.
		if end_turn_button:
			end_turn_button.play_animation(true) # Play release animation
			if console_anim_player and console_anim_player.is_playing():
				await console_anim_player.animation_finished

		# THEN, use the targeting system to find the correct button to release.
		if _enemy_to_release:
			Logger.log("DEBUG: Releasing pressed button: %s" % _enemy_to_release.target_mesh.name)
			_enemy_to_release.play_animation(true)
			_enemy_to_release = null
		
		for button in all_buttons:
			button.enable()

func find_button_by_mesh_name(mesh_name: String) -> PhysicalButton3D:
	for button in all_buttons:
		if button.target_mesh.name == mesh_name:
			return button
	return null

func setup_game():
	var all_factions = FactionDatabase.get_all_faction_ids()
	all_factions.shuffle()
	var selected_factions = all_factions.slice(0, 4)
	GameManager.start_new_game(selected_factions)
	update_all_ui()

func connect_3d_buttons():
	var console_model_root = $SubViewportContainer/SubViewport/Console3D/console
	if console_model_root:
		for node in console_model_root.find_children("*", "StaticBody3D", true):
			if node is PhysicalButton3D:
				node.button_pressed.connect(_on_3d_button_pressed)
				node.set_animation_player(console_anim_player)
				all_buttons.append(node)
				if node.target_mesh.name.begins_with("EnemyButton"):
					enemy_buttons.append(node)
				elif node.target_mesh.name == "EndTurnButton":
					end_turn_button = node

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
			return
		else:
			if selected_enemy_button:
				selected_enemy_button.play_animation(true)
			button_node.play_animation(false)
			selected_enemy_button = button_node
			for btn in enemy_buttons:
				if btn != selected_enemy_button:
					btn.disable()
			
			if enemy_button_map.has(mesh_name):
				var target_player = enemy_button_map[mesh_name]
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
		_on_end_turn_pressed()
	elif mesh_name == "BuildButton":
		deployment_screen.show_choices("Invest in a Sector:", GameManager.INVESTMENT_SECTORS, "INVESTMENT")
	elif mesh_name == "DeliveryButton":
		show_cards_on_deployment_screen(CardData.CardType.DELIVERY)
	elif mesh_name == "PayloadButton":
		show_cards_on_deployment_screen(CardData.CardType.PAYLOAD)
	elif mesh_name == "InfoWarButton":
		show_cards_on_deployment_screen(CardData.CardType.INFO_WAR)
	elif mesh_name == "UtilityButton":
		show_cards_on_deployment_screen(CardData.CardType.UTILITY)
	elif mesh_name == "DefenseButton":
		show_cards_on_deployment_screen(CardData.CardType.DEFENSE)

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
		Logger.log("--- INPUT SHIELD DISABLED after choice made (New State: %s) ---" % input_shield_collision_shape.disabled)
	else:
		Logger.log("ERROR: Cannot disable input shield, reference is null!")
	
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
		Logger.log("--- INPUT SHIELD DISABLED at end of turn (New State: %s) ---" % input_shield_collision_shape.disabled)
	else:
		Logger.log("ERROR: Cannot disable input shield, reference is null!")
		
	if end_turn_button:
		end_turn_button.play_animation() # Play press animation

	for button in all_buttons:
		button.disable()
	
	if light_anim_player:
		light_anim_player.play("Alarm_AI_TurnStart")
		
	if GameManager.is_player_action_valid():
		GameManager.process_player_attack()
	else:
		Logger.log("No action selected. Ending turn.")
		GameManager.pass_turn()

	if selected_enemy_button:
		_enemy_to_release = selected_enemy_button
		selected_enemy_button = null


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
			Logger.log("ERROR: Deployment screen reference is null in _on_input_shield_clicked!")

		# Disable the input shield's collision shape
		if input_shield_collision_shape:
			input_shield_collision_shape.disabled = true
			# --- DEBUG ---
			Logger.log("--- INPUT SHIELD DISABLED after click (New State: %s) ---" % input_shield_collision_shape.disabled)
		else:
			Logger.log("ERROR: Cannot disable input shield in _on_input_shield_clicked, reference is null!")

func _set_default_lighting():
	if overhead_light:
		overhead_light.light_energy = 5.0
	if ambient_light:
		ambient_light.light_energy = 0.5
	if left_fill_light:
		left_fill_light.light_color = Color(1, 1, 1, 1)
	if right_fill_light:
		right_fill_light.light_color = Color(1, 1, 1, 1)
