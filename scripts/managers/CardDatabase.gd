# This script loads all CardData resources into memory.
# It acts as a central, read-only database for all possible cards in the game.
extends Node

var database: Dictionary = {}

func _ready():
	print("CardDatabase: Loading all card data...")
	load_cards_from_directory("res://data/cards/")
	print("CardDatabase: Loading complete. Found %s cards." % database.size())

func load_cards_from_directory(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var card_id = file_name.get_basename()
				database[card_id] = load(path + file_name)
			file_name = dir.get_next()
	else:
		print("ERROR: Could not open directory at path: " + path)

# Public function to get a single card's data by its ID.
func get_card_data(card_id: String) -> CardData:
	return database.get(card_id, null) as CardData

# Public function to get a list of all available card IDs.
func get_all_card_ids() -> Array:
	return database.keys()

# A useful helper to get all card IDs of a specific type.
func get_card_ids_by_type(card_type: CardData.CardType) -> Array:
	var results: Array = []
	for card_id in database:
		var card: CardData = database[card_id]
		if card.card_type == card_type:
			results.append(card_id)
	return results
