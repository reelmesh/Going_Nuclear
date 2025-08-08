# (This is the full, final script that listens to the EventBus)
extends Node2D

@onready var console_anim_player = $SubViewportContainer/SubViewport/Console3D/AnimationPlayer
@onready var interaction_controller: InteractionController = $SubViewportContainer/SubViewport/Console3D/Camera3D

var selected_enemy_button: PhysicalButton3D = null
var enemy_buttons: Array[PhysicalButton3D] = []

func _ready():
	GameManager.game_state_changed.connect(update_all_ui)
	GameManager.turn_started.connect(on_turn_started)
	
	# --- THIS IS THE FIX ---
	# We listen to the global EventBus. We no longer try to connect to the screen directly.
	EventBus.deployment_choice_made.connect(_on_deployment_choice_made)
	
	await get_tree().create_timer(0.1).timeout
	connect_3d_buttons()
	
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if console and console.game_log_label:
		Logger.log_label = console.game_log_label
		Logger.log("--- GAME LOG CONNECTION ESTABLISHED ---")
	
	setup_game()

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
	
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if not console or not console.deployment_screen: return
	var dep_screen = console.deployment_screen

	if mesh_name == "EndTurnButton":
		dep_screen.hide() # Close the menu if it's open
		_on_end_turn_pressed()
	elif mesh_name == "BuildButton":
		dep_screen.show_choices("Invest in a Sector:", GameManager.INVESTMENT_SECTORS, "INVESTMENT")
	elif mesh_name == "DeliveryButton":
		show_cards_of_type(CardData.CardType.DELIVERY)
	elif mesh_name == "PayloadButton":
		show_cards_of_type(CardData.CardType.PAYLOAD)
	elif mesh_name == "InfoWarButton":
		show_cards_of_type(CardData.CardType.INFO_WAR)
	elif mesh_name == "UtilityButton":
		show_cards_of_type(CardData.CardType.UTILITY)
	elif mesh_name == "DefenseButton":
		show_cards_of_type(CardData.CardType.DEFENSE)
		
func show_cards_of_type(card_type: int):
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if not console or not console.deployment_screen: return
	
	var title = CardData.CardType.keys()[card_type]
	var human_hand = GameManager.get_human_player_state().hand
	var choices = []
	for card_id in human_hand:
		var card_data = CardDatabase.get_card_data(card_id)
		if card_data and card_data.card_type == card_type:
			choices.append(card_data)
	
	if choices.is_empty():
		Logger.log("You have no cards of type: %s" % title)
		return
		
	console.deployment_screen.show_choices(title, choices, "CARD")
	
# --- THIS FUNCTION IS NOW "VERBOSE" ---
func _show_deployment_screen(choice_type: String, card_filter = -1):
	Logger.log("--- UI: Attempting to show deployment screen for type: %s ---" % choice_type)
	
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if not console:
		Logger.log("ERROR: Could not find ConsoleController node.")
		return
	
	if not console.deployment_screen:
		Logger.log("ERROR: ConsoleController does not have a valid reference to the deployment screen.")
		return
	
	Logger.log("SUCCESS: Found ConsoleController and DeploymentScreen instance.")
	
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
		Logger.log("No options of this type to show.")
		return
	
	Logger.log("Found %d choices. Calling show_choices() on DeploymentScreen." % choices.size())
	console.deployment_screen.show_choices(title, choices, choice_type)

func _on_deployment_choice_made(choice_data):
	var console: ConsoleController = $SubViewportContainer/SubViewport/Console3D
	if not console or not console.deployment_screen: return
	
	if choice_data is int:
		GameManager.process_build_action(choice_data)
	elif choice_data is CardData:
		Logger.log("You selected: %s" % choice_data.card_name)
		GameManager.player_selected_card(choice_data)
	
func _on_end_turn_pressed():
	if GameManager.is_player_action_valid():
		GameManager.process_player_attack()
	else:
		Logger.log("No action selected. Ending turn.")
		GameManager.pass_turn()

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
		console.enemy_info_tl, console.enemy_info_bl
	]
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
