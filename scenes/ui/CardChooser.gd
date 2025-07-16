# (This code is indented with tabs)
class_name CardChooser
extends PanelContainer

# This signal is emitted when a card is clicked inside the chooser.
signal card_chosen(card_data)

const CardScene = preload("res://scenes/ui/Card.tscn")

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var card_grid: GridContainer = $MarginContainer/VBoxContainer/CardGrid

# This is the main function to set up the chooser.
func initialize(title: String, card_ids: Array):
	title_label.text = title
	
	# Clear any old cards, just in case.
	for child in card_grid.get_children():
		child.queue_free()
		
	# Create a card UI for each card ID we were given.
	for card_id in card_ids:
		var card_data = CardDatabase.get_card_data(card_id)
		if card_data:
			var new_card = CardScene.instantiate()
			card_grid.add_child(new_card)
			new_card.update_display(card_data)
			# Connect the card's signal to our internal handler.
			new_card.card_selected.connect(_on_card_clicked_in_chooser)

# This internal function is called when a card inside me is clicked.
func _on_card_clicked_in_chooser(card_node: Card):
	# Bubble up the event by emitting our own signal.
	card_chosen.emit(card_node.card_data)
	# I have served my purpose. Remove myself from the screen.
	queue_free()
