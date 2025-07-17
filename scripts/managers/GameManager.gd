# (This code is indented with tabs)
extends Node

signal game_state_changed
signal turn_started(player_state)

var active_players: Array[PlayerState] = []
var current_player_index: int = 0
var is_game_running: bool = false
var main_deck: Array = []
var build_cost: int = 25

const AP_COST_BUILD = 1
const AP_COST_INFOWAR = 1
const AP_COST_CONVENTIONAL = 2

var selected_delivery_card: CardData = null
var selected_payload_card: CardData = null
var selected_infowar_card: CardData = null
var selected_target: PlayerState = null

func start_new_game(faction_ids: Array):
	print("GameManager: Starting a new 4 vs 1 game!")
	active_players.clear()
	main_deck.clear()
	current_player_index = 0
	is_game_running = true

	# Create the placeholder FactionData object in code just for the player.
	var human_faction_data = FactionData.new()
	# --- THIS IS THE FIX ---
	# The property is 'faction_name', not 'name'.
	human_faction_data.faction_name = "Your Nation"
	human_faction_data.leader_name = "The President"
	human_faction_data.starting_population = 100
	human_faction_data.starting_treasury = 150
	human_faction_data.starting_morale = 0.80
	human_faction_data.base_action_points = 3
	
	var human_player_state = PlayerState.new(human_faction_data, false, 0)
	active_players.append(human_player_state)

	# Create the 4 AI Factions
	var ai_player_index = 1
	for id in faction_ids:
		var data = FactionDatabase.get_faction_data(id)
		if data:
			var new_ai_player = PlayerState.new(data, true, ai_player_index)
			active_players.append(new_ai_player)
			ai_player_index += 1

	setup_deck()
	deal_initial_cards(5)

# --- THIS IS THE MISSING FUNCTION, RESTORED PERMANENTLY ---
func setup_deck():
	main_deck = CardDatabase.get_all_card_ids()
	# Let's add multiple copies to make the deck bigger
	main_deck.append_array(CardDatabase.get_all_card_ids())
	main_deck.append_array(CardDatabase.get_all_card_ids())
	main_deck.shuffle()
	Logger.log("GameManager: Deck created and shuffled with %s cards." % main_deck.size())
# --- END OF RESTORED FUNCTION ---

func deal_initial_cards(amount: int):
	for player in active_players:
		for i in range(amount):
			draw_card(player)

func draw_card(player_state: PlayerState):
	if not main_deck.is_empty():
		var new_card_id = main_deck.pop_front()
		player_state.hand.append(new_card_id)
		Logger.log("%s drew: %s" % [player_state.faction_data.faction_name, new_card_id])
	else:
		Logger.log("The main deck is empty!")

func get_human_player_state() -> PlayerState:
	if not active_players.is_empty() and not active_players[0].is_ai:
		return active_players[0]
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

func player_selected_target(p_player_state: PlayerState):
	selected_target = p_player_state

func start_turn():
	if active_players.is_empty(): return
	var current_player = active_players[current_player_index]
	
	current_player.current_ap = current_player.faction_data.base_action_points
	var treasury_gain = 5 + int(current_player.current_population / 10.0 * current_player.current_morale)
	current_player.current_treasury += treasury_gain
	
	Logger.log("\n--- It's now %s's turn. ---" % current_player.faction_data.faction_name)
	Logger.log("%s gains %d Treasury. AP reset to %d." % [current_player.faction_data.faction_name, treasury_gain, current_player.current_ap])
	
	turn_started.emit(current_player)
	
	if current_player.is_ai:
		process_ai_turn(current_player)
	else:
		game_state_changed.emit()

func next_turn():
	current_player_index = (current_player_index + 1) % active_players.size()
	start_turn()

func process_ai_turn(ai_player: PlayerState):
	Logger.log("%s is thinking..." % ai_player.faction_data.faction_name)
	game_state_changed.emit()
	await get_tree().create_timer(2.0).timeout
	AIController.take_turn(ai_player, active_players)
	game_state_changed.emit()
	next_turn()

func process_build_action():
	var player = get_human_player_state()
	if not player: return
	if player.current_ap < AP_COST_BUILD:
		Logger.log("Not enough Action Points! (Needs %d)" % AP_COST_BUILD)
		return
	if player.current_treasury < build_cost:
		Logger.log("Not enough Treasury! (Needs %d)" % build_cost)
		return
	player.current_ap -= AP_COST_BUILD
	player.current_treasury -= build_cost
	draw_card(player)
	draw_card(player)
	Logger.log("Build successful! Gained 2 new assets. (%d AP remaining)" % player.current_ap)
	game_state_changed.emit()

func is_player_action_valid() -> bool:
	if selected_infowar_card and selected_target:
		return true
	if selected_delivery_card and selected_payload_card and selected_target:
		return true
	return false

func pass_turn():
	selected_delivery_card = null
	selected_payload_card = null
	selected_infowar_card = null
	selected_target = null
	game_state_changed.emit()
	next_turn()

func process_player_attack():
	var attacker = get_human_player_state()
	if not attacker: return

	if selected_infowar_card and selected_target:
		if attacker.current_ap < AP_COST_INFOWAR:
			Logger.log("Not enough Action Points! InfoWar attack costs %d AP." % AP_COST_INFOWAR)
			return
		attacker.current_ap -= AP_COST_INFOWAR
		execute_infowar_attack(attacker, selected_target, selected_infowar_card)
		attacker.hand.erase(selected_infowar_card.resource_path.get_file().get_basename())
	elif selected_delivery_card and selected_payload_card and selected_target:
		if attacker.current_ap < AP_COST_CONVENTIONAL:
			Logger.log("Not enough Action Points! Conventional attack costs %d AP." % AP_COST_CONVENTIONAL)
			return
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
	
	if attacker.current_ap <= 0:
		Logger.log("Out of Action Points. Ending turn automatically.")
		pass_turn()
	else:
		Logger.log("Action complete. %d AP remaining." % attacker.current_ap)
		game_state_changed.emit()

func execute_conventional_attack(attacker: PlayerState, target: PlayerState, delivery: CardData, payload: CardData):
	Logger.log("%s launches a %s with a %s at %s!" % [attacker.faction_data.faction_name, delivery.card_name, payload.card_name, target.faction_data.faction_name])
	if randf() < delivery.success_chance:
		var damage = payload.damage
		Logger.log("DIRECT HIT! %s loses %s million people." % [target.faction_data.faction_name, damage])
		target.current_population -= damage
		if target.current_population < 0:
			target.current_population = 0
			Logger.log("%s has been annihilated!" % target.faction_data.faction_name)
	else:
		Logger.log("The attack was intercepted!")

func execute_infowar_attack(attacker: PlayerState, target: PlayerState, card: CardData):
	Logger.log("%s uses '%s' on %s!" % [attacker.faction_data.faction_name, card.card_name, target.faction_data.faction_name])
	var damage = card.damage
	Logger.log("It's super effective! %s loses %s million people to chaos and dissent." % [target.faction_data.faction_name, damage])
	target.current_population -= damage
	if target.current_population < 0:
		target.current_population = 0
