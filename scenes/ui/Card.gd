class_name Card
extends PanelContainer

@onready var name_label: Label = %NameLabel
@onready var art_rect: TextureRect = %Art
@onready var type_label: Label = %TypeLabel
@onready var description_label: Label = %DescriptionLabel

# A variable to hold the actual card data resource.
var card_data: CardData

# This is the main function. It takes a CardData object and updates the UI.
func update_display(p_card_data: CardData):
	self.card_data = p_card_data
	
	name_label.text = card_data.card_name
	type_label.text = CardData.CardType.keys()[card_data.card_type]
	description_label.text = card_data.description
	
	if card_data.card_art:
		art_rect.texture = card_data.card_art
	else:
		art_rect.texture = null # Or a default "no art" texture
