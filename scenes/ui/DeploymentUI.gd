# (This is the final version that uses the global EventBus)
class_name DeploymentUI
extends Control

# This script no longer needs its own signal.

const OptionButtonScene = preload("res://scenes/ui/OptionButton.tscn")

@onready var title_label = $ContentBox/CardChooserUI/TitleBar/TitleLabel
@onready var background_click_handler = $ColorRect # Adjust path if needed

func _ready():
	hide()
	mouse_filter = MOUSE_FILTER_STOP
	background_click_handler.gui_input.connect(_on_background_clicked)

func _on_background_clicked(event):
	if event is InputEventMouseButton and event.pressed:
		hide_screen()
# Optionally, emit a signal via EventBus if other nodes need to know
# EventBus.deployment_screen_closed.emit()

func show_choices(title: String, choices: Array, choice_type: String):
	title_label.text = title
	_update_visualizer(null)
	
	var options_list = get_node("ContentBox/CardChooserUI/OptionsList")
	if not options_list:
		printerr("DeploymentUI Error: OptionsList node not found at the specified path.")
		return
		
	# Clear only the previously added buttons, preserving other nodes.
	for child in options_list.get_children():
		if child is Button:
			child.queue_free()
		
	for i in range(choices.size()):
		var choice = choices[i]
		var button = OptionButtonScene.instantiate()
		options_list.add_child(button)
		# Ensure the button is added before any non-button nodes (like the background panel)
		options_list.move_child(button, i)
		
		if choice_type == "INVESTMENT":
			button.text = "%s (%d AP, $%d)" % [choice.name, choice.ap_cost, choice.treasury_cost]
			button.pressed.connect(func(): EventBus.deployment_choice_made.emit(choice.id))
		elif choice_type == "CARD":
			button.text = choice.card_name
			button.pressed.connect(func(): EventBus.deployment_choice_made.emit(choice))
			button.mouse_entered.connect(func(): 
				Logger.log("Mouse entered button: '%s'" % choice.card_name)
				_update_visualizer(choice)
			)
	show()

func hide_screen():
	hide()

func _update_visualizer(card_data: CardData):
	var visualizer_art = get_node("ContentBox/CardVisualsOverlay/VisualizerContent/Visualizer_Art")
	var visualizer_description = get_node("ContentBox/CardVisualsOverlay/VisualizerContent/Visualizer_Description")

	if not visualizer_art or not visualizer_description:
		printerr("DeploymentUI Error: Visualizer nodes not found at the specified paths.")
		return

	if card_data:
		visualizer_art.texture = card_data.card_art
		visualizer_description.text = card_data.description
	else:
		visualizer_art.texture = null
		visualizer_description.text = "Select an option from the list."

func _input(event):
	# Handle input events for this control
	if event is InputEventMouseButton and event.pressed:
		# --- DEBUG ---
		Logger.log("--- DeploymentUI _input received MOUSE BUTTON PRESS ---")
		# If we're showing the deployment screen, we might want to handle clicks outside
		# to close the menu, but let's not interfere with button presses
		pass

# Ensure that this UI can properly process mouse events
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		# --- DEBUG ---
		Logger.log("--- DeploymentUI _gui_input received MOUSE BUTTON PRESS ---")
		# This will be called when mouse is pressed on this control or its children
		# We don't need to do anything special here, but we want to make sure 
		# the control properly accepts input events
		pass
