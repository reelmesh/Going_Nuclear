# (This is the final version that uses the global EventBus)
class_name DeploymentUI
extends Control

# This script no longer needs its own signal.

@onready var title_label = $ContentBox/CardChooserUI/TitleBar/TitleLabel
@onready var options_list = $ContentBox/CardChooserUI/OptionsList
@onready var visualizer_art = $ContentBox/CardVisualsOverlay/VisualizerContent/Visualizer_Art
@onready var visualizer_description = $ContentBox/CardVisualsOverlay/VisualizerContent/Visualizer_Description

func _ready():
	hide()

func show_choices(title: String, choices: Array, choice_type: String):
	title_label.text = title
	_update_visualizer(null)
	
	for child in options_list.get_children():
		child.queue_free()
		
	for choice in choices:
		var button = Button.new()
		options_list.add_child(button)
		
		if choice_type == "INVESTMENT":
			button.text = "%s (%d AP, $%d)" % [choice.name, choice.ap_cost, choice.treasury_cost]
			button.pressed.connect(func(): EventBus.deployment_choice_made.emit(choice.id))
		elif choice_type == "CARD":
			button.text = choice.card_name
			button.pressed.connect(func(): EventBus.deployment_choice_made.emit(choice))
			button.mouse_entered.connect(func(): _update_visualizer(choice))
	show()

func hide_screen():
	hide()

func _update_visualizer(card_data: CardData):
	if card_data:
		visualizer_art.texture = card_data.card_art
		visualizer_description.text = card_data.description
	else:
		visualizer_art.texture = null
		visualizer_description.text = "Select an option from the list."
