# (This code is indented with tabs)
# This script is now attached to the UILayer CanvasLayer.
extends CanvasLayer

const PlayerPanelScene = preload("res://scenes/ui/PlayerPanel.tscn")
const CardChooserScene = preload("res://scenes/ui/CardChooser.tscn")
const PlaceholderButtonScene = preload("res://scenes/ui/PlaceHolderButton.tscn")

# --- UPDATED: These paths are now simple because the script and nodes are siblings ---
# Make sure these nodes have "Access as Scene Unique Name" enabled.
@onready var enemy_panels_left = %EnemyPanel_Left
@onready var enemy_panels_right = %EnemyPanel_Right
@onready var action_buttons_container = %ActionButtons
@onready var game_log_label = %GameLog
@onready var end_turn_button = %EndTurn_Button
@onready var player_treasury_label = %PlayerTreasuryLabel
@onready var player_morale_label = %PlayerMoraleLabel
@onready var player_ap_label = %PlayerAPLabel

var selected_target_node: PlayerPanel = null

# The _ready function is now called when the UILayer is ready.
func _ready():
	Logger.log_label = game_log_label
	GameManager.game_state_changed.connect(update_all_ui)
	GameManager.turn_started.connect(on_turn_started)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	
	# We still kick off the game setup from here.
	setup_game()

func _on_end_turn_pressed():
	if GameManager.is_player_action_valid():
		GameManager.process_player_attack()
	else:
		Logger.log("No action selected. Ending turn.")
		GameManager.pass_turn()

func setup_game():
	var players_in_match = ["usa", "russia", "china"]
	var human_player = "usa"
	GameManager.start_new_game(players_in_match, human_player)
	update_all_ui()
	GameManager.start_turn()

func update_all_ui():
	var human_player = GameManager.get_human_player_state()
	if human_player:
		player_treasury_label.text = "Treasury: $%sT" % human_player.current_treasury
		player_morale_label.text = "Morale: %s%%" % int(human_player.current_morale * 100)
		player_ap_label.text = "Action Points: %s" % human_player.current_ap
	generate_player_ui()
	generate_action_buttons()
	if selected_target_node: selected_target_node.deselect()
	selected_target_node = null

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

	# --- The "Build" Button ---
	var build_button = PlaceholderButtonScene.instantiate()
	build_button.text = "Build (1 AP)"
	action_buttons_container.add_child(build_button)
	build_button.pressed.connect(GameManager.process_build_action)

	# --- The Card Category Buttons ---
	var card_categories = {
		"Delivery": CardData.CardType.DELIVERY,
		"Payload": CardData.CardType.PAYLOAD,
		"InfoWar": CardData.CardType.INFO_WAR,
	}
	for category_name in card_categories:
		# We instantiate our custom scene instead of creating a generic button.
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
	var chooser = CardChooserScene.instantiate()
	add_child(chooser)
	chooser.initialize(CardData.CardType.keys()[card_type_to_show], cards_in_category)
	chooser.card_chosen.connect(_on_card_chosen_from_chooser)

func _on_card_chosen_from_chooser(card_data: CardData):
	Logger.log("You selected: %s" % card_data.card_name)
	GameManager.player_selected_card(card_data)

func generate_player_ui():
	for child in enemy_panels_left.get_children():
		child.queue_free()
	for child in enemy_panels_right.get_children():
		child.queue_free()
	var right_col_count = 0
	for player_state in GameManager.active_players:
		if player_state.is_ai:
			var new_panel = PlayerPanelScene.instantiate()
			if right_col_count < (GameManager.active_players.size() - 1) / 2.0:
				enemy_panels_right.add_child(new_panel)
				right_col_count += 1
			else:
				enemy_panels_left.add_child(new_panel)
			new_panel.update_display(player_state)
			new_panel.panel_selected.connect(_on_target_panel_selected)

func _on_target_panel_selected(panel_node: PlayerPanel):
	var player_data = panel_node.player_state
	GameManager.player_selected_target(player_data)
	if selected_target_node:
		selected_target_node.deselect()
	selected_target_node = panel_node
	selected_target_node.select()
