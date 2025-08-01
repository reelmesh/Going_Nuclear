# (This is the simple, correct version)
class_name DeploymentScreen
extends PanelContainer

signal card_chosen(card_data)

@onready var options_list = $HBoxContainer/SecondaryOptions_Left
@onready var visualizer_name = $HBoxContainer/CardVisualsOverlay/VisualizerContent/Visualizer_Name
@onready var visualizer_art = $HBoxContainer/CardVisualsOverlay/VisualizerContent/Visualizer_Art
@onready var visualizer_description = $HBoxContainer/CardVisualsOverlay/VisualizerContent/Visualizer_Description

func show_card_choices(card_ids: Array):
	for child in options_list.get_children():
		child.queue_free()
	
	_update_visualizer(null)
		
	if card_ids.is_empty():
		var label = Label.new()
		label.text = "No cards of this type."
		options_list.add_child(label)
		return
		
	for card_id in card_ids:
		var card_data = CardDatabase.get_card_data(card_id)
		if card_data:
			var button = Button.new()
			button.text = card_data.card_name
			options_list.add_child(button)
			button.pressed.connect(_on_card_button_pressed.bind(card_data))
			button.mouse_entered.connect(_on_card_button_hovered.bind(card_data))

func _on_card_button_pressed(card_data: CardData):
	card_chosen.emit(card_data)

func _on_card_button_hovered(card_data: CardData):
	_update_visualizer(card_data)

func _update_visualizer(card_data: CardData):
	if card_data:
		visualizer_name.text = card_data.card_name
		visualizer_art.texture = card_data.card_art
		visualizer_description.text = card_data.description
	else:
		visualizer_name.text = "HOVER OVER AN OPTION"
		visualizer_art.texture = null
		visualizer_description.text = ""
