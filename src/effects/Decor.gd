extends KinematicBody2D

var velocity : Vector2 = Vector2.ZERO
var speed : int = 0

func _ready():
	pass

func _physics_process(delta):
	velocity.y += 3
#	move_and_collide(velocity * delta)
	velocity = move_and_slide(velocity * Vector2.DOWN, Vector2.UP, true, 1)
