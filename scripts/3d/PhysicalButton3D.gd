# (This script is correct and does not need to be changed)
class_name PhysicalButton3D
extends StaticBody3D

signal button_pressed(mesh_name)

@onready var target_mesh: MeshInstance3D = get_parent()
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var anim_player: AnimationPlayer

func set_animation_player(p_anim_player: AnimationPlayer):
	self.anim_player = p_anim_player

func on_click():
	button_pressed.emit(target_mesh.name)

func play_animation(is_backwards: bool = false):
	var anim_name = "%s_Press" % target_mesh.name
	if anim_player and anim_player.has_animation(anim_name):
		if is_backwards:
			anim_player.play_backwards(anim_name)
		else:
			anim_player.play(anim_name)

func enable():
	if collision_shape:
		collision_shape.disabled = false

func disable():
	if collision_shape:
		collision_shape.disabled = true
