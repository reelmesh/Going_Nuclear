# (This code is indented with tabs)
class_name AvatarScreen2D
extends SubViewportContainer

@onready var avatar_image: TextureRect = $SubViewport/AvatarImage

# This is the only function we need. It sets the texture.
func set_avatar_texture(texture: Texture2D):
	avatar_image.texture = texture
