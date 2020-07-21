extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var owned_by = null
var damage : int = 0
onready var collision_shape := $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready():
	deactivate()

func setup(o):
	owned_by = o
	damage = o.damage

func activate():
	collision_shape.disabled = false
	
func deactivate():
	collision_shape.disabled = true


func _on_Hitbox_body_entered(body):
	if body.is_in_group("characters"):
		body.update_health(damage)
