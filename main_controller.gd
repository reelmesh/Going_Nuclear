# (This is the full, correct script for your Main scene)
extends Node2D

@onready var console_anim_player = $SubViewportContainer/SubViewport/Console3D/AnimationPlayer

# This will now store the MESH NAME of the selected button.
#var selected_enemy_mesh_name: String = ""
# --- UPDATED: This variable now holds our CORRECT class type ---
var selected_enemy_button: PhysicalButton3D = null
# This array will hold references to all enemy buttons for easy access.
var enemy_buttons: Array[PhysicalButton3D] = []

func _ready():
	GameManager.game_state_changed.connect(update_all_ui)
	GameManager.turn_started.connect(on_turn_started)
	EventBus.deployment_choice_made.connect(_on_deployment_choice_made)
	
	await get_tree().create_timer(0.1).timeout
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	var interaction_controller: Camera3D = $SubViewportContainer/SubViewport/Console3D/Camera3D
	
	# Initialize the deployment screen, giving it the reference it needs.
	if console and console.deployment_screen and interaction_controller:
		console.deployment_screen.initialize(interaction_controller)
		# Connect to its signal here, once.
		console.deployment_screen.choice_made.connect(_on_deployment_choice_made)
	
	connect_3d_buttons()
	setup_game()

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
	Logger.log("3D Button Pressed: %s" % mesh_name)
	
	var button_node: PhysicalButton3D = find_button_by_mesh_name(mesh_name)
	if not button_node: return
	
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

	if mesh_name == "EndTurnButton":
		var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
		if console and console.deployment_screen:
			console.deployment_screen.hide_screen()
		_on_end_turn_pressed()
	elif mesh_name == "BuildButton":
		_show_deployment_screen("INVESTMENT")
	elif mesh_name == "DeliveryButton":
		_show_deployment_screen("CARD", CardData.CardType.DELIVERY)
	elif mesh_name == "PayloadButton":
		_show_deployment_screen("CARD", CardData.CardType.PAYLOAD)
	elif mesh_name == "InfoWarButton":
		_show_deployment_screen("CARD", CardData.CardType.INFO_WAR)
	elif mesh_name == "UtilityButton":
		_show_deployment_screen("CARD", CardData.CardType.UTILITY)
	elif mesh_name == "DefenseButton":
		_show_deployment_screen("CARD", CardData.CardType.DEFENSE)
		
# --- THIS IS THE MISSING FUNCTION, NOW RESTORED ---
func _show_deployment_screen(choice_type: String, card_filter = -1):
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if not console or not console.deployment_screen: return
	var dep_screen = console.deployment_screen
	
	var choices = []
	var title = ""
	
	if choice_type == "INVESTMENT":
		title = "Invest in a Sector:"
		choices = GameManager.INVESTMENT_SECTORS
	elif choice_type == "CARD":
		title = CardData.CardType.keys()[card_filter]
		var human_hand = GameManager.get_human_player_state().hand
		for card_id in human_hand:
			var card_data = CardDatabase.get_card_data(card_id)
			if card_data and card_data.card_type == card_filter:
				choices.append(card_data)
	
	if choices.is_empty():
		Logger.log("You have no options of that type.")
		return
		
	dep_screen.show_choices(title, choices, choice_type)
	
func _on_deployment_choice_made(choice_data):
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if not console or not console.deployment_screen: return
	
	if choice_data is int:
		GameManager.process_build_action(choice_data)
	elif choice_data is CardData:
		Logger.log("You selected: %s" % choice_data.card_name)
		GameManager.player_selected_card(choice_data)
	
	console.deployment_screen.hide_screen()
# --- Rule 3: Turn-Based Reset ---
func on_turn_started(player_state: PlayerState):
	if player_state.is_ai:
		set_player_controls_enabled(false)
	else:
		set_player_controls_enabled(true)
		# Auto-release the selected button at the start of our turn.
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

# --- THIS IS THE NEW, CLEANER UPDATE FUNCTION ---
# --- The generate_player_ui function has been moved inside update_all_ui for clarity ---

func update_all_ui():
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if not console: return

	# --- 1. Update Player Info ---
	var human_player = GameManager.get_human_player_state()
	if human_player and console.player_info_label:
		var player_text = "TREASURY: $%sT\nMORALE: %s%%\nAP: %s" % [
			human_player.current_treasury,
			int(human_player.current_morale * 100),
			human_player.current_ap
		]
		console.player_info_label.text = player_text
		
	# --- 2. Update Enemy Info & Avatars ---
	var enemy_labels = [console.enemy_info_tr, console.enemy_info_br, console.enemy_info_tl, console.enemy_info_bl]
	# --- THIS IS THE FIX: Use the correct variable names ---
	var avatar_images = [console.avatar_image_tr, console.avatar_image_br, console.avatar_image_tl, console.avatar_image_bl]
	
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

# --- THIS IS THE UPGRADED FUNCTION WITH ERROR REPORTING ---
func generate_player_ui():
	Logger.log("--- UI: Starting generate_player_ui ---")
	
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if not console:
		Logger.log("ERROR: Could not find ConsoleController node. Aborting UI generation.")
		return
	
	# These arrays are correct.
	var avatar_images = [
		console.avatar_image_tr, console.avatar_image_br,
		console.avatar_image_tl, console.avatar_image_bl
	]
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
		# --- NEW: Get a reference to the avatar image for this slot ---
		var avatar_image_node = avatar_images[i]
		
		# Safety checks for both nodes.
		if not is_instance_valid(label_node) or not is_instance_valid(avatar_image_node):
			Logger.log("ERROR: UI node for enemy slot %d is invalid or null." % i)
			continue

		if i < ai_players.size():
			var ai = ai_players[i]
			Logger.log("Updating slot %d for: %s" % [i, ai.faction_data.faction_name])
			if ai and ai.faction_data:
				# This part is correct.
				label_node.text = "%s\n%s\nPop: %sM" % [
					ai.faction_data.faction_name,
					ai.faction_data.leader_name,
					ai.current_population
				]
				# --- NEW: Tell the avatar image what texture to display ---
				avatar_image_node.texture = ai.faction_data.avatar
		else:
			# If no AI for this slot, clear both the text and the avatar.
			Logger.log("Clearing unused enemy slot %d." % i)
			label_node.text = ""
			# --- NEW: Clear the texture for the unused slot ---
			avatar_image_node.texture = null
	
	Logger.log("--- UI: Finished generate_player_ui ---")
	
func _on_action_button_pressed(card_type_to_show: CardData.CardType):
	var human_hand = GameManager.get_human_player_state().hand
	var cards_in_category: Array = []
	for card_id in human_hand:
		var card_data = CardDatabase.get_card_data(card_id)
		if card_data and card_data.card_type == card_type_to_show:
			# Pass the full CardData object
			cards_in_category.append(card_data)
	
	if cards_in_category.is_empty():
		Logger.log("You have no cards of that type.")
		return
		
	var dep_screen = get_deployment_screen()
	dep_screen.show_choices(CardData.CardType.keys()[card_type_to_show], cards_in_category, "CARD")
	dep_screen.choice_made.connect(_on_card_chosen_from_deployment_screen)

func _on_card_chosen_from_deployment_screen(card_data: CardData):
	Logger.log("You selected: %s" % card_data.card_name)
	GameManager.player_selected_card(card_data)
	get_deployment_screen().hide()
	get_deployment_screen().choice_made.disconnect(_on_card_chosen_from_deployment_screen)

func get_deployment_screen() -> DeploymentScreen:
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	return console.deployment_screen
