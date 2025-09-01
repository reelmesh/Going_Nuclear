# (This is the full, final, and correct GameManager script)
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

const INVESTMENT_SECTORS = [
	{"id": 0, "name": "Nuclear Program", "ap_cost": 2, "treasury_cost": 100, "type": CardData.CardType.PAYLOAD},
	{"id": 1, "name": "Aerospace & Ballistics", "ap_cost": 2, "treasury_cost": 80, "type": CardData.CardType.DELIVERY},
	{"id": 2, "name": "Cyber Warfare Division", "ap_cost": 1, "treasury_cost": 50, "type": CardData.CardType.INFO_WAR},
	{"id": 3, "name": "Intelligence Agency", "ap_cost": 1, "treasury_cost": 40, "type": CardData.CardType.UTILITY},
	{"id": 4, "name": "Civil Defense Initiative", "ap_cost": 1, "treasury_cost": 30, "type": CardData.CardType.DEFENSE}
]

var selected_delivery_card: CardData = null
var selected_payload_card: CardData = null
var selected_infowar_card: CardData = null
var selected_target: PlayerState = null

func start_new_game(faction_ids: Array):
	active_players.clear()
	main_deck.clear()
	current_player_index = 0
	is_game_running = true
	var human_faction_data = FactionData.new()
	human_faction_data.faction_name = "Your Nation"
	human_faction_data.leader_name = "The President"
	human_faction_data.starting_population = 100
	human_faction_data.starting_treasury = 150
	human_faction_data.starting_morale = 0.80
	human_faction_data.base_action_points = 3
	var human_player_state = PlayerState.new(human_faction_data, false, 0)
	active_players.append(human_player_state)
	var ai_player_index = 1
	for id in faction_ids:
		var data = FactionDatabase.get_faction_data(id)
		if data:
			var new_ai_player = PlayerState.new(data, true, ai_player_index)
			active_players.append(new_ai_player)
			ai_player_index += 1
	setup_deck()
	deal_initial_cards(5)

func setup_deck():
	main_deck = CardDatabase.get_all_card_ids()
	main_deck.append_array(CardDatabase.get_all_card_ids())
	main_deck.append_array(CardDatabase.get_all_card_ids())
	main_deck.shuffle()
	Logger.log("GameManager: Deck created and shuffled with %s cards." % main_deck.size())

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

func get_current_player() -> PlayerState:
	if active_players.is_empty():
		return null
	return active_players[current_player_index]

func find_random_card_of_type(card_type: CardData.CardType) -> String:
	var card_pool = CardDatabase.get_card_ids_by_type(card_type)
	if not card_pool.is_empty():
		return card_pool.pick_random()
	return ""

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

func process_build_action(sector_id: int):
	var player = get_human_player_state()
	if not player: return
	var sector = INVESTMENT_SECTORS[sector_id]
	if player.current_ap < sector.ap_cost:
		Logger.log("Not enough AP!")
		return
	if player.current_treasury < sector.treasury_cost:
		Logger.log("Not enough Treasury!")
		return
	player.current_ap -= sector.ap_cost
	player.current_treasury -= sector.treasury_cost
	var card_to_draw = find_random_card_of_type(sector.type)
	if card_to_draw:
		player.hand.append(card_to_draw)
		Logger.log("Build successful! Acquired: %s" % card_to_draw)
	else:
		Logger.log("Build failed: No cards of that type available to draw.")
	game_state_changed.emit()

# Additional function to get sector information for UI display
func get_investment_sector(sector_id: int) -> Dictionary:
	return INVESTMENT_SECTORS[sector_id]

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
	if damage > 0:
		Logger.log("It's super effective! %s loses %s million people to chaos and dissent." % [target.faction_data.faction_name, damage])
		target.current_population -= damage
		if target.current_population < 0:
			target.current_population = 0
