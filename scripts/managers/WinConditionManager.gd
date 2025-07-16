# (This code is indented with tabs)
extends Node

# This function analyzes the list of active players.
# It returns a dictionary with the results.
func check_win_conditions(active_players: Array) -> Dictionary:
	var players_alive = []
	for p in active_players:
		if p.current_population > 0:
			players_alive.append(p)
	
	if players_alive.size() <= 1:
		# The game is over!
		var winner_state = null
		if not players_alive.is_empty():
			winner_state = players_alive[0]
			
		return {
			"is_game_over": true,
			"winner": winner_state
		}
	else:
		# The game continues.
		return {
			"is_game_over": false,
			"winner": null
		}
