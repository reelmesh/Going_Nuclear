# (This script is on the Camera3D)
extends Camera3D

# We no longer need a signal here.

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var mouse_pos = get_viewport().get_mouse_position()
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = self.project_ray_origin(mouse_pos)
		query.to = query.from + self.project_ray_normal(mouse_pos) * 1000
		var result = space_state.intersect_ray(query)
		
		if not result.is_empty():
			var hit_object = result.collider
			# --- THE NEW LOGIC ---
			# Check if the object we hit has our new "on_click" function.
			if hit_object.has_method("on_click"):
				# If it does, call it directly.
				hit_object.on_click()
