# (This code is indented with tabs)
class_name AIController

static func take_turn(ai_player: PlayerState, all_players: Array) -> void:
	Logger.log("AIController is now in charge of %s." % ai_player.faction_data.leader_name)
	var target = choose_smarter_target(ai_player, all_players)
	if not target:
		Logger.log("%s can't find a valid target and ends their turn." % ai_player.faction_data.leader_name)
		return
	Logger.log("%s chose %s as a target." % [ai_player.faction_data.leader_name, target.faction_data.leader_name])
	var infowar_card_id = find_card_of_type(ai_player.hand, CardData.CardType.INFO_WAR)
	var delivery_card_id = find_card_of_type(ai_player.hand, CardData.CardType.DELIVERY)
	var payload_card_id = find_card_of_type(ai_player.hand, CardData.CardType.PAYLOAD)
	if infowar_card_id:
		var card_data = CardDatabase.get_card_data(infowar_card_id)
		GameManager.execute_infowar_attack(ai_player, target, card_data)
		ai_player.hand.erase(infowar_card_id)
	elif delivery_card_id and payload_card_id:
		var delivery_data = CardDatabase.get_card_data(delivery_card_id)
		var payload_data = CardDatabase.get_card_data(payload_card_id)
		GameManager.execute_conventional_attack(ai_player, target, delivery_data, payload_data)
		ai_player.hand.erase(delivery_card_id)
		ai_player.hand.erase(payload_card_id)
	else:
		Logger.log("%s doesn't have the right cards to attack and ends their turn." % ai_player.faction_data.leader_name)

# --- UPGRADED: This function now understands personality! ---
static func choose_smarter_target(ai_player: PlayerState, all_players: Array) -> PlayerState:
	var possible_targets: Array = []
	for p in all_players:
		if p != ai_player and p.current_population > 0:
			possible_targets.append(p)
	
	if possible_targets.is_empty():
		return null

	# --- PERSONALITY CHECK ---
	# Check if this AI has the "RUTHLESS" trait.
	if ai_player.faction_data.personality_traits.has(FactionData.Traits.RUTHLESS):
		Logger.log("%s is feeling RUTHLESS and looks for the weakest target..." % ai_player.faction_data.leader_name)
		# Sort targets by who has the LEAST population.
		possible_targets.sort_custom(func(a, b):
			return a.current_population < b.current_population
		)
		var weakest_target = possible_targets[0]
		Logger.log("The weakest target is %s." % weakest_target.faction_data.leader_name)
		return weakest_target
	
	# --- DEFAULT BEHAVIOR (Relationship-based) ---
	# If not ruthless, use the old logic.
	possible_targets.sort_custom(func(a, b):
		var id_a = a.faction_data.resource_path.get_file().get_basename()
		var id_b = b.faction_data.resource_path.get_file().get_basename()
		var score_a = ai_player.faction_data.relationships.get(id_a, 0)
		var score_b = ai_player.faction_data.relationships.get(id_b, 0)
		return score_a < score_b
	)

	var most_hated_target = possible_targets[0]
	Logger.log("Sorted targets by relationship. Most hated is %s." % most_hated_target.faction_data.leader_name)
	return most_hated_target

static func find_card_of_type(hand: Array, card_type: CardData.CardType) -> String:
	for card_id in hand:
		var card_data = CardDatabase.get_card_data(card_id)
		if card_data and card_data.card_type == card_type:
			return card_id
	return ""
