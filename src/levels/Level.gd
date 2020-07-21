extends Node2D
onready var character_holder = $Characters
onready var world_camera_man = $CameraMan
onready var world_camera = $CameraMan/WorldCamera
onready var turn_queue = $Characters

func _ready():
	turn_queue.setup(self)
	for team in turn_queue.get_children():
		for child in team.get_children():
			child.level_setup(self)
			
func _input(event):
	if event.is_action_pressed("ui_cancel"): #esc
		get_tree().quit()
	if event.is_action_pressed("reset"): #R
		get_tree().reload_current_scene()
	if event.is_action_pressed("toggle_labels"): #T
		for child in character_holder.get_children():
			for label in child.get_node("Labels"):
				label.toggle()

func change_camera_leader(leader):
	world_camera.change_leader(leader)
	print_debug("CHANGED CAMERA LEADER")
