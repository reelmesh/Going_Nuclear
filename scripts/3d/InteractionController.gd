# (This is the final, correct script with the check_for_click function)
class_name InteractionController
extends Camera3D

var subviewport: SubViewport

func set_subviewport(vp: SubViewport):
	subviewport = vp

signal mouse_entered_button(button)
signal mouse_exited_button(button)

var _last_hovered_button = null


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
			if hit_object is PhysicalButton3D:
				hit_object.on_click()
			elif hit_object.name == "MainScreen":
				if subviewport:
					subviewport.push_input(event)

func _physics_process(_delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = self.project_ray_origin(mouse_pos)
	query.to = query.from + self.project_ray_normal(mouse_pos) * 1000
	
	var result = space_state.intersect_ray(query)
	
	var current_hovered_button = null
	if not result.is_empty():
		var hit_object = result.collider
		if hit_object is PhysicalButton3D:
			current_hovered_button = hit_object
			
	if current_hovered_button != _last_hovered_button:
		if _last_hovered_button:
			mouse_exited_button.emit(_last_hovered_button)
		if current_hovered_button:
			mouse_entered_button.emit(current_hovered_button)
		_last_hovered_button = current_hovered_button
