# (This script is attached to the root of Console3D.tscn)
class_name ConsoleController
extends Node3D
# --- This script acts as a "receptionist" for our 3D console. ---
# It holds references to all the important nodes within this scene.

# NOTE: The paths below assume the labels are children of a SubViewport system.
# You will need to adjust these paths to match your exact scene structure.
# Example: $LogViewport/GameLogLabel

@onready var game_log_label = $console/GameLogScreen/LogViewport/Panel/GameLogLabel
@onready var player_info_label = $console/PlayerInfoScreen/LogViewport/Panel/PlayerInfoLabel
@onready var enemy_info_tl = $console/EnemyInfoScreen_TopLeft/LogViewport/Panel/EnemyInfoTopLeftLabel
@onready var enemy_info_bl = $console/EnemyInfoScreen_BottomLeft/LogViewport/Panel/EnemyInfoBottomLeftLabel
@onready var enemy_info_tr = $console/EnemyInfoScreen_TopRight/LogViewport/Panel/EnemyInfoTopRightLabel
@onready var enemy_info_br = $console/EnemyInfoScreen_BottomRight/LogViewport/Panel/EnemyInfoBottomRightLabel

# This function runs when the node is ready.
func _ready():
	# We will now test each of our own paths.
	print("--- ConsoleController Self-Check ---")
	if is_instance_valid(game_log_label):
		print("SUCCESS: Found GameLogLabel.")
	else:
		print("ERROR: Could not find GameLogLabel at the specified path.")
		
	if is_instance_valid(player_info_label):
		print("SUCCESS: Found PlayerInfoLabel.")
	else:
		print("ERROR: Could not find PlayerInfoLabel at the specified path.")

	if is_instance_valid(enemy_info_tr):
		print("SUCCESS: Found EnemyInfoTopRightLabel.")
	else:
		print("ERROR: Could not find EnemyInfoTopRightLabel at the specified path.")

	if is_instance_valid(enemy_info_tl):
		print("SUCCESS: Found EnemyInfoTopLeftLabel.")
	else:
		print("ERROR: Could not find EnemyInfoTopRightLabel at the specified path.")

	if is_instance_valid(enemy_info_br):
		print("SUCCESS: Found EnemyInfoBottomRightLabel.")
	else:
		print("ERROR: Could not find EnemyInfoTopRightLabel at the specified path.")

	if is_instance_valid(enemy_info_bl):
		print("SUCCESS: Found EnemyInfoBottomLeftLabel.")
	else:
		print("ERROR: Could not find EnemyInfoTopRightLabel at the specified path.")

	# ... (You can add checks for the other enemy labels if you wish)
	print("--- Self-Check Complete ---")
