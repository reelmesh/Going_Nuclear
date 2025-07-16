# (This code is indented with tabs)
extends Node

signal game_state_changed
signal turn_started(player_state) # NEW SIGNAL

var active_players: Array = []
var current_player_index: int = 0
var is_game_running: bool = false
var main_deck: Array = []

var selected_delivery_card: CardData = null
var selected_payload_card: CardData = null
var selected_infowar_card: CardData = null
var selected_target: PlayerState = null
var build_cost: int = 25 # The cost in Treasury to build.
const AP_COST_BUILD = 1
const AP_COST_INFOWAR = 1
const AP_COST_CONVENTIONAL = 2 # The combined cost for Delivery + Payload

func start_new_game(faction_ids: Array, human_player_id: String):
	print("GameManager: Starting a new game!")
	active_players.clear()
	main_deck.clear()
	current_player_index = 0
	is_game_running = true
	for i in range(faction_ids.size()):
		var id = faction_ids[i]
		var data = FactionDatabase.get_faction_data(id)
		if data:
			# This logic is now safe because PlayerState is its own file.
			var is_ai_controlled = (id != human_player_id)
			var new_player = PlayerState.new(data, is_ai_controlled, i)
			active_players.append(new_player)
	setup_deck()
	deal_initial_cards(5)
	
	# The UI layer will call update_all_ui once the game is set up.

func setup_deck():
	main_deck = CardDatabase.get_all_card_ids()
	main_deck.shuffle()
	print("GameManager: Deck created and shuffled with %s cards." % main_deck.size())

func deal_initial_cards(amount: int):
	for player in active_players:
		for i in range(amount):
			if not main_deck.is_empty():
				player.hand.append(main_deck.pop_front())
				
func process_build_action():
	var player = get_human_player_state()
	if not player: return
	# --- Validation ---
	# Check if the player has enough AP and Treasury.
	if player.current_ap < AP_COST_BUILD: # Use the constant
		Logger.log("Not enough Action Points! (Needs %d)" % AP_COST_BUILD)
		return
	if player.current_treasury < build_cost:
		Logger.log("Not enough Treasury! (Needs %d)" % build_cost)
		return
		
	player.current_ap -= AP_COST_BUILD # Use the constant

	# --- Execution ---
	# Deduct the costs.
	player.current_ap -= 1
	player.current_treasury -= build_cost
	
	# Give the reward: draw 2 cards.
	draw_card(player)
	draw_card(player)
	
	Logger.log("Build successful! Gained 2 new assets. (%d AP remaining)" % player.current_ap)
	
	# Update the entire game UI to show new stats and cards.
	game_state_changed.emit()
	
func get_human_player_state() -> PlayerState:
	for p in active_players:
		if not p.is_ai:
			return p
	return null

func player_selected_card(p_card_data: CardData):
	match p_card_data.card_type:
		CardData.CardType.DELIVERY:
			selected_delivery_card = p_card_data
			selected_infowar_card = null
		CardData.CardType.PAYLOAD:
			selected_payload_card = p_card_data
			selected_infowar_card = null
		CardData.CardType.INFO_WAR:
			selected_infowar_card = p_card_data
			selected_delivery_card = null
			selected_payload_card = null

func draw_card(player_state: PlayerState):
	if not main_deck.is_empty():
		var new_card_id = main_deck.pop_front()
		player_state.hand.append(new_card_id)
		# We can log this to see what was drawn.
		Logger.log("%s drew: %s" % [player_state.faction_data.leader_name, new_card_id])
	else:
		# In a real game, we would shuffle the discard pile back into the deck here.
		Logger.log("The main deck is empty!")
		
func player_selected_target(p_player_state: PlayerState):
	selected_target = p_player_state

# --- GAME LOOP LOGIC ---

func process_player_attack():
	var attacker = get_human_player_state()
	if not attacker: return

	if selected_infowar_card and selected_target:
		if attacker.current_ap < AP_COST_INFOWAR:
			Logger.log("Not enough Action Points! InfoWar attack costs %d AP." % AP_COST_INFOWAR)
			return
			# Deduct cost and execute
		attacker.current_ap -= AP_COST_INFOWAR
		execute_infowar_attack(attacker, selected_target, selected_infowar_card)
		attacker.hand.erase(selected_infowar_card.resource_path.get_file().get_basename())
	elif selected_delivery_card and selected_payload_card and selected_target:
		if attacker.current_ap < AP_COST_CONVENTIONAL:
			Logger.log("Not enough Action Points! Conventional attack costs %d AP." % AP_COST_CONVENTIONAL)
			return
			# Deduct cost and execute
		attacker.current_ap -= AP_COST_CONVENTIONAL
		execute_conventional_attack(attacker, selected_target, selected_delivery_card, selected_payload_card)
		attacker.hand.erase(selected_delivery_card.resource_path.get_file().get_basename())
		attacker.hand.erase(selected_payload_card.resource_path.get_file().get_basename())
	else:
		Logger.log("Invalid selection for attack.")
		return

	selected_delivery_card = null
	selected_payload_card = null
	selected_infowar_card = null
	selected_target = null
	
	game_state_changed.emit()
	
	# If the player is out of AP, automatically end their turn.
	if attacker.current_ap <= 0:
		Logger.log("Out of Action Points. Ending turn automatically.")
		pass_turn()
	else:
		Logger.log("Action complete. %d AP remaining." % attacker.current_ap)
		
	# After the player's attack is done, move to the next turn.
	next_turn()

func start_turn():
	# TODO: Check for a winner first.
	var current_player = active_players[current_player_index]
	Logger.log("\n--- It's now %s's turn. ---" % current_player.faction_data.leader_name)
	
	# --- NEW: Resource Generation Phase ---
	# Reset AP to the faction's base value.
	current_player.current_ap = current_player.faction_data.base_action_points
	# Generate Treasury based on Population and Morale.
	var treasury_gain = 5 + (current_player.current_population / 10) * current_player.current_morale
	current_player.current_treasury += treasury_gain
	
	# --- NEW: Emit the signal here ---
	# Announce who the current player is so the UI can react.
	turn_started.emit(current_player) 
	
	# TODO: Process status effects like "Fallout" here.
	
	Logger.log("\n--- It's now %s's turn. ---" % current_player.faction_data.leader_name)
	Logger.log("%s gains %d Treasury. AP reset to %d." % [current_player.faction_data.leader_name, treasury_gain, current_player.current_ap])
	
	game_state_changed.emit() # Update the UI with new values
	
	if current_player.is_ai:
		process_ai_turn(current_player)
	else:
		Logger.log("Your turn! You have %d AP." % current_player.current_ap)
		# It's the human's turn again.
		Logger.log("Your turn! Select your cards and target.")
		# The UI is already interactive, so we don't need to do anything else.

func next_turn():
	current_player_index = (current_player_index + 1) % active_players.size()
	# TODO: Skip over any eliminated players.
	start_turn()

func process_ai_turn(ai_player: PlayerState):
	Logger.log("AI is thinking...")
	game_state_changed.emit() # Update UI to show it's the AI's turn
	await get_tree().create_timer(2.0).timeout # Use await to pause for 2 seconds
		# Hand control over to our new AIController script.
	AIController.take_turn(ai_player, active_players)
		# After the AI is done, update the UI and move to the next turn.
	game_state_changed.emit()
	next_turn()

# --- ATTACK EXECUTION HELPERS ---
func execute_conventional_attack(attacker: PlayerState, target: PlayerState, delivery: CardData, payload: CardData):
	Logger.log("%s launches a %s with a %s at %s!" % [attacker.faction_data.leader_name, delivery.card_name, payload.card_name, target.faction_data.leader_name])
	if randf() < delivery.success_chance:
		var damage = payload.damage
		Logger.log("DIRECT HIT! %s loses %s million people." % [target.faction_data.leader_name, damage])
		target.current_population -= damage
		if target.current_population < 0:
			target.current_population = 0
			Logger.log("%s has been annihilated!" % target.faction_data.leader_name)
	else:
		Logger.log("The attack was intercepted!")

func execute_infowar_attack(attacker: PlayerState, target: PlayerState, card: CardData):
	Logger.log("%s uses '%s' on %s!" % [attacker.faction_data.leader_name, card.card_name, target.faction_data.leader_name])
	var damage = card.damage
	Logger.log("It's super effective! %s loses %s million people to chaos and dissent." % [target.faction_data.leader_name, damage])
	target.current_population -= damage
	if target.current_population < 0:
		target.current_population = 0
		
		# NEW: A function to check if the player has a valid attack queued.
func is_player_action_valid() -> bool:
	if selected_infowar_card and selected_target:
		return true
	if selected_delivery_card and selected_payload_card and selected_target:
		return true
	return false

# NEW: A function to simply advance the turn without an attack.
func pass_turn():
	# Clear any lingering selections.
	selected_delivery_card = null
	selected_payload_card = null
	selected_infowar_card = null
	selected_target = null
	
	game_state_changed.emit()
	
	# Move to the next turn's logic.
	next_turn()
