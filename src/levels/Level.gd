class_name Level
extends Node2D

onready var character_holder = $Characters
onready var world_camera_man = $CameraMan
onready var world_camera = $CameraMan/WorldCamera
onready var turn_queue = $Characters


onready var blue_team_hp = $HUD/Control/BlueTeamHP
onready var red_team_hp = $HUD/Control/RedTeamHP

onready var HUD = $HUD/Control
onready var win_menu := $HUD/WinMenu
onready var lose_menu := $HUD/LoseMenu
onready var turn_timer = $HUD/Control/TurnTimer

onready var turn_label = $HUD/Control/TurnLabel
onready var time_text_label := $HUD/Control/TimeLeftLabel
onready var timer_label := $HUD/Control/TurnTimer/TimeLabel

func _ready():
	reset_hp(blue_team_hp)
	reset_hp(red_team_hp)
	
	turn_queue.setup(self)
	for blue_child in turn_queue.get_child(0).get_children():
		blue_child.level_setup(self)
		add_team_hp(blue_team_hp,blue_child.hp)
	for red_child in turn_queue.get_child(1).get_children():
		red_child.level_setup(self)
		add_team_hp(red_team_hp,red_child.hp)
	

func _input(event):
	if event.is_action_pressed("ui_cancel"): #esc
		get_tree().quit()
	if event.is_action_pressed("reset"): #R
		get_tree().reload_current_scene()
	if event.is_action_pressed("go_to_menu"): #R
		get_tree().change_scene("res://src/menus/MainMenu.tscn")
#	if event.is_action_pressed("toggle_labels"): #T
#		for child in character_holder.get_children():
#			for label in child.get_node("Labels"):
#				label.toggle()

func change_camera_leader(leader = null):
	if leader != null:
		if leader.is_in_group("characters"):
			turn_label.text = leader.team + "'s turn"
			turn_label.self_modulate = leader.team_color
		world_camera.change_leader(leader)


func _on_TurnTimer_timeout():
	turn_queue.active_character.set_inactive()
	
func _on_start_turn():
	turn_timer.paused = false
	turn_timer.start()

func _on_pause_timer():
	turn_timer.paused = true

func _on_take_damage(team, dmg):
	match team:
		"Blue":
			var x = blue_team_hp.value - dmg
			if x <= 0:
				HUD.visible = false
				timer_label.visible = false	
				lose_menu.show()
			blue_team_hp.take_damage(dmg)
		"Red":
			var x = red_team_hp.value - dmg
			if x <= 0:
				HUD.visible = false
				timer_label.visible = false
				win_menu.show()
			red_team_hp.take_damage(dmg)

func _on_panning():
	world_camera_man.panning(true)
	
func add_team_hp(team_hp, add):
	team_hp.max_value += add
	team_hp.value += add

func reset_hp(team_hp):
	team_hp.max_value = 0
	team_hp.value = 0
