extends Button

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	get_parent().get_parent().get_parent().get_parent()._set_cursor_hand(true)

func _on_mouse_exited():
	get_parent().get_parent().get_parent().get_parent()._set_cursor_hand(false)
