# (This code is indented with tabs)
extends Node

# We preload our effect scene so we can create instances of it.
const FloatingTextScene = preload("res://scenes/effects/FloatingText.tscn")

# This is the main function other scripts will call.
func show_damage_text(damage_amount: int, target_panel: PlayerPanel):
	if not is_instance_valid(target_panel):
		return # Don't do anything if the target panel is gone.
	
	# Create an instance of our floating text scene.
	var floating_text = FloatingTextScene.instantiate()
	
	# We need to add it to the main scene tree to make it visible.
	# get_tree().root gives us access to the top of the scene.
	get_tree().root.add_child(floating_text)
	
	# Find the center position of the target's panel to spawn the text.
	var start_pos = target_panel.global_position + (target_panel.size / 2)
	
	# Tell the text what to say and where to start.
	floating_text.start("-%sM" % damage_amount, start_pos)
