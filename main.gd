extends Node2D

# Preload our reusable scenes so we can create instances of them.
const PlayerPanelScene = preload("res://scenes/ui/PlayerPanel.tscn")
const CardScene = preload("res://scenes/ui/Card.tscn") # NEW: Preload the card scene

# Get references to the containers on our main scene.
# Make sure both have "Access as Scene Unique Name" enabled.
@onready var player_panel_container = %PlayerPanelContainer
@onready var hand_container = %HandContainer # NEW: Get the hand container

func _ready():
	setup_game()
	# NEW: Connect to a signal from the GameManager.
	# We will create this signal in the next step.
	GameManager.hand_updated.connect(generate_hand_ui)

func setup_game():
	var players_in_match = ["usa", "russia", "china"]
	var human_player = "usa"
	GameManager.start_new_game(players_in_match, human_player)
	generate_player_ui()
	generate_hand_ui() # NEW: Call this once at the start.

func generate_player_ui():
	for child in player_panel_container.get_children():
		child.queue_free()
	for player_state in GameManager.active_players:
		var new_panel = PlayerPanelScene.instantiate()
		player_panel_container.add_child(new_panel)
		new_panel.update_display(player_state)

# --- NEW FUNCTION: GENERATE HAND UI ---
func generate_hand_ui():
	# First, clear any old cards from the display.
	for child in hand_container.get_children():
		child.queue_free()
		
	# Find the human player's state.
	var human_player_state = null
	for p in GameManager.active_players:
		if not p.is_ai:
			human_player_state = p
			break
			
	if human_player_state == null:
		return # No human player found, do nothing.

	# Loop through the card IDs in the human player's hand.
	for card_id in human_player_state.hand:
		# Get the full card data from our database.
		var card_data = CardDatabase.get_card_data(card_id)
		if card_data:
			# Create a new instance of our Card scene.
			var new_card = CardScene.instantiate()
			
			# Add it to our hand container on screen.
			hand_container.add_child(new_card)
			
			# Call the card's function to update its display.
			new_card.update_display(card_data)
