# (This script is attached to the root of Console3D.tscn)
class_name ConsoleController
extends Node3D
# --- This script acts as a "receptionist" for our 3D console. ---
# It holds references to all the important nodes within this scene.

# NOTE: The paths below assume the labels are children of a SubViewport system.
# You will need to adjust these paths to match your exact scene structure.
# Example: $LogViewport/GameLogLabel

# --- Avatar Screens ---
# These are the 2D scenes that act as "slide projectors"
# --- References to the TextureRects inside each screen's SubViewport ---
@onready var avatar_image_tr: TextureRect = $console/AvatarScreens/console/EnemyAvatarScreen_TopRight/SubViewport/AvatarImage_TopRight
@onready var avatar_image_br: TextureRect = $console/AvatarScreens/console/EnemyAvatarScreen_BottomRight/SubViewport/AvatarImage_BottomRight
@onready var avatar_image_tl: TextureRect = $console/AvatarScreens/console/EnemyAvatarScreen_TopLeft/SubViewport/AvatarImage_TopLeft
@onready var avatar_image_bl: TextureRect = $console/AvatarScreens/console/EnemyAvatarScreen_BottomLeft/SubViewport/AvatarImage_BottomLeft
#@onready var deployment_screen: DeploymentUI = $console/MainScreen/SubViewport/DeploymentScreen


# --- Info Labels ---
# These are the 3D TextMesh nodes that display text
@onready var game_log_label = $console/InfoScreens/console/GameLogScreen/LogViewport/Panel/GameLogLabel
@onready var player_info_label = $console/InfoScreens/console/PlayerInfoScreen/LogViewport/Panel/PlayerInfoLabel
@onready var enemy_info_tl = $console/InfoScreens/console/EnemyInfoScreen_TopLeft/LogViewport/Panel/EnemyInfoTopLeftLabel
@onready var enemy_info_bl = $console/InfoScreens/console/EnemyInfoScreen_BottomLeft/LogViewport/Panel/EnemyInfoBottomLeftLabel
@onready var enemy_info_tr = $console/InfoScreens/console/EnemyInfoScreen_TopRight/LogViewport/Panel/EnemyInfoTopRightLabel
@onready var enemy_info_br = $console/InfoScreens/console/EnemyInfoScreen_BottomRight/LogViewport/Panel/EnemyInfoBottomRightLabel

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

	if is_instance_valid(avatar_image_tr):
		print("SUCCESS: Found avatar_image_tr.")
	else:
		print("ERROR: Could not find avatar_image_tr at the specified path.")

	# ... (You can add checks for the other enemy labels if you wish)
	print("--- Self-Check Complete ---")

func update_avatar_display(ai_players: Array):
	if ai_players.size() > 0 and avatar_image_tr:
		avatar_image_tr.texture = ai_players[0].faction_data.avatar
	if ai_players.size() > 1 and avatar_image_br:
		avatar_image_br.texture = ai_players[1].faction_data.avatar
	if ai_players.size() > 2 and avatar_image_tl:
		avatar_image_tl.texture = ai_players[2].faction_data.avatar
	if ai_players.size() > 3 and avatar_image_bl:
		avatar_image_bl.texture = ai_players[3].faction_data.avatar

func update_info_screens(player_state: PlayerState, ai_players: Array):
	if player_state:
		player_info_label.text = "Player: %s\nAP: %d\nTreasury: %d\nPopulation: %dM" % [player_state.faction_data.faction_name, player_state.current_ap, player_state.current_treasury, player_state.current_population]

	if ai_players.size() > 0 and enemy_info_tr:
		var p = ai_players[0]
		enemy_info_tr.text = "Leader: %s\nFaction: %s\nPopulation: %dM" % [p.faction_data.leader_name, p.faction_data.faction_name, p.current_population]
	if ai_players.size() > 1 and enemy_info_br:
		var p = ai_players[1]
		enemy_info_br.text = "Leader: %s\nFaction: %s\nPopulation: %dM" % [p.faction_data.leader_name, p.faction_data.faction_name, p.current_population]
	if ai_players.size() > 2 and enemy_info_tl:
		var p = ai_players[2]
		enemy_info_tl.text = "Leader: %s\nFaction: %s\nPopulation: %dM" % [p.faction_data.leader_name, p.faction_data.faction_name, p.current_population]
	if ai_players.size() > 3 and enemy_info_bl:
		var p = ai_players[3]
		enemy_info_bl.text = "Leader: %s\nFaction: %s\nPopulation: %dM" % [p.faction_data.leader_name, p.faction_data.faction_name, p.current_population]
