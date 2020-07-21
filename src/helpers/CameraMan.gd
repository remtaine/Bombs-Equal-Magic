extends KinematicBody2D

var goal = null
var speed = 200
var direction = Vector2.ZERO

onready var camera = $WorldCamera
func _ready():
	pass

func _physics_process(delta):
	if camera.leader != null:
		follow_leader()
	else:
		goal = Vector2(320,180)
		approach()

func follow_leader():
	if "camera_goal" in camera.leader:
		goal = camera.leader.camera_goal
	else:
		goal = camera.leader.global_position
	
		approach()
		#TODO follow

func approach():
	if goal.distance_to(global_position) >= 10:
		direction = (goal - global_position).normalized()
		move_and_slide(direction * speed)
