extends KinematicBody2D

var velocity : Vector2 = Vector2.ZERO
var speed : int = 0

func _ready():
	pass

func _physics_process(delta):
	velocity.y += 3
	velocity = move_and_slide(velocity, Vector2.UP, true, 1)
