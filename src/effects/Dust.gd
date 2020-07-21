extends AnimatedSprite

func setup(action, pos):
	global_position = pos
	play()
	set_animation(action)

func _on_Dust_animation_finished():
	queue_free()
