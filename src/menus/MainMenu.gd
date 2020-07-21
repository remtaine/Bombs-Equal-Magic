extends Node2D

onready var start_label = $Buttons/StartLabel
onready var start_label_anim = $Buttons/StartLabel/AnimationPlayer

func _input(event):
	if event is InputEventKey and event.pressed:
		#TODO add transitions
		start_label_anim.play("clicked")
		yield(get_tree().create_timer(1.0), "timeout")
		get_tree().change_scene("res://src/levels/Level1.tscn")
#	pass
