# This script's job is to load all our FactionData resources into memory.
extends Node

var database: Dictionary = {}

func _ready():
	print("FactionDatabase: Loading all faction data...")
	load_factions_from_directory("res://data/factions/")
	print("FactionDatabase: Loading complete. Found %s factions." % database.size())

func load_factions_from_directory(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var faction_id = file_name.get_basename()
				
				# --- NEW DEBUGGING LINE ---
				# This will show us the exact ID being created for each file.
				print("...Found file '%s', creating database entry with ID: '%s'" % [file_name, faction_id])

				database[faction_id] = load(path + file_name)
			file_name = dir.get_next()
	else:
		print("Error: Could not open directory at path: " + path)

func get_faction_data(faction_id: String) -> FactionData:
	return database.get(faction_id, null) as FactionData

func get_all_faction_ids() -> Array:
	return database.keys()
