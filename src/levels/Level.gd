extends Node2D
onready var character_holder = $Characters
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("toggle_labels"):
		for child in character_holder.get_children():
			for label in child.get_node("Labels"):
				label.toggle()
