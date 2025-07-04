# The new "brain" of our game. Manages the active game state and turn loop.
extends Node

signal hand_updated # NEW: Add this signal declaration.

# --- Game State Variables ---
var active_players: Array = []
var current_player_index: int = 0
var is_game_running: bool = false
var main_deck: Array = [] # NEW: The deck of cards for the current game.

# This is a template for an active player's data during a match.
class PlayerState:
	var faction_data: FactionData
	var current_population: int
	var is_ai: bool
	var player_index: int
	var hand: Array = [] # NEW: Each player now has a hand to hold cards.

	func _init(p_faction_data: FactionData, p_is_ai: bool, p_index: int):
		self.faction_data = p_faction_data
		self.is_ai = p_is_ai
		self.player_index = p_index
		self.current_population = p_faction_data.starting_population

# --- Public Functions (called from other scripts) ---

func start_new_game(faction_ids: Array, human_player_id: String):
	print("GameManager: Starting a new game!")
	active_players.clear()
	main_deck.clear() # NEW: Clear the deck.
	current_player_index = 0
	is_game_running = true

	# Create PlayerState objects for each faction in the match.
	for i in range(faction_ids.size()):
		var id = faction_ids[i]
		var data = FactionDatabase.get_faction_data(id)
		if data:
			var is_player_ai = (id != human_player_id)
			var new_player = PlayerState.new(data, is_player_ai, i)
			active_players.append(new_player)
		else:
			print("ERROR: Could not find faction data for ID: '" + id + "'")
	
	if active_players.is_empty():
		print("FATAL ERROR: No valid players could be created.")
		is_game_running = false
		return
	
	# --- NEW: CARD DEALING LOGIC ---
	setup_deck()
	deal_initial_cards(5) # Deal 5 cards to each player.
	# --- END OF NEW LOGIC ---
	
	print_player_status()
	start_turn()

# --- NEW: CARD MANAGEMENT FUNCTIONS ---
func setup_deck():
	# Get all card IDs from our new database.
	main_deck = CardDatabase.get_all_card_ids()
	# For a real game, you might add multiple copies of some cards.
	# For now, one of each is fine.
	main_deck.shuffle()
	print("GameManager: Deck created and shuffled with %s cards." % main_deck.size())

func deal_initial_cards(amount: int):
	for player in active_players:
		for i in range(amount):
			# Make sure the deck isn't empty.
			if not main_deck.is_empty():
				# Take the top card from the deck and add it to the player's hand.
				player.hand.append(main_deck.pop_front())

func draw_card(player_state: PlayerState):
	if not main_deck.is_empty():
		var card_id = main_deck.pop_front()
		player_state.hand.append(card_id)
		print("%s draws a card: %s" % [player_state.faction_data.leader_name, card_id])
		# If the player who drew is the human player, update the UI.
		if not player_state.is_ai:
			hand_updated.emit() # NEW: Emit the signal here.

# --- Internal Game Loop ---

func start_turn():
	if not is_game_running: return
	
	var current_player: PlayerState = active_players[current_player_index]
	print("\n--- It's %s's turn. ---" % current_player.faction_data.leader_name)
	
	# Let's draw a card at the start of each turn.
	draw_card(current_player)
	
	if current_player.is_ai:
		print("AI is thinking...")
		await get_tree().create_timer(1.0).timeout
		print("AI turn complete.")
		next_turn()
	else:
		print("This is your turn. Your hand contains:")
		for card_id in current_player.hand:
			var card_data = CardDatabase.get_card_data(card_id)
			print("  - %s (%s)" % [card_data.card_name, CardData.CardType.keys()[card_data.card_type]])

func next_turn():
	print("Moving to the next turn...")
	current_player_index = (current_player_index + 1) % active_players.size()
	start_turn()

func print_player_status():
	print("--- CURRENT STATUS ---")
	for p in active_players:
		print("%s (%s) has %s million people." % [p.faction_data.faction_name, p.faction_data.leader_name, p.current_population])
	print("----------------------")
