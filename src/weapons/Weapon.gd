class_name Weapon
extends KinematicBody2D

var velocity : Vector2 = Vector2.ZERO
var speed : int = 300
var strength : float = 0.0
var direction : Vector2 = Vector2.ZERO

var damage : int = 50 
var knockback : int = 25
var max_distance : int = 12

var owned_by = null

onready var sprite := $AnimatedSprite
onready var label := $Labels/TimerLabel
onready var hitbox := $Hitbox
onready var stream_particles := $StreamParticles

func setup(o, pos, dir, throw_strength): #throw strength is from 20 to 100, output should be 100 to 300
	owned_by = o
	direction = dir.normalized()
	strength = float(throw_strength/100)
	position = to_local(pos)
	velocity = speed * direction * strength
	connect("finished_exploding", o, "bomb_exploded")
