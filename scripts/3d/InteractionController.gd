# (This code is indented with tabs)
extends Camera3D

# This signal will be emitted when a clickable 3D object is successfully clicked.
signal object_clicked(object_node)

func _unhandled_input(event: InputEvent):
	# We only care about the moment the left mouse button is pressed.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# Get the 2D mouse position on the screen.
		var mouse_pos = get_viewport().get_mouse_position()
		
		# --- This is the Raycasting logic ---
		# Get the physics space of the 3D world.
		var space_state = get_world_3d().direct_space_state
		
		# Create a query object.
		var query = PhysicsRayQueryParameters3D.new()
		# The ray starts at the camera's position.
		query.from = self.project_ray_origin(mouse_pos)
		# The ray points 1000 units straight forward from the camera through the mouse pointer.
		query.to = query.from + self.project_ray_normal(mouse_pos) * 1000
		
		# Execute the query. The result is a dictionary containing info about what was hit.
		var result = space_state.intersect_ray(query)
		
		# Check if the ray actually hit anything.
		if not result.is_empty():
			# --- THIS IS THE MISSING CODE ---
			# 'collider' is the object that was hit (our StaticBody3D).
			var hit_object = result.collider
			# We emit our signal, passing the hit object along.
			object_clicked.emit(hit_object)
