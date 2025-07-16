# (This code is indented with tabs)
extends Label

# This function is called when the label is created.
# It starts the animation.
func start(text_to_show: String, start_position: Vector2):
	text = text_to_show
	position = start_position
	
	# A tween animates properties over time.
	var tween = create_tween()
	# Make the tween run in parallel, so move and fade happen at the same time.
	tween.set_parallel(true)
	
	# Animate the 'position' property. Move it 60 pixels up from its start.
	tween.tween_property(self, "position:y", start_position.y - 60, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Animate the 'modulate' property (color/alpha). Fade its alpha to 0.
	tween.tween_property(self, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_CUBIC)
	
	# When the tween is finished, remove the label from the game.
	tween.finished.connect(queue_free)
