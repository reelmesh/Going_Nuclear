# (This is the new, self-contained controller for the deployment screen)
class_name DeploymentScreen
extends PanelContainer

# This script no longer uses the EventBus. It will connect directly
# to the main controller, which is a more robust pattern for a single UI element.
signal choice_made(choice_data)

@onready var title_label = $CardChooserUI/TitleBar/TitleLabel
@onready var options_list = $CardChooserUI/ContentBox/OptionsList
# ... (@onready vars for your visualizer are also needed here)

# This will hold a reference to the 3D raycast controller.
var interaction_controller: Camera3D

# This is called once by the main controller at the start of the game.
func initialize(p_interaction_controller: Camera3D):
	self.interaction_controller = p_interaction_controller
	hide() # Ensure the screen starts hidden.

func show_choices(title: String, choices: Array, choice_type: String):
	# --- The Input Lock ---
	# Before showing, disable the 3D interaction.
	if interaction_controller:
		interaction_controller.process_input = false
	
	title_label.text = title
	# ... (_update_visualizer(null) if you have it)
	
	for child in options_list.get_children():
		child.queue_free()
		
	for choice in choices:
		var button = Button.new()
		options_list.add_child(button)
		
		if choice_type == "INVESTMENT":
			button.text = "%s (%d AP, $%d)" % [choice.name, choice.ap_cost, choice.treasury_cost]
			button.pressed.connect(func(): _on_choice_selected(choice.id))
		elif choice_type == "CARD":
			button.text = choice.card_name
			button.pressed.connect(func(): _on_choice_selected(choice))
			# button.mouse_entered.connect(func(): _on_card_button_hovered(choice))
			
	show()

# This internal function is called by the buttons.
func _on_choice_selected(choice_data):
	# Announce that a choice was made.
	choice_made.emit(choice_data)
	
	# Hide myself and clean up.
	hide_screen()

func hide_screen():
	for child in options_list.get_children():
		child.queue_free()
	hide()
	
	# --- The Input Unlock ---
	# After hiding, re-enable 3D interaction.
	if interaction_controller:
		interaction_controller.process_input = true
