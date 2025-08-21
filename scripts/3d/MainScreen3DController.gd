# res://scripts/3d/MainScreen3DController.gd
extends Node3D

# This script is attached to MainScreen3D to help with debugging input events.

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		# --- DEBUG ---
		Logger.log("--- MainScreen3DController _input received MOUSE BUTTON PRESS ---")
		# This will help us see if events are reaching the 3D scene at all.
		pass

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		# --- DEBUG ---
		Logger.log("--- MainScreen3DController _gui_input received MOUSE BUTTON PRESS ---")
		# This will help us see if GUI events are reaching the 3D scene at all.
		pass
