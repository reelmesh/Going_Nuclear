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

static func choose_smarter_target(ai_player: PlayerState, all_players: Array) -> PlayerState:
	var possible_targets: Array = []
	for p in all_players:
		if p != ai_player and p.current_population > 0:
			possible_targets.append(p)
	if possible_targets.is_empty():
		return null
	possible_targets.sort_custom(func(a, b):
		var id_a = a.faction_data.resource_path.get_file().get_basename()
		var id_b = b.faction_data.resource_path.get_file().get_basename()
		var score_a = ai_player.faction_data.relationships.get(id_a, 0)
		var score_b = ai_player.faction_data.relationships.get(id_b, 0)
		return score_a < score_b
	)

	# --- THE FIX IS HERE ---
	# Create the array of names first.
	var target_names = possible_targets.map(func(p): return p.faction_data.leader_name)
	# Log the array by converting it to a string.
	Logger.log("Sorted targets by relationship: " + str(target_names))
	
	return possible_targets[0]

static func find_card_of_type(hand: Array, card_type: CardData.CardType) -> String:
	for card_id in hand:
		var card_data = CardDatabase.get_card_data(card_id)
		if card_data and card_data.card_type == card_type:
			return card_id
	return ""
