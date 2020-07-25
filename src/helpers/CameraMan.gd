extends KinematicBody2D

var goal = null
var speed = 200
var direction = Vector2.ZERO
var manual = false
var leader = null

signal start_turn

onready var camera = $WorldCamera
onready var pan_label = $CanvasLayer/Control/PanLabel

func _ready():
	pan_label.visible = false

func setup(o):
	connect("start_turn", o, "_on_start_turn")

func _physics_process(delta):
	if manual:
		if not Input.is_action_pressed("panning"):
			panning(false)
			camera.leader.camera.current = true
			camera.leader.can_input = true
			global_position = camera.leader.camera.global_position
			return
		if leader != camera.leader:
			panning(false)
			return
		var x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
		var y = int(Input.is_action_pressed("aim_down")) - int(Input.is_action_pressed("aim_up"))
		move_and_slide(Vector2(x,y) * speed)
	
	else:
		if camera.leader != null:
			leader = camera.leader
			follow_leader()
		else:
			goal = Vector2(320,180)
			approach()

func panning(on):
	if on:
		manual = true
		pan_label.visible = true
		camera.current = true
	else:
		manual = false
		pan_label.visible = false

func follow_leader():
	if "camera" in camera.leader:
		goal = camera.leader.camera.global_position
	else:
		goal = camera.leader.global_position
	
	approach()
		#TODO follow

func approach():
	if goal.distance_to(global_position) >= 5 or not camera.current:
		direction = (goal - global_position).normalized()
		move_and_slide(direction * speed)
	else:
		if camera.leader.is_in_group("characters"):
			camera.leader.can_input = true
			emit_signal("start_turn")
		elif camera.leader.is_in_group("weapons"):
			camera.leader.apply_stored_force()
		print("PASSED THE TORCH TO ", camera.leader.instance_name)
		camera.leader.camera.current = true
