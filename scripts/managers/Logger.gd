# (This code is indented with tabs)
extends Node

var log_label: RichTextLabel

func log(message: String):
	if log_label:
		# Add the new message and a newline character.
		log_label.append_text(message + "\n")
		
		# --- THE FIX ---
		# We need to wait one frame for the label to update its size
		# before we can accurately scroll to the new bottom.
		# 'await get_tree().process_frame' is the Godot 4 way to do this.
		await get_tree().process_frame
		
		# Get the vertical scrollbar and set its value to the maximum.
		var scrollbar = log_label.get_v_scroll_bar()
		scrollbar.value = scrollbar.max_value
	
	# Also print to the console for debugging purposes.
	print(message)
