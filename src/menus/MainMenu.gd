extends Node2D

onready var start_label = $Buttons/StartLabel
onready var start_label_anim = $Buttons/StartLabel/AnimationPlayer
onready var select_audio = $Audio/ClickedAudio

func _input(event):
	if event.is_action_pressed("select"): 
		#TODO add transitions
		select_audio.play()
		start_label_anim.play("clicked")
		yield(get_tree().create_timer(1.0), "timeout")
		get_tree().change_scene("res://src/levels/Level1.tscn")
#	pass
