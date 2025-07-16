# (This code is indented with tabs)
extends Node2D

const PlayerPanelScene = preload("res://scenes/ui/PlayerPanel.tscn")
const CardChooserScene = preload("res://scenes/ui/CardChooser.tscn")
const PlaceholderButtonScene = preload("res://scenes/ui/PlaceholderButton.tscn")

@onready var enemy_panel_tl = %EnemyPanel_TopLeft
@onready var enemy_panel_bl = %EnemyPanel_BottomLeft
@onready var enemy_panel_tr = %EnemyPanel_TopRight
@onready var enemy_panel_br = %EnemyPanel_BottomRight
@onready var avatar_panel_tl = %EnemyAvatarTopLeft
@onready var avatar_panel_bl = %EnemyAvatarBottomLeft
@onready var avatar_panel_tr = %EnemyAvatarTopRight
@onready var avatar_panel_br = %EnemyAvatarBottomRight
@onready var action_buttons_container = %ActionButtons
@onready var game_log_label = %GameLog
@onready var end_turn_button = %EndTurn_Button
@onready var player_treasury_label = %PlayerTreasuryLabel
@onready var player_morale_label = %PlayerMoraleLabel
@onready var player_ap_label = %PlayerAPLabel

var selected_target_node: PlayerPanel = null

func _ready():
	Logger.log_label = game_log_label
	GameManager.game_state_changed.connect(update_all_ui)
	GameManager.turn_started.connect(on_turn_started)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
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
	var chooser = CardChooserScene.instantiate()
	$UILayer.add_child(chooser)
	chooser.initialize(CardData.CardType.keys()[card_type_to_show], cards_in_category)
	chooser.card_chosen.connect(_on_card_chosen_from_chooser)

func _on_card_chosen_from_chooser(card_data: CardData):
	Logger.log("You selected: %s" % card_data.card_name)
	GameManager.player_selected_card(card_data)

func generate_player_ui():
	var ui_panel_containers = [enemy_panel_tr, enemy_panel_br, enemy_panel_tl, enemy_panel_bl]
	var avatar_panels = [avatar_panel_tr, avatar_panel_br, avatar_panel_tl, avatar_panel_bl]
	for container in ui_panel_containers:
		for child in container.get_children():
			child.queue_free()
	for panel in avatar_panels:
		panel.self_modulate = Color(1, 1, 1, 0) # Hide by default
		# Clear old styles
		panel.remove_theme_stylebox_override("panel")
	var panel_index = 0
	for player_state in GameManager.active_players:
		if player_state.is_ai:
			if panel_index >= ui_panel_containers.size():
				break
			var target_ui_container = ui_panel_containers[panel_index]
			var target_avatar_panel = avatar_panels[panel_index]
			var new_ui_panel = PlayerPanelScene.instantiate()
			target_ui_container.add_child(new_ui_panel)
			new_ui_panel.update_display(player_state, true)
			new_ui_panel.panel_selected.connect(_on_target_panel_selected)
			if player_state.faction_data.avatar:
				var stylebox = StyleBoxTexture.new()
				stylebox.texture = player_state.faction_data.avatar
				# --- THIS IS THE FIX ---
				stylebox.content_margin_left = 4.0
				stylebox.content_margin_right = 4.0
				stylebox.content_margin_top = 4.0
				stylebox.content_margin_bottom = 4.0
				target_avatar_panel.add_theme_stylebox_override("panel", stylebox)
				target_avatar_panel.self_modulate = Color(1, 1, 1, 1) # Make visible
			panel_index += 1

func _on_target_panel_selected(panel_node: PlayerPanel):
	var player_data = panel_node.player_state
	GameManager.player_selected_target(player_data)
	if selected_target_node:
		selected_target_node.deselect()
	selected_target_node = panel_node
	selected_target_node.select()
