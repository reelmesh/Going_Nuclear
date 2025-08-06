# (This script is our global message board)
extends Node

# --- THIS IS THE FIX ---
# The '@warning_ignore' annotation tells the Godot script checker
# to not show a warning for the specific code on the next line.
@warning_ignore("unused_signal")
signal deployment_choice_made(choice_data)
