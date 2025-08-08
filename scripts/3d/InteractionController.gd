# (This is the final, correct script with the check_for_click function)
class_name InteractionController
extends Camera3D

# This flag is controlled by the main controller to prevent clicks
# when a 2D UI is open.
var process_input = true

# This is now a public function that the main_controller calls.
# It no longer uses the automatic _unhandled_input.
func check_for_click(event: InputEvent):
	if not process_input:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var mouse_pos = get_viewport().get_mouse_position()
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = self.project_ray_origin(mouse_pos)
		query.to = query.from + self.project_ray_normal(mouse_pos) * 1000
		
		var result = space_state.intersect_ray(query)
		
		if not result.is_empty():
			var hit_object = result.collider
			if hit_object.has_method("on_click"):
				hit_object.on_click()
