class_name Card
extends PanelContainer

# UPDATED SIGNAL: Instead of just data, it will send a reference to ITSELF.
signal card_selected(card_node)

# --- Node References (same as before) ---
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var art_rect: TextureRect = $MarginContainer/VBoxContainer/Art
@onready var type_label: Label = $MarginContainer/VBoxContainer/TypeLabel
@onready var description_label: Label = $MarginContainer/VBoxContainer/DescriptionLabel

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	get_parent().get_parent().get_parent().get_parent()._set_cursor_hand(true)

func _on_mouse_exited():
	get_parent().get_parent().get_parent().get_parent()._set_cursor_hand(false)
	
var card_data: CardData

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# UPDATED: Emit the signal with a reference to this card instance.
		card_selected.emit(self)

# --- NEW: VISUAL FEEDBACK FUNCTIONS ---
func select():
	# A Tween smoothly animates a property over time.
	var tween = create_tween()
	# Animate my "position:y" property to -30 over 0.2 seconds.
	tween.tween_property(self, "position:y", -30, 0.2).set_trans(Tween.TRANS_QUAD)

func deselect():
	var tween = create_tween()
	# Animate my "position:y" property back to 0.
	tween.tween_property(self, "position:y", 0, 0.2).set_trans(Tween.TRANS_QUAD)

# --- update_display function (same as before) ---
func update_display(p_card_data: CardData):
	self.card_data = p_card_data
	name_label.text = card_data.card_name
	type_label.text = CardData.CardType.keys()[card_data.card_type]
	description_label.text = card_data.description
	
	if card_data.card_art:
		art_rect.texture = card_data.card_art
	else:
		art_rect.texture = null
